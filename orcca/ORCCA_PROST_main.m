% Main XD-ORCCA (respiratory-resolved)and MC-ORCCA (non-rigid
% motion-corrected) reconstruction with PROST reconstruction
% Authors: Teresa Correia (teresa.correia@kcl.ac.uk)
%          Aurelien Bustin (aurelien.bustin@kcl.ac.uk)
% CODE USE ON THE BIOENG264-PC

%% DATA

directory = '/mnt/workspace/pdpino/debug_orcca';
dir_twix = 'twix';
iNav    = 'CV_NAV_INAV_VD_X4_NAVIGATOR_0008/';
acqui   = 'meas_MID00074_FID44102_CV_nav_iNAV_VD_x4.dat';  % res 0.9 acc x4
channels  = [3 5 7 9 10 11 12 13 14 15 16 25 26 28 29];


%% MAIN

path_inav       = [directory '/' dir_twix iNav];
output_folder   = [directory 'RECONSTRUCTION/' acqui(1:end-4) '/'];
mkdir(output_folder);
path_ORCCA      = output_folder;
save_data       = 0;


%% READ iNAVs %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This section allows for reading the dicom files (.dcm or .ima) containing
% the 2D iNAVs and organises then into a M x M x N matrix, where M is the
% size of the iNAV and N is the total number of iNAVs acquired.

% Read the name of all the files contained in the folder assigned in 
% path_inav. NOTE: Change .IMA to .DCM if needed
disp('*********** Loading iNAV images *************')

files_inav = dir(fullfile(path_inav,'*.IMA*')); 

if (isempty(files_inav))
files_inav = dir(fullfile(path_inav,'*.dcm*')); 
end

files_inav = {files_inav.name}';

% Define M and N
M = size(dicomread([path_inav files_inav{1}]),1);
N = length(files_inav);

% Create two matrices of size MxMxN and read all the dicom files. The 
% matrix 'inav' contains the iNAVs and the matrix 'over' contains the 
% template tracked by the scanner.
inav = zeros([M M N]);
over = zeros([M M N]);

for nn = 1:N
    [nav_i,~,~,ov_i]  = dicomread([path_inav files_inav{nn}]);
    inav(:,:,nn) = mat2gray(nav_i); % iNAV image
    over(:,:,nn) = ov_i; % overlay template
end


%% READ RAW DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This section of the code reads the data acquired by the scanner and gets
% the k-space data and relevant measurement parameters
disp('*********** Loading data ********************')

fid = [directory, acqui];
twix = mapVBVD(fid);
twix = twix{length(twix)};
twix.image.flagIgnoreSeg = 1;
twix.image.flagRemoveOS = 0;
twix.image.dataSize(1:11);

rawdata = twix.image();
rawdata = remove_RO_oversampling(rawdata, twix);
rawdata = permute(rawdata,[1 3 4 2]);


%% CHECK COILS

if (1)
    [dimY, dimX, dimZ, ~] = size(rawdata);
    
    sz_center   = dimZ;
    sensitivity = get_sensitivity_map(rawdata, dimX, dimY, dimZ, sz_center);
    trajectory  = abs(abs(rawdata(:,:,:,1)) > 0);
    
    imagine(squeeze(abs(sensitivity(:,:,round(end/2),:))))
end


%% COILS REJECTION

disp('*********** Coils Rejection ********************')

coils_rejection = false;

if (coils_rejection && ~isempty(channels))
    rawdata     = rawdata(:,:,:,channels,:);
end

% SIEMENS selection:

if (0)
nCoils = size(rawdata, 4); % Number of coils

del_coils = ["B11","B16","B21","B26","B31","B36","S11","S14","S21","S24","S31","S34"];
for i = 1:nCoils
    if (sum(twix.hdr.MeasYaps.sCoilSelectMeas.aRxCoilSelectData{1}.asList{i}.sCoilElementID.tElement == del_coils) >0)
        idx(i) = i;
    end
end

coils_noarms = 1:nCoils;

if 0%(prm.scoils)
    sel_channels = prm.user_val;
else
    sel_channels = coils_noarms(idx==0);
end

j = 1;
for i=1:size(rawdata, 2)
    check_ch = any(sel_channels(:) == i);
    if check_ch == 1
        % disp(['j = ' num2str(j)]);
        rawdata_new(:,:,:,j) = rawdata(:,:,:,i);
        j = j + 1;
        % disp(['*** i = ' num2str(i)]);
    end
end

rawdata = rawdata_new;
clear rawdata_new

end

% Relevant measurement parameters of the acquisition
nCoils = size(rawdata, 4); % Number of coils 
nAcq   = twix.image.NAcq;  % Number of readouts acquired
nSeg   = twix.image.NSeg;  % Number of heartbeats = Number of iNAVs
nKx    = twix.image.NCol;  % Number of samples in each readout
nKy    = twix.image.NLin;  % Number of phase encoding lines
nKz    = twix.image.NPar;  % Number of slices

% Location of the centre of K-space in (Kx,Ky,Kz)
centreKx = twix.image.centerCol(1); 
centreKy = twix.image.centerLin(1);
centreKz = twix.image.centerPar(1);

% Coordinates of each readout in the phase encoding plane
kY  = double(twix.image.Lin); % ky coordinate of each readout
kZ  = double(twix.image.Par); % kz coordinate of each readout
seg = double(twix.image.Seg); % number of heart beat when each 


%% MOTION ESTIMATION FROM INAVS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This section allows to obtain the translational motion using the position 
% of the tracked templates.

disp('***** Estimating translational motion *****')

% Coordinates of the original template.
[i1,j1] = find(over(:,:,1),1,'first'); % Top rigth corner of the template
[i2,j2] = find(over(:,:,1),1,'last'); % Bottom left corner of the template

% Translational motion estimated from the scanner. These vectors contain 
% the foot-head (FH) and right-left (RL) translational motion as estimated 
% by the scanner
t_fh_scan = zeros(1,N);
t_rl_scan = zeros(1,N);

for nn = 1:N
    [i0,j0] = find(over(:,:,nn),1,'first');
    t_fh_scan(nn) = i0-i1;
    t_rl_scan(nn) = j0-j1;
end


%% image registration %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[optimizer_mono, metric_mono] = imregconfig('mono');

delta_fh = 10;
delta_rl = 2;  
im_navs = inav(i1-delta_fh:i2+delta_fh,j1-delta_rl:j2+delta_rl,:);
N = size(inav,3);
t_rl_mat = zeros(1,N);
t_fh_mat = zeros(1,N);

parfor n = 1:N
    tform = imregtform(mat2gray(abs(im_navs(:,:,n)))*256,mat2gray(abs(im_navs(:,:,1)))*256,'translation',optimizer_mono,metric_mono);
	t_fh_mat(1,n)  = -tform.T(3,2);
	t_rl_mat(1,n)  = -tform.T(3,1);
end

% Select the iNAV of reference
% the reference is selected at end expiration
if (1)
    [idx] = find_25_75_end_exp_XMR(t_fh_mat);  % end-expiration is used as reference
% the reference is selected the closest to the mean
else
    Average  = mean(t_fh_mat);
    [~, idx] = min(abs(t_fh_mat - Average));
end

parfor n = 1:N
    tform = imregtform(mat2gray(abs(im_navs(:,:,n)))*256,mat2gray(abs(im_navs(:,:,idx)))*256,'translation',optimizer_mono,metric_mono);
	t_fh_mat(1,n)  = -tform.T(3,2);
	t_rl_mat(1,n)  = -tform.T(3,1);
end

t_fh = t_fh_mat;
t_rl = t_rl_mat;    

motion.t_fh = t_fh;
motion.t_rl = t_rl;

if (save_data)
    save ([output_folder, 'out_motion'],'motion');
end

clear motion


%% GET DATA and SAMPLING MATRIX %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% there is a faster way of doing this (not tested with ORCCA)
% kSpace is a matrix containing the measured raw data. 
% At is a logical matrix that contains the sampling pattern (section of 
% k-space) measured at each heart beat

disp('******** Sorting data and sampling ********')

nKx     = size(rawdata,1);
At_raw  = false(nKx,nKy,nKz,nSeg);

for nnn=1:nAcq
    At_raw(:,kY(nnn),kZ(nnn),seg(nnn)) = true;
end

kData = rawdata;
At = At_raw;

clear At_raw
% clear rawdata


%% ARRHYTHMIA DETECTION / REJECTION

threshold   = 1.3;
outlier_idx1 = Arrythmia_rejection(twix, threshold);

threshold   = 2;
outlier_idx2 = Respiratory_rejection(t_fh, threshold);

At(:,:,:,outlier_idx1) = false;
At(:,:,:,outlier_idx2) = false;


%%  MOTION CORRECTED K-SPACE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This section of the code performs image reconstruction with translational
% motion correction. Using the estimated motion, we correct each readout in
% k-space according to the corresponding phase shift.

% This section of the code applies translational phase correction. In order
% to avoid memory overload, we split the data correction in chunks of size 
% 'chunksize'. Bigger chunk -> faster but higher memory requirement
disp('***** k-space translational motion correction *****')

siz = [size(kData,1) size(kData,2) size(kData,3)];
chunksize  = 50;
nchunks    = floor(size(At,4)/chunksize);
kData_corr = zeros([siz nCoils]);

for ccc = 1:nchunks
    idx_list = 1+((ccc-1)*chunksize):ccc*chunksize;
    curr_At = At(:,:,:,idx_list);
    curr_motion.Tx = t_fh(idx_list);
    curr_motion.Ty = -t_rl(idx_list);
    curr_kdata = translationCorrectionAndy_V3(kData, curr_At, curr_motion);
    kData_corr = kData_corr + sample_dataV2(curr_kdata, curr_At);
end

% Final chunk
ccc = nchunks+1;
idx_list = 1+((ccc-1)*chunksize):size(At,4);
curr_At  = At(:,:,:,idx_list);
curr_motion.Tx = t_fh(idx_list);
curr_motion.Ty = -t_rl(idx_list);
curr_kdata = translationCorrectionAndy_V3(kData, curr_At, curr_motion);
kData_corr = kData_corr + sample_dataV2(curr_kdata, curr_At);

clear curr_At
clear curr_kdata


%% COILS COMPRESSION

coils_compression = false;

if (coils_compression)
    numVrec = 8; % set the number of virtual coils
    calsize = [20,20]; % set the fully sampled center k-space size
    correction = 1; % turn on the alignment of the coil compression matrices

    kData_corr = CoilCompression(kData_corr, numVrec , calsize,correction);
    % rawdata = permute(rawdata, [1 4 2 3]);

    % rawdata_cor = permute(rawdata_cor, [1 4 2 3]);
end


%% GENERATE COIL SENSITIVITY MAPS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

disp('***** Estimating coil sensitivity maps *****')

csm_walsh = 0; % coils obtained from Walsh
csm_sos   = 1; % coils obtained from sum-of-squares

if (csm_walsh)
    
    addpath(genpath('/data/abu17/DATA/NON_RIGID_PROST/ORCCA_CMRA_GUI/bart-0.4.03/')); 
    
    startup;

    tic;
    [calib, emaps] = bart('ecalib -r 20 -k 5 -S', kData);
    toc;
    csm_total = bart('slice 4 0', calib);

elseif (csm_sos)

    [dimY, dimX, dimZ, ~] = size(kData);
    sz_center   = dimZ;
    tic;
    csm_total = get_sensitivity_map(kData, dimX, dimY, dimZ, sz_center);
    toc;

end

coil_rss = sqrt(sum(csm_total.*conj(csm_total),4));

trajectory  = abs(abs(kData_corr(:,:,:,1)) > 0);

disp('***** Saving coil sensitivity maps *****')
if (save_data)
    save( [output_folder 'csm'], 'csm_total','-v7.3')
end
clear emaps
clear calib




%% MOTION CORRECTED RECONSTRUCTION (ZERO-FILLING) %%%%%%%%%%%%%%%%%%%%%%%%%

% Image reconstruction with translational motion correction. E is the same 
% encoding matrix, including the sampling pattern and coil sensitivity maps
% We just need to reconstruct the corrected kSpace, with zero-fill 
% reconstruction and with iterative SENSE.
disp('************ TC reconstruction: Zero-Filling **************')

E = Cruz_E_3D_CARTESIAN(sum(At,4), csm_total, nCoils, siz, [siz nCoils], coil_rss);

% Zero-filled reconstruction
% recon_dft       = E'*kData;
recon_mc_dft    = E'*kData_corr;
% recon_dft       = recon_dft(end:-1:1,end:-1:1,:,:);
recon_mc_dft    = recon_mc_dft(end:-1:1,end:-1:1,:,:);

ORCCA.TC    = recon_mc_dft(:,50:end-50,:);
ORCCA.sizex = size(ORCCA.TC,1);
ORCCA.sizey = size(ORCCA.TC,2);
ORCCA.sizez = size(ORCCA.TC,3);
ORCCA.end   = 0;
% ORCCA.NMC   = prm.NMC;

disp('************ Saving TC reconstruction (ZF) **************')
if (save_data)
%     save( [path_ORCCA 'RECON_DFT'], 'recon_dft','-v7.3')
    save( [path_ORCCA 'RECON_MC_DFT'], 'recon_mc_dft','-v7.3')
end


%% MOTION CORRECTED RECONSTRUCTION (3D-PROST) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if(0)
disp('************ TC reconstruction: 3D-PROST **************')

% Parameters: acquisition

Params_acqui.kdata_OUT = kData_corr;

% Parameters: PROST

Params_PROST.sig         =  1;%0.05;
Params_PROST.patch_sz    =  8;
Params_PROST.max_patch   =  20;
Params_PROST.win         =  20;
Params_PROST.offset      =  4;
Params_PROST.debug       =  1;
Params_PROST.recon_mode  =  4;% 3: 2D / 4: 3D
Params_PROST.type        =  2;
Params_PROST.sharpness   =  0.6;

% Parameters: MR

Params_MR.ADMM_maxit    = 2;
Params_MR.CG_minres     = 1e-10;
Params_MR.CG_maxit_ini  = 7;
Params_MR.CG_maxit      = 5;
Params_MR.CG_lambda     = 0.3;
Params_MR.E_CSbins      = E;

disp('************ NMC reconstruction with 3D PROST **************');

[recon_prost, Rx_it, y_it, x_it] = PROST_NON_RIGID(Params_acqui, Params_MR, Params_PROST);


disp('************ Saving TC reconstruction (CS) **************')
if (save_data)
    save( [path_ORCCA 'RECON_PROST'], 'recon_prost','-v7.3')
end

end
% clear kData_corr
% clear recon*

%% MOTION CORRECTED RECONSTRUCTION (3D-PROST / CPU) %%%%%%%%%%%%%%%%%%%%%%%

if (1)
    
disp('************ TC reconstruction: 3D-PROST **************')

rawdata_cor_fft1 = fftshift(ifft(ifftshift(kData_corr),[], 1));

csm         = csm_total;
coil_rss    = sqrt(sum(csm.*conj(csm),4));
ncoils      = size(rawdata_cor_fft1,4);
siz         = [size(rawdata_cor_fft1,1), size(rawdata_cor_fft1,2), size(rawdata_cor_fft1,3)];
Ksiz        = size(rawdata_cor_fft1);

% Permute read-out

At2                 = permute(trajectory, [2 3 1]);
csm2                = permute(csm, [2 3 4 1]);
coil_rss2           = permute(coil_rss, [2 3 1]);
rawdata_cor_fft12   = permute(rawdata_cor_fft1, [2 3 4 1]);

% Get Params MR recon

Params_MRrecon.CG_maxit     = 5;
Params_MRrecon.CG_minres    = 1e-10;
Params_MRrecon.ADMM_maxit   = 2;
Params_MRrecon.CG_maxit_ini = 5; 
Params_MRrecon.CG_lambda    = 0.3;

% Get Params kspace

Params_data.kspace      = rawdata_cor_fft12;
Params_data.csm_total   = csm2;
Params_data.trajectory  = At2;

% Get Params PROST

% Params_PROST.sig         =  0.08;%0.06;
% Params_PROST.patch_sz    =  5;
% Params_PROST.max_patch   =  20;
% Params_PROST.win         =  10;
% Params_PROST.offset      =  4;
% Params_PROST.debug       =  1;
% Params_PROST.recon_mode  =  4;% 3: 2D / 4: 3D
% Params_PROST.sharpness   =  0.8;

Params_PROST.patch_sz    =  5;
Params_PROST.max_patch   =  20;
Params_PROST.win         =  20;
Params_PROST.offset      =  4;
Params_PROST.debug       =  1;
Params_PROST.recon_mode  =  4;% 3: 2D / 4: 3D
Params_PROST.sharpness   =  0.6;

Params_PROST.sig         =  1;
Params_PROST.type        =  0;
Params_PROST.sig         =  1;
Params_PROST.type        =  2;

% Run reconstruction
rec_Ny = twix.hdr.Config.NImageLins;
rec_Nz = twix.hdr.Config.NImagePar;

disp('************ NMC reconstruction with 3D PROST **************');
[recon_prost, Rx_it, y_it, x_it] = Bustin_PROST_reconstruction_CPU(Params_data, Params_MRrecon, Params_PROST, rec_Ny, rec_Nz);
recon_prost = permute(recon_prost,[3 1 2]);


disp('************ Saving 3D-PROST reconstruction **************')
if (save_data)
    save( [path_ORCCA 'RECON_PROST'], 'recon_prost','-v7.3')
end

% clear kData_corr
% clear recon*

end


%% RESPIRATORY BINNING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

disp('************ Respiratory Binning **************')

% Number of respiratory bins
nbins = 5;%4;
curr_motion.Tx = t_fh;
curr_motion.Ty = -t_rl;

% Creates nbins with ~ the same amount of data (k-space points) in each
% one. The output 'bins_all' is a set of thresholds that define each bin
[bins_all] = get_bins_const_dataV2(curr_motion.Tx, nbins, 0); 
% Show_bins(bins_all,curr_motion.Tx)

bins_size = abs(bins_all(:,1) - bins_all(:,2));
if bins_size(nbins) > 6
    bins_all(nbins,2) = sign(bins_all(nbins,2))*(bins_all(nbins,1) + 6);
end

i = find(bins_size == min(bins_size));
ORCCA.bin = i;


%% LOW RESOLUTION BINS (CAMILA'S TECHNIQUE)

if (1)
    
decay = 1; soft_mode = 1;
curr_motion.Tx = t_fh;
curr_motion.Ty = t_rl;
curr_motion.RecVoxel = size(kData,1);

tol = mean(bins_all(:,2)-bins_all(:,1));

clear im_bins_lowres
curr_motion.RecVoxel      = size(kData,1);
[kdata_OUT, At_bins_hard] = Focus_binsV2(kData, At, curr_motion, bins_all);%, 1);


for bbb = 1:nbins
    
    fprintf('Reconstructing bin %d/%d\n', bbb, nbins);
    
    % Soft gating approach. An exponential decay is used
    [kData_W,At_W,R] = soft_gating(kdata_OUT(:,:,:,:,bbb), At_bins_hard, curr_motion, bins_all(bbb,:), tol, decay, soft_mode);
    nIter = 5; % Number of iterations for the itSENSE algorithm
    
    if (1) % reconstruction on 1 CPU
        
        tic;
        At_W = double(At_W);
        kData_W = double(kData_W);
        E  = Cruz_E_3D_CARTESIAN(At_W,csm_total,nCoils,siz,[siz nCoils],coil_rss);
    %     clear At_W coil_rss_bins csm_data_bins

        % Iterative SENSE reconsctruction of each bin
        
        [best_rho,residuals]  = Cart_itSENSE(kData_W,E,nIter,5e-3,0);
        im_bins_lowres(:,:,:,bbb) = best_rho(:,:,:,nIter);
        elapsed_time = toc;
        fprintf('Reconstruction of the bin took: %f seconds\n', elapsed_time);
    
    elseif (0) % reconstruction on multiple CPU
        
        kData_W = fftshift(ifft(ifftshift(kData_W),[], 1));

        csm         = csm_total;
        coil_rss    = sqrt(sum(csm.*conj(csm),4));
        ncoils      = size(kData_W,4);
        siz         = [size(kData_W,1), size(kData_W,2), size(kData_W,3)];
        Ksiz        = size(kData_W);

        % Permute read-out

        At2                 = permute(At_W, [2 3 1]);
        csm2                = permute(csm, [2 3 4 1]);
        coil_rss2           = permute(coil_rss, [2 3 1]);
        kData_W   = permute(kData_W, [2 3 4 1]);
        [sz1, sz2, ~, sz4, ~] = size(kData_W);
        
        tic();
        parfor id = 1:sz4
            E_3D      = Cruz_E_2D_CARTESIAN( At2(:,:,id), csm2(:,:,:,id), ncoils, [sz1 sz2], [sz1 sz2 ncoils], coil_rss2(:,:,id));
            im_bins_lowres(:,:,id,bbb) = solve_CG(kData_W(:,:,:,id), E_3D, nIter, 5e-3);
        end
        toc();
        
    elseif (0) % compressed sensing reconstruction
        
        addpath(genpath('/data/abu17/DATA/NON_RIGID_PROST/ORCCA_CMRA_GUI/bart-0.4.03/')); 
    
        startup;

        kData_W = double(kData_W);
        
        tic;
        im_bins_lowres(:,:,:,bbb) = bart('pics -l1 -S -r0.01 -d5 -i30', kData_W, csm_total);%-r0.01
        toc;
        
    end
        
%     clear E kData_W best_rho
   
end


% Motion Estimation
tic;
DFs_bins_TV = NIFTI_reg_bins_XMR(im_bins_lowres);
elapsed_time = toc;
fprintf('Registration took: %f seconds\n', elapsed_time);
    
end


if(0)
    
% First we need to mask the acquired k-space with an elliptical mask of
% radius 1/2 of the acquired data
imageSizeX = size(kData,3);
imageSizeY = size(kData,2);

[columnsInImage rowsInImage] = meshgrid(1:imageSizeX, 1:imageSizeY);
% Next create the ellipse in the image.
centerX = round(size(kData,3)/2);
centerY = round(size(kData,2)/2);
radX = round(size(kData,3)/4);
radY = round(size(kData,2)/4);
maskPixels = (rowsInImage - centerY).^2/radY^2 + (columnsInImage - centerX).^2/radX^2 <= 1;
mask = repmat(maskPixels, [1, 1,size(kData,1)]);

% Reconstruct each bin with a soft-binning approach. Before reconstruction,
% the coil sensitivity maps are translated to the average position of each
% bin.
decay = 1; soft_mode = 1;
curr_motion.Tx = t_fh;
curr_motion.Ty = t_rl;
curr_motion.RecVoxel = size(kData,1);

tol = mean(bins_all(:,2)-bins_all(:,1));

display('************ Low-resolution bins reconstruction **************')

% Mask for sampling pattern
mask_A    = repmat(permute(mask,[3 1 2]),[1 1 1 size(At,4)]);
At_low    = At & mask_A; clear mask_A
% Mask for k-space
mask_k    = repmat(permute(mask,[3 1 2]),[1 1 1 size(kData,4)]);
kData_low = kData.*mask_k; clear mask_k

% Creates one k-Space per each bin by focusing all the data to the average
% translational position of each bin. At_bins_hard contains the sampling
% matrix for each bin
[kData_bins_low,~] = Focus_binsV2(kData_low, At_low, curr_motion, bins_all);

clear kData_low

for bbb = 1:nbins
    
    % Soft gating approach. An exponential decay is used
    [kData_W,At_W,R] = soft_gating(kData_bins_low(:,:,:,:,bbb), At_low, curr_motion, bins_all(bbb,:), tol, decay, soft_mode);
    At_W = double(At_W);
    kData_W = double(kData_W);
    
    E  = Cruz_E_3D_CARTESIAN(At_W,csm_total,nCoils,siz,[siz nCoils],coil_rss);
    clear At_W coil_rss_bins csm_data_bins
    
    % Iterative SENSE reconsctruction of each bin
    nIter = 5; % Number of iterations for the itSENSE algorithm
    [best_rho,residuals]  = Cart_itSENSE(kData_W,E,nIter,5e-3,0);
    im_bins_lowres(:,:,:,bbb) = best_rho(:,:,:,nIter);
    
    clear E kData_W best_rho
end

clear At_low kData_bins_low

clear mask*

% Get motion fields
tic;
DFs_bins_TV = NIFTI_reg_bins_XMR(im_bins_lowres);
toc;

end



%% HARD GATING  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if(0)
    
disp('************ Separating CMRA data into respiratory bins **************')

curr_motion.RecVoxel      = size(kData,1);
[kdata_OUT, At_bins_hard] = Focus_binsV2(kData, At, curr_motion, bins_all);%, 1);

At_ORCCA    = At_bins_hard;
kdata_ORCCA = kdata_OUT;

if (save_data)
disp('************ Saving binned data **************')
save([path_ORCCA  'SamplingM_ORCCA',], 'At_ORCCA', '-v7.3');
save([path_ORCCA  'Data_ORCCA',], 'kdata_ORCCA', '-v7.3');
end

% clear kdata_ORCCA At_ORCCA

end


%% XD_ORCCA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for bbb = 1:size(bins_all,1)
	curr_shots = find(curr_motion.Tx>=bins_all(bbb,1) & curr_motion.Tx<=bins_all(bbb,2));
	target_pos_mean(bbb).X = mean(curr_motion.Tx(curr_shots));
	target_pos_mean(bbb).Y = mean(curr_motion.Ty(curr_shots));
end

E_CSbins = Cruz_E_BINS_3D_CARTESIAN(At_bins_hard, csm_total, nbins, nCoils, siz, siz, coil_rss);

% clear recon_*
lambda_base = (1*10^-5)*max(abs(kdata_OUT(:))); 
TV_it = 20;%;20;TO CHANGE !

%Sparsity operators and respective weights
param.E                 = E_CSbins;
param.W                 = TempFFT(3);
param.L1Weight          = 0.00; 
   
param.TV                = TVOP();
lambdas                 = 1;
param.TVWeight          = lambdas*lambda_base; % Here use 1
    
param.TV_Temp           = TV_Temp(); 
param.TV_TempWeight     = 0;
    
%param.MTV               = MTV(interpolationMatrices); % nonrigid correction
param.MTV               = TC_XMR_MTVi(target_pos_mean);   % translational correction
lambdat                 = 150;
param.MTVWeight         = lambdat*lambda_base; % Here use 150
    
param.nite              = TV_it;
param.display           = 1;
lsiter_max              = 10;
param.IdWeight          = 0;
param.y = kdata_OUT; % shape: kx, ky, kz, ncoils, nbins

recon_dft = param.E'*param.y;

disp('************ XD-ORCCA reconstruction **************')

[recon_NewTV_STV,recon_it_New_TV_STV] = CSL1NlCg_ORCCA_gui(recon_dft, param, lsiter_max, coil_rss);

XD_ORCCA = recon_NewTV_STV(end:-1:1,end:-1:1,:,:);
ORCCA.XD = XD_ORCCA(:,50:end-50,:,:);
ORCCA.end = 1;


disp('************ Saving XD-ORCCA reconstruction **************')
save([path_ORCCA  'RECON_XD_ORCCA',], 'XD_ORCCA', '-v7.3');
clear XD_ORCCA


disp('************ Estimating nonrigid motion **************')

DFs_bins_TV = NIFTI_reg_bins_XMR(recon_NewTV_STV);
% clear recon*

DFs_ORCCA   = DFs_bins_TV;
disp('************ Saving nonrigid motion fields **************')
save([path_ORCCA  'DFs_ORCCA',], 'DFs_ORCCA', '-v7.3');


% %% NON-RIGID GMD %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % This is the final non-rigid motion correction reconstruction
% % algorithms can be found in /code
% 
% % Load datasets already reconstructed: (run until MOTION CORRECTED K-SPACE)
% path_reco = '/data/abu17/DATA/NON_RIGID_PROST/vAB/vAB2x/';
% load([path_reco 'RECON_ORCCA/Data_ORCCA.mat']); kdata_OUT = kdata_ORCCA;
% load([path_reco 'RECON_ORCCA/DFs_ORCCA.mat']);  DFs_bins_TV = DFs_ORCCA;
% load([path_reco 'RECON_ORCCA/SamplingM_ORCCA.mat']); At_bins_hard = At_ORCCA;
% load([path_reco 'output/csm.mat']);
% coil_rss = sqrt(sum(csm_total.*conj(csm_total),4));
% siz      = [size(DFs_bins_TV,1), size(DFs_bins_TV,2), size(DFs_bins_TV,3)];
% nbins    = size(DFs_bins_TV,5);%  = nbins or = size(bins_all,1);
% nCoils   = size(csm_total,4);
% 
% % Build operator matrix E
% interpolationMatrices = cell(1,nbins);
% Image_size            = zeros(size(DFs_bins_TV,1), size(DFs_bins_TV,2), size(DFs_bins_TV,3)); %sizezeros(siz);
% 
% for b = 1:nbins%size(bins_all,1)
%     interpolationMatrices{b} = resampleMatrix(Image_size, DFs_bins_TV(:,:,:,:,b));  %linear interp
% end
% 
% % remove regions of the coils maps that can cause problems
% coil_rss(isinf(1./coil_rss))    = mean(coil_rss(:));
% coil_rss(coil_rss < 0.1)        = mean(coil_rss(:));
% 
% E_CSbins = Cruz_E_3D_CART_BATCH(interpolationMatrices, At_bins_hard, csm_total, nCoils, siz, size(kdata_OUT), coil_rss);
% 
% disp('************ NMC reconstruction **************');
% 
% [MC_ORCCA_it, residuals] = Cart_itSENSE(kdata_OUT, E_CSbins, 7);
% 
% it = find(residuals<5*10^-3);
% if ~isempty(it)
%     MC_ORCCA = MC_ORCCA_it(:,:,:,it(1));
% else
%     [~,it] = min(residuals(:));
%     MC_ORCCA = MC_ORCCA_it(:,:,:,it);
% end
% 
% MC_ORCCA    = MC_ORCCA(end:-1:1,end:-1:1,:);
% ORCCA.MC    = MC_ORCCA(:,50:end-50,:);
% ORCCA.end   = 2;
% 
% disp('************ Saving NMC reconstruction **************')
% save([path_ORCCA  'RECON_MC_ORCCA',], 'MC_ORCCA_it', '-v7.3');
% 
% clear MC_ORCCA
% clear At_bins_hard
% clear kdata
% 
% disp('************ ALL DONE! **************')


%% NON-RIGID GMD + 3D PROST RECONSTRUCTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is the final non-rigid motion correction reconstructionsave( [path_ORCCA 'RECON_PROST'], 'recon_prost','-v7.3')
%  with 3D PROST reconstruction and ADMM solver

% disp('************ Estimating nonrigid motion **************')
% 
% DFs_bins_TV = NIFTI_reg_bins_XMR(recon_NewTV_STV);
% clear recon*


%%
% Load datasets already reconstructed: (run until MOTION CORRECTED K-SPACE)
% path_reco = '/data/abu17/DATA/NON_RIGID_PROST/vAB/vAB3x/'
% path_reco = '/data/abu17/DATA/NON_RIGID_PROST/vGC_coils+/vGC3x_coils+/' %2 3

% path_reco = '/data/abu17/DATA/NON_RIGID_PROST/vCM_coils+/vCM5x_coils+/' %2 3 5
% path_reco = '/data/abu17/DATA/NON_RIGID_PROST/vGN/vGN3x/' %2 3 5
% path_reco = '/data/abu17/DATA/NON_RIGID_PROST/Patient1mm/'
% % path_reco = '/data/abu17/DATA/NON_RIGID_PROST/Aurelien_submm/12mm_4x/'; %2 3 5
% 
% load([path_reco 'RECON_ORCCA/Data_ORCCA.mat']); kdata_OUT = kdata_ORCCA;
% load([path_reco 'RECON_ORCCA/DFs_ORCCA.mat']);  DFs_bins_TV = DFs_ORCCA;
% load([path_reco 'RECON_ORCCA/SamplingM_ORCCA.mat']); At_bins_hard = At_ORCCA;
% load([path_reco 'output/csm.mat']);
% 
% csm_total = csm_total(:,:,:,[9 15 23]);
% kdata_OUT = kdata_OUT(:,:,:,[9 15 23],:);
% csm_total = csm_total(:,:,:,[4 9 15 16 20 23]);
% kdata_OUT = kdata_OUT(:,:,:,[4 9 15 16 20 23],:);
% 
% coil_rss = sqrt(sum(csm_total.*conj(csm_total),4));
% siz      = [size(DFs_bins_TV,1), size(DFs_bins_TV,2), size(DFs_bins_TV,3)];
% nbins    = size(DFs_bins_TV,5);%  = nbins or = size(bins_all,1);
% nCoils   = size(csm_total,4);

% Build operator matrix E
interpolationMatrices = cell(1,nbins);
Image_size            = zeros(size(DFs_bins_TV,1), size(DFs_bins_TV,2), size(DFs_bins_TV,3)); %sizezeros(siz);

for b = 1:nbins%size(bins_all,1)
    interpolationMatrices{b} = resampleMatrix(Image_size, DFs_bins_TV(:,:,:,:,b));  %linear interp
end

% remove regions of the coils maps that can cause problems
coil_rss(isinf(1./coil_rss))    = mean(coil_rss(:));
coil_rss(coil_rss < 0.1)        = mean(coil_rss(:));

E_CSbins = Cruz_E_3D_CART_BATCH(interpolationMatrices, At_bins_hard, csm_total, nCoils, siz, size(kdata_OUT), coil_rss);

% Parameters: acquisition

Params_acqui.kdata_OUT = kdata_OUT;

% Parameters: PROST

Params_PROST.sig         =  0.04;%lambda;
Params_PROST.patch_sz    =  10;
Params_PROST.max_patch   =  30;
Params_PROST.win         =  20;
Params_PROST.offset      =  3;
Params_PROST.debug       =  1;
Params_PROST.recon_mode  =  3;% 3: 2D / 4: 3D

% Parameters: MR

Params_MR.ADMM_maxit    = 2;%3
Params_MR.CG_minres     = 1e-10;
Params_MR.CG_maxit_ini  = 7;
Params_MR.CG_maxit      = 5;
Params_MR.CG_lambda     = 0.005;
Params_MR.E_CSbins      = E_CSbins;

Params_PROST.sig         =  0.1;%0.06;
% Params_PROST.sig         =  0.06;

% New Parameters:

Params_PROST.sig         =  1;%lambda;
Params_PROST.patch_sz    =  5;
Params_PROST.max_patch   =  20;
Params_PROST.win         =  20;
Params_PROST.offset      =  4;
Params_PROST.debug       =  1;
Params_PROST.recon_mode  =  4;% 3: 2D / 4: 3D
Params_PROST.sharpness   =  0.6;
Params_PROST.type        =  2;% 3: 2D / 4: 3D

% Parameters: MR

Params_MR.ADMM_maxit    = 2;
Params_MR.CG_minres     = 1e-10;
Params_MR.CG_maxit_ini  = 5;
Params_MR.CG_maxit      = 5;
Params_MR.CG_lambda     = 0.3;
Params_MR.E_CSbins      = E_CSbins;


disp('************ NMC reconstruction with 3D PROST **************');

tic;
[x, Rx_it, y_it, x_it] = PROST_NON_RIGID(Params_acqui, Params_MR, Params_PROST);
elapsed_time = toc;
fprintf('Reconstruction took: %f seconds\n', elapsed_time);

disp('************ ALL DONE! **************')

disp('************ Saving NMC-ORCAA-PROST reconstruction **************')

%save([output_folder  'RECON_MC_ORCCA_PROST',], 'x_it', '-v7.3');



%% NON RIGID COMPRESSED SENSING

path_reco = '/data/abu17/NON_RIGID_PROST/Sub_millimeter/CRUZ_GASTAO/RECONSTRUCTION/meas_MID00194_FID64801_CV_nav_iNAV_VD_acc4_0_9/';
path_reco = '/data/abu17/NON_RIGID_PROST/Sub_millimeter/DREGELY_ISABEL/RECONSTRUCTION/meas_MID00115_FID45990_CV_nav_iNAV_VD_res09_x4/';
path_reco = '/data/abu17/NON_RIGID_PROST/Sub_millimeter/JASMIN_JASMIN/RECONSTRUCTION/meas_MID00044_FID44072_CV_nav_iNAV_VD_x4/';
path_reco = '/data/abu17/NON_RIGID_PROST/Sub_millimeter/LOPEZ_KARINA_05_10_2018/RECONSTRUCTION/meas_MID00134_FID07125_CV_nav_iNAV_VD_acc4_0_95_iso/';
path_reco = '/data/abu17/NON_RIGID_PROST/Sub_millimeter/MILOTTA_GIORGIA/RECONSTRUCTION/meas_MID00066_FID06996_CV_nav_iNAV_VD_acc4_0_9/';
path_reco = '/data/abu17/NON_RIGID_PROST/Sub_millimeter/NORDIO_GIOVANNA_2/RECONSTRUCTION/meas_MID00226_FID49558_CV_nav_iNAV_VD_res09_acc4/';
path_reco = '/data/abu17/NON_RIGID_PROST/Sub_millimeter/HAIKUN/RECONSTRUCTION/meas_MID00119_FID07388_CV_nav_iNAV_VD_acc4_0_95_iso/';
path_reco = '/data/abu17/NON_RIGID_PROST/Sub_millimeter/ROCCIA_ELISA/RECONSTRUCTION/meas_MID00261_FID52437_CV_nav_iNAV_VD_res0_9_acc4/';
path_reco = '/data/abu17/NON_RIGID_PROST/Sub_millimeter/ELLIS_SAM/RECONSTRUCTION/meas_MID00550_FID33364_CV_nav_iNAV_VD_acc4/';
path_reco = '/data/abu17/NON_RIGID_PROST/Sub_millimeter/BUSTIN_AURELIEN/09mm_4x/RECON_ORCCA/';

if (1)
    
load([path_reco 'Data_ORCCA.mat']); kdata_OUT = kdata_ORCCA;
load([path_reco 'DFs_ORCCA.mat']);  DFs_bins_TV = DFs_ORCCA;
load([path_reco 'SamplingM_ORCCA.mat']); At_bins_hard = At_ORCCA;
load([path_reco 'csm.mat']);
load([path_reco 'out_motion.mat']);

coil_rss = sqrt(sum(csm_total.*conj(csm_total),4));
siz      = [size(DFs_bins_TV,1), size(DFs_bins_TV,2), size(DFs_bins_TV,3)];
nbins    = size(DFs_bins_TV,5);%  = nbins or = size(bins_all,1);
nCoils   = size(csm_total,4);

nbins = 5;
curr_motion.Tx = motion.t_fh;
curr_motion.Ty = -motion.t_rl;
[bins_all] = get_bins_const_dataV2(curr_motion.Tx, nbins, 0);
bins_size = abs(bins_all(:,1) - bins_all(:,2));
if bins_size(nbins) > 6
    bins_all(nbins,2) = sign(bins_all(nbins,2))*(bins_all(nbins,1) + 6);
end
for bbb = 1:size(bins_all,1)
	curr_shots = find(curr_motion.Tx>=bins_all(bbb,1) & curr_motion.Tx<=bins_all(bbb,2));
	target_pos_mean(bbb).X = mean(curr_motion.Tx(curr_shots));
	target_pos_mean(bbb).Y = mean(curr_motion.Ty(curr_shots));
end

% Build operator matrix E
interpolationMatrices = cell(1,nbins);
Image_size            = zeros(size(DFs_bins_TV,1), size(DFs_bins_TV,2), size(DFs_bins_TV,3)); %sizezeros(siz);

for b = 1:nbins%size(bins_all,1)
    interpolationMatrices{b} = resampleMatrix(Image_size, DFs_bins_TV(:,:,:,:,b));  %linear interp
end

% remove regions of the coils maps that can cause problems
coil_rss(isinf(1./coil_rss))    = mean(coil_rss(:));
coil_rss(coil_rss < 0.1)        = mean(coil_rss(:));

end



E_CSbins = Cruz_E_3D_CART_BATCH(interpolationMatrices, At_bins_hard, csm_total, nCoils, siz, size(kdata_OUT), coil_rss);
% E_CSbins = Cruz_E_BINS_3D_CARTESIAN(At_bins_hard, csm_total, nbins, nCoils, siz, siz, coil_rss);

clear recon_*
lambda_base = (1*10^-5)*max(abs(kdata_OUT(:)));
TV_it = 10;%10

%Sparsity operators and respective weights
param.E                 = E_CSbins;
param.W                 = TempFFT(3);
param.L1Weight          = 0.00; 

param.TV                = TVOP();
lambdas                 = 3; % only spatial TV
param.TVWeight          = lambdas*lambda_base; % Here use 1

param.TV_Temp           = TV_Temp(); 
param.TV_TempWeight     = 0;

%param.MTV               = MTV(interpolationMatrices); % nonrigid correction
param.MTV               = TC_XMR_MTVi(target_pos_mean);   % translational correction
lambdat                 = 0;%150;
param.MTVWeight         = lambdat*lambda_base; % Here use 150

param.nite              = TV_it;
param.display           = 1;
lsiter_max              = 10;
param.IdWeight          = 0;
param.y                 = kdata_OUT;

recon_dft = param.E'*param.y;

disp('************ XD-ORCCA reconstruction **************')

tic();
[recon_CS,recon_it_CS] = CSL1NlCg_ORCCA_gui(recon_dft, param, lsiter_max, coil_rss);
toc();


save([path_reco 'recon_CS.mat'], 'recon_CS');




%% REFORMAT

% non-rigid prost
A = x_it(:,:,:,1,2);
A = remove_PH_oversampling(A, twix);
A = remove_SL_oversampling(A, twix);

native_res  = 0.9;
new_res     = 0.6;
B = interpft3D(A, round(size(A) * native_res / new_res));

B = rotate_and_flip(B);
C = crop3D(B,[480 480 166]);

non_rigid_prost_cor = C; save non_rigid_prost_cor.mat non_rigid_prost_cor


D=permute(C,[2 3 1]);
D=rot90(fliplr(D),1);
E=zeros(480,480,166);
E(201:366,:,:)=D(:,:,201-30:366-30);

non_rigid_prost_sag = E; save non_rigid_prost_sag.mat non_rigid_prost_sag

% reformat
format_write_iT2_V2_bustin


%% MIP

clear A B C

A(:,:,:,1)=(patch(:,:,1:end-4));
A(:,:,:,2)=(patch(:,:,2:end-3));
A(:,:,:,3)=(patch(:,:,3:end-2));
A(:,:,:,4)=(patch(:,:,4:end-1));
A(:,:,:,5)=(patch(:,:,5:end));
B = max(A, [], 4);

C = patch;
C(:,:,3:end-2) = B;

clear A D
patch2 = permute(patch,[3 2 1]);
A(:,:,:,1)=(patch2(:,:,1:end-4));
A(:,:,:,2)=(patch2(:,:,2:end-3));
A(:,:,:,3)=(patch2(:,:,3:end-2));
A(:,:,:,4)=(patch2(:,:,4:end-1));
A(:,:,:,5)=(patch2(:,:,5:end));
B = max(A, [], 4);

D = patch2;
D(:,:,3:end-2) = B;


