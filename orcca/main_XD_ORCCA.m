% Main XD-ORCCA (respiratory-resolved)and MC-ORCCA (non-rigid
% motion-corrected) reconstruction

% This scripts executes translational motion correction for CMRA data based
% on 2D image navigators (iNAVs). 
% Required functions:   - mapVBVD.m (Siemens code for reading raw data)
%                       - Cruz_E_3D_CARTESIAN.m, Cart_itSENSE.m, mtimes.m 
%                         for image reconstruction
% 
% Required input:       - Path to folder containing iNAVs (.ima or .dcm)                       
%                       - Path to Siemens MR raw data (.dat)
%                       - Coil sensitivity maps (.mat)
%%%%


clear all
clc
close all
addpath(genpath('/home/hq18/Bin_motion_recon/UTILS'))
addpath(genpath('Recon_Operators'))
addpath('/home/hq18/Bin_motion_recon/remove_oversampling')
addpath(genpath('/home/hq18/Bin_motion_recon/ESPIRiT'))

%%
[name_raw,path_raw]    = uigetfile('/media/Aurelien_HD/DATA_CMRA/*.*','read rawdata');
% [name_raw,path_raw]    = uigetfile('/data/hq18/DATA_CMRA/*.*','read rawdata');

tmp=strfind(path_raw,'/');
case_name=path_raw(tmp(end-2)+1:tmp(end-1)-1)
% case_name=path_raw(tmp(end-1)+1:tmp(end)-1)

if path_raw == 0
    return
else
  [~,inav_path]    = uigetfile([path_raw,'*.*'],'read inav');
end
%%

path_ORCCA  = '/data/hq18/Recon_ORCCA/';
if ~isdir(path_ORCCA)
    mkdir(path_ORCCA);
end
%%
coils_rej = 1;
channels  = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 16, 17, 18, 19, 20];
coil_compression = 1;
ncc=8;
%% load sense recon and motion field
% path_sense = '/data/hq18/Motion_CMRA/';
path_flow = '/data/hq18/CMRA_flow_res/';
case_name
[name_flow1,~] = uigetfile(path_flow,'*.mat');
[name_flow2,~] = uigetfile(path_flow,'*.mat');
if isempty(name_flow2) | isempty(name_flow1)
    return;
end

load([path_flow,name_flow1])
load([path_flow,name_flow2])

%% READ RAW DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This section of the code reads the data acquired by the scanner and gets
% the k-space data and relevant measurement parameters
disp('*********** Loading data ********************')

twix_obj_fs = mapVBVD([path_raw,name_raw]);
twix = twix_obj_fs{end};
% t.image.flagIgnoreSeg = 1;
rawdata = twix.image.unsorted();

% Relevant measurement parameters of the acquisition
nCoils = twix.image.NCha; % Number of coils 
nAcq   = twix.image.NAcq; % Number of readouts acquired
nSeg   = twix.image.NSeg; % Number of heartbeats = Number of iNAVs
nKx = twix.image.NCol;  % Number of samples in each readout
nKy = twix.image.NLin;  % Number of phase encoding lines
nKz = twix.image.NPar;  % Number of slices

% Location of the centre of K-space in (Kx,Ky,Kz)
centreKx = twix.image.centerCol(1); 
centreKy = twix.image.centerLin(1);
centreKz = twix.image.centerPar(1);

% Coordinates of each readout in the phase encoding plane
kY  = double(twix.image.Lin); % ky coordinate of each readout
kZ  = double(twix.image.Par); % kz coordinate of each readout
seg = double(twix.image.Seg); % number of heart beat when each 
%% GET DATA and SAMPLING MATRIX %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% there is a faster way of doing this (not tested with ORCCA)
% kSpace is a matrix containing the measured raw data. 
% At is a logical matrix that contains the sampling pattern (section of 
% k-space) measured at each heart beat

disp('******** Sorting data and sampling ********')
At     = false(nKx,nKy,nKz,nSeg);
kData     = zeros(nKx,nKy,nKz,nCoils);

for nnn=1:nAcq
    for ccc=1:nCoils
        kData(:,kY(nnn),kZ(nnn),ccc)=rawdata(:,ccc,nnn);
    end
    At(:,kY(nnn),kZ(nnn),seg(nnn)) = true;
end

clear rawdatanmi +=  (hx + hy) / hxy

[kData, At] = remove_RO_oversampling(kData,At,twix);


%% coil selection and compression
if (coils_rej && ~isempty(channels))
   kData = kData(:,:,:,channels);
end

if coil_compression == 1
%%COMPRESS COILS
dim = 3;
ncalib = 24; 
[sx,sy,sz,Nc] = size(kData);
slwin = 4; 
dispm = [4,8]; 
% crop calibration data
calib = crop(kData,[ncalib,sy,sz,Nc]);
eccmtx = calcECCMtx(calib,dim,ncc);
% crop and align matrices
eccmtx_aligned = alignCCMtx(eccmtx(:,1:ncc,:));
% save([results_folder 'eccmtx_' num2str(acn) '_odd.mat'],'eccmtx_aligned');
ECCDATA_aligned = CC(kData,eccmtx_aligned, dim);


% compute coil image
kData = permute(ECCDATA_aligned,[3 1 2 4]); % raw k-space data after coil compression
clear ECCDATA_aligned
clear eccmtx*
clear calib
end
%% coils with Walsh
img  = ktoi(kData,[1 2 3]);
% imagineTK(image)
csm_total = ismrm_estimate_csm_walsh_3D(img,51,size(img,3));
% imagineTK(squeeze(csm_total(:,:,60,:)))   

csm_total=csm_total./max(abs(csm_total(:)));
coil_rss=sum(csm_total.*conj(csm_total),4);
clear image
%% MOTION CORRECTION (FAST)
try 
    load([inav_path 'tx_curves.mat'],'t_fh_scan','t_fh','t_rl_scan','t_rl');
catch
    [t_fh_scan, t_fh, t_rl_scan, t_rl, inav, ov] = read_tx_curves(inav_path);
end

if (1)
    t_fh = t_fh - mean(t_fh);
    t_rl = t_rl - mean(t_rl);
else
    t_fh_scan = t_fh_scan - mean(t_fh_scan);
    t_rl_scan = t_rl_scan - mean(t_rl_scan);
end

no_rl_motion=0;
scale=1;
t_fh= t_fh.*scale;
t_rl= t_rl.*scale;
if no_rl_motion == 1
t_rl = zeros(size(t_rl));
end
clear motion

tx = t_fh;
thresh = 1;
vis = 1;
bin_size_max = 1.5;
nbins=4;
% Creates nbins with ~ the same amount of data (k-space points) in each
% one. The output 'bins_all' is a set of thresholds that define each bin
[bins_all,~] = binning(tx,thresh,vis,bin_size_max,nbins);
% Reconstruct each bin with a soft-binning approach. Before reconstruction,
% the coil sensitivity maps are translated to the average position of each
% bin.
curr_motion.Tx = tx;
curr_motion.Ty = - zeros(size(t_rl));
curr_motion.RecVoxel = size(kData,1);
tol = mean(bins_all(:,2)-bins_all(:,1));

% Creates one k-Space per each bin by focusing all the data to the average
% translational position of each bin. At_bins_hard contains the sampling
% matrix for each bin
%% focus each bin  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[kdata_OUT,At_bins_hard] = Focus_binsV2(kData,At,curr_motion,bins_all);
nbins=4;
kdata_OUT=kdata_OUT(:,:,:,:,1:nbins);
At_bins_hard=At_bins_hard(:,:,:,1:nbins);
%% HARD GATING or SOFT gating %%%%%%%
clear kData_W At_W
soft_mode=1;
decay=1;

if soft_mode
    for nbin=1:nbins
        [kData_W(:,:,:,:,nbin),At_W(:,:,:,nbin),R] = soft_gating(kdata_OUT(:,:,:,:,nbin),...
            At,curr_motion,bins_all(nbin,:),tol,decay,soft_mode);
        R
    end
else
    At_W = At_bins_hard;
    kData_W = kdata_OUT.*permute(repmat(At_bins_hard,[1,1,1,1,ncc]),[1 2 3 5 4]);
end
%% XD_ORCCA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
curr_motion.RecVoxel = size(kData,1);

sizek=size(kData);
for bbb = 1:size(bins_all,1)
	curr_shots = find(curr_motion.Tx>=bins_all(bbb,1) & curr_motion.Tx<=bins_all(bbb,2));
	target_pos_mean(bbb).X = mean(curr_motion.Tx(curr_shots));
	target_pos_mean(bbb).Y = mean(curr_motion.Ty(curr_shots));
end
%
clear recon_dft
E_CSbins = Cruz_E_BINS_3D_CARTESIAN(At_W,csm_total,nbins,ncc,sizek(1:end-1),sizek,coil_rss);
recon_dft = E_CSbins'*kData_W;
scale = max(abs(recon_dft(:))); 
recon_dft = recon_dft./scale;
kData_W = kData_W./scale;
% 
%%
%Sparsity operators and respective weights
param.E = E_CSbins;
param.W                 = TempFFT(3);
param.TV                = TVOP(); 
param.TV_Temp           = TV_Temp(); 
    
%param.MTV               = MTV(interpolationMatrices); % nonrigid correction
param.MTV               = TC_XMR_MTVi(target_pos_mean);   % translational correction
    
param.nite              = 8;
param.display           = 1;
lsiter_max              = 50;
param.IdWeight          = 0;
param.y = kData_W;
%%
param.L1Weight          = 0.00; 
param.TVWeight          = 0.02; %0.02
param.TV_TempWeight     = 0.0; 
param.MTVWeight         = 0.5; %0.5

%%
% imagineTK(squeeze(recon_dft(:,:,60,:)))
disp('************ XD-ORCCA reconstruction **************')
tic
recon_TV_STV=recon_dft;
for n=1:4
    n
    recon_TV_STV = CSL1NlCg_ORCCA_gui(recon_TV_STV,param,lsiter_max);
end
toc

%% save results
recon_TV_STV=double(abs(recon_TV_STV));
recon_TV_STV(isnan(recon_TV_STV) | isinf(recon_TV_STV))=0;
save([path_ORCCA,case_name,'_ORCCA.mat'],'recon_TV_STV')

recon_dft=double(abs(recon_dft));
recon_dft(isnan(recon_dft) | isinf(recon_dft))=0;
save([path_ORCCA,case_name,'_dft.mat'],'recon_dft')

