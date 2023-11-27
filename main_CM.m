% Main XD-ORCCA (respiratory-resolved)and MC-ORCCA (non-rigid
% motion-corrected) reconstruction with PROST reconstruction
% Authors: Teresa Correia (teresa.correia@kcl.ac.uk)
%          Aurelien Bustin (aurelien.bustin@kcl.ac.uk)

addpath(genpath("./"))
%% STEP 0: Parameters
% This section defines the parameters

%file_dir_out = "/mnt/workspace/maparegal/datasets/";

%file_dir_out = "/mnt/workspace/maparegal/datasets/BOOST/20230825_BO/";


file_dir_out = "ISMRM2023/GCR/";
twix_pattern = file_dir_out + 'meas_MID00067_FID16673_GR_DIAS_BOOST_BOOST_T2p60_TI85_1_5mm3_NoScout.dat';
% Path to data
% Path to save outputs
% Outputs to save (debugging)
% Dimensions of data (x, y, z, coils, echoes, set, repetitions)
% Compressed dimensions (coil compression etc.)
% Motion correction scheme

% raw data to include
% [] => use all
selected.coils = [];
selected.echoes = [];
selected.sets = [];
selected.repetitions = [];

% for rating coils, and also for coil map estimation
% TODO: choose a better name
% TODO: should this be two variables?
% TODO: currently these have to be specified relative to the selected
%       indices i.e. as only set four has been selected, set one below
%       actually refers to set four. This should probably be fixed.
selected_for_rating.echo = 1;
selected_for_rating.set = 1;
selected_for_rating.repetition = 1;

% probably only need one echo of the navigator
% TODO: make this less confusing
selected_navigators = selected;
selected_navigators.echoes = 1;

n_compressed_coils = 8;

coil_sensitivity_mapping_algorithm = "ESPIRiT";
% Options:
% "SOS"
% "ESPIRiT"
% "WASLH"

if coil_sensitivity_mapping_algorithm == "BART"
    % can use `what("bart-0.3.01")` to find
    bart_path = "";
    setenv('TOOLBOX_PATH', bart_path);
end

motion_correction_type = "non_rigid";

reconstruction_type = "it_SENSE";

denoising_type = "HD_PROST";

water_fat_algorithm = "none";

if water_fat_algorithm ~= "none"
    CREAM_PDFF_path = "C:\src\CREAM_PDFF";
    include_CREAM_PDFF(CREAM_PDFF_path)    
end

mapping = false;

%% STEP 0.1: Read Twix

disp("step 0.1: reading twix")
path_to_twix = find_twix_file(twix_pattern);
twix = read_twix(path_to_twix);

%% STEP 1: Unpack raw data

disp("step 1: unpacking raw data")
% TODO: use more cell arrays like in read_navigators
data = read_raw_data(twix, selected);

%% STEP 2: Remove Oversampling

disp("step 2: removing oversampling")
data = remove_readout_oversampling(data);

%% STEP 3: Coil Rejection
% Assume that if coils have already been specified then no further
% rejection required since they are removed in step 1

disp("step 3: rejecting coils")

if any(structfun(@isempty, selected_for_rating))
    % TODO: allow partial selection
    selected_for_rating = select_for_coil_rating(data);
end

if isempty(selected.coils)
    [yes_indices, maybe_indices, no_indices] = rate_coils(data, selected_for_rating);
    data = reject_coils(data, vertcat(maybe_indices, no_indices)); % TODO include variable if use maybe or not?
end

%% STEP 5: CSM Estimation

disp("step 5: estimating coil maps")

% TODO: should the echo/set/repetition used for csm estimation be (allowed to
% be) different to those used for rating the coils? (I think the desired
% characteristics are the same for both cases)
csm = estimate_coil_sensitivity_maps(data, coil_sensitivity_mapping_algorithm, selected_for_rating);

% SOS
% ESPIRIT
% WASLH
% The one from the scanner (that reads files)

% filename = ['bruno_data/coil_sensitivity_maps.mat'];
% csm_output = csm.coil_sensitivity_maps;
% save(filename,"csm_output",'-v7.3');

%% STEP 6: Reading iNavs

% TODO: only use coils that weren't rejected?
% TODO: use iNavs from DICOM if available (not necessary)

if (0)
    load('AORTA_data/motion_curves.mat','motion_curves'); % Variable is csm_load.csm

else   
    if motion_correction_type ~= "none"
        disp("step 6: estimating motion")
        motion_curves = estimate_motion_curves(twix, selected_navigators);
    end
end

%%
% plot motion of all navigators in acquisition order
hold on
%plot(fh_displacements(:))

included_1 = abs(motion_curves{1,1,1}.fh - mean(motion_curves{1,1,1}.fh)) <= 2 * std(motion_curves{1,1,1}.fh);
included_2 = abs(motion_curves{1,2,1}.fh - mean(motion_curves{1,2,1}.fh)) <= 2 * std(motion_curves{1,2,1}.fh);

% Without outliers

plot(motion_curves{1}.fh(included_1), 'LineWidth', 1, 'DisplayName', 'SET_1');
plot(motion_curves{2}.fh(included_2), 'LineWidth', 1, 'DisplayName', 'SET_2');

% With outliers
%plot(motion_curves{1}.fh) 
%plot(motion_curves{2}.fh)
ylabel('FH MOTION (Pixels)', 'FontSize', 15);
xlabel('Acquisition Heartbeat (N)', 'FontSize', 15);
%save('AORTA_data/motion_curves.mat', 'motion_curves','-v7.3');
legend("set_1", "set_2",'FontSize',15)

%%
siz = [size(data.k_spaces{1},1) size(data.k_spaces{1},2) size(data.k_spaces{1},3)];
nCoils = size(data.k_spaces{1},4);
[n_echoes, n_sets, n_repetitions] = size(data.k_spaces);
n_bins = 4;
nIter = 5;
data.displacement_fields = cell(size(data.sampling_masks));
kdata_OUT = cell(size(data.sampling_masks));
kData_W = cell(size(data.sampling_masks));
At_W = cell(size(data.sampling_masks));
bin_images_cell = cell(size(data.sampling_masks));
fh_motion_cell = cell(size(data.sampling_masks));
bin_limits_cell = cell(size(data.sampling_masks));
At_bins_hard = cell(size(data.sampling_masks));
% It wasn't considerated the binning process for each set.
% Now it should work also for each repetition and echo.
for repetition = 1:n_repetitions
    for set = 1:n_sets
        for echo = 1:n_echoes
            % Number of respiratory bins
          
            nbins = 4;%5;%
            
            curr_motion.Tx = motion_curves{echo,set,repetition}.fh;
            curr_motion.Ty = zeros(size(motion_curves{echo,set,repetition}.fh));
            
            % Creates nbins with ~ the same amount of data (k-space points) in each
            % one. The output 'bins_all' is a set of thresholds that define each bin
            [bins_all] = get_bins_const_dataV2(curr_motion.Tx, nbins, 0); 
            
            
            % Show_bins(bins_all,curr_motion.Tx)
            bins_size = abs(bins_all(:,1) - bins_all(:,2));
            if bins_size(nbins) > 6
                bins_all(nbins,2) = sign(bins_all(nbins,2))*(bins_all(nbins,1) + 6);
               
            end

            decay = 1; soft_mode = 1;
            curr_motion.RecVoxel = size(data.k_spaces{1},1);
            
            tol = mean(bins_all(:,2)-bins_all(:,1));
            
            [kdata_OUT{echo,set,repetition}, At_bins_hard{echo,set,repetition}] = Focus_binsV2_CM(data.k_spaces{echo,set,repetition}, data.segment_masks{echo,set,repetition}, curr_motion, bins_all);%, 1);
            
            tic();
            for bbb = 1:nbins
                
                fprintf('Reconstructing bin %d/%d\n', bbb, nbins);
                
                % Soft gating approach. An exponential decay is used
                [kData_W{echo,set,repetition},At_W{echo,set,repetition},R] = soft_gating(kdata_OUT{echo,set,repetition}(:,:,:,:,bbb), At_bins_hard{echo,set,repetition}, curr_motion, bins_all(bbb,:), tol, decay, soft_mode);
                nIter = 5; % Number of iterations for the itSENSE algorithm
                
                if (1) % reconstruction on 1 CPU
                    
                    tic();
                    At_W{echo,set,repetition} = double(At_W{echo,set,repetition});
                    kData_W{echo,set,repetition} = double(kData_W{echo,set,repetition});
                    E  = Cruz_E_3D_CARTESIAN(At_W{echo,set,repetition},csm.coil_sensitivity_maps,siz,[siz nCoils],csm.coil_sensitivity_sum);
                %     clear At_W coil_rss_bins csm_data_bins
            
                    % Iterative SENSE reconsctruction of each bin
                    
                    [best_rho,residuals]  = Cart_itSENSE_CM(kData_W{echo,set,repetition},E,nIter,0);%,5e-3,0);
                    im_bins_lowres(:,:,:,bbb) = best_rho(:,:,:,nIter);
                    toc();
                end
            end
            bin_images_cell{echo,set,repetition} = im_bins_lowres;

        end
    end
end
%%
for repetition = 1:n_repetitions
    for set = 1:n_sets
        for echo = 1:n_echoes
            bin_images_cell{echo,set,repetition} = flip(flip(flip(bin_images_cell{echo,set,repetition},3),2),1);
        end
    end
end

%%
DFs_bins_TV = cell(size(data.sampling_masks));
for repetition = 1:n_repetitions
    for set = 1:n_sets
        for echo = 1:n_echoes
            DFs_bins_TV{echo,set,repetition} = NIFTI_reg_bins_XMR(bin_images_cell{echo,set,repetition});
        end
    end
end
%% STEP 8: Reconstructions:
% Zero/filled
% itSENSE
% CS reco
% HD-PROST

interpolationMatrices = cell(1,nbins);
Image_size            = zeros(size(DFs_bins_TV{echo,set,repetition},1), size(DFs_bins_TV{echo,set,repetition},2), size(DFs_bins_TV{echo,set,repetition},3)); %sizezeros(siz);
motion_corrected_data.interpolation_matrix = cell(size(data.sampling_masks));

for repetition = 1:n_repetitions
    for set = 1:n_sets
        for echo = 1:n_echoes

            for b = 1:nbins%size(bins_all,1)
                interpolationMatrices{b} = resampleMatrix(Image_size, DFs_bins_TV{echo,set,repetition}(:,:,:,:,b));  %linear interp
            end

            motion_corrected_data.interpolation_matrix{echo,set,repetition} = interpolationMatrices;
        end
    end
end

motion_corrected_data.k_spaces_corrected = kdata_OUT;
motion_corrected_data.binned_sampling_masks = At_bins_hard;
% remove regions of the coils maps that can cause problems
csm.coil_sensitivity_sum(isinf(1./csm.coil_sensitivity_sum))    = mean(csm.coil_sensitivity_sum(:));
csm.coil_sensitivity_sum(csm.coil_sensitivity_sum < 0.1)        = mean(csm.coil_sensitivity_sum(:));
%%
%images = reconstruct_images(data, csm, reconstruction_type);
if motion_correction_type ~= "none"
    images_moco = reconstruct_images(motion_corrected_data, csm, reconstruction_type);
end

%% STEP 9: PROST Denoising

if denoising_type ~= "none"
    disp("step 9: denoising")
    %denoised_images = denoise(images_moco, denoising_type);
    denoised_images = denosing_HD_PROST_MULTICONTRAST(images_moco);
end
disp("Done")

%%
%%
denoised_images{1} = denoised_images{1}(10:200,40:247,9:96);
denoised_images{2} = denoised_images{2}(10:200,40:247,9:96);
%%
deno_blackblood = abs(denoised_images{2}) - abs(denoised_images{1});

%%
imagine(abs(denoised_images{1}),'w',[0 max(abs(denoised_images{1}),[],'all')],abs(denoised_images{2}),'w',[0 max(abs(denoised_images{2}),[],'all')], ...
    abs(deno_blackblood),'w',[0 max(abs(deno_blackblood),[],'all')])
%% STEP 10: Reconstructions + Denoising

[n_echoes, n_sets, n_repetitions] = size(motion_corrected_data.k_spaces_corrected);
E_CSbins = cell(size(motion_corrected_data.binned_sampling_masks));

for repetition = 1:n_repetitions
    for set = 1:n_sets
        for echo = 1:n_echoes
            E_CSbins{echo,set,repetition} = Cruz_E_3D_CART_BATCH(motion_corrected_data.interpolation_matrix{echo,set,repetition}, motion_corrected_data.binned_sampling_masks{echo,set,repetition}, csm.coil_sensitivity_maps, size(motion_corrected_data.k_spaces_corrected{echo,set,repetition},4), size(motion_corrected_data.k_spaces_corrected{echo, ...
                            set,repetition}, 1:3), ...
                            size(motion_corrected_data.k_spaces_corrected{echo,set,repetition}), ...
                            csm.coil_sensitivity_sum);
        end
    end
end


%%
% NON-RIGID HD-PROST GMD %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is the final non-rigid motion correction reconstruction
% algorithms can be found in /code
% 

Params_acqui.kdata_OUT = motion_corrected_data.k_spaces_corrected;
Params_MR.E_CSbins      = E_CSbins;

% New Parameters:
% Parameters: PROST
Params_PROST.sig         =  0.05;
Params_PROST.patch_sz    =  5;
Params_PROST.max_patch   =  20;
Params_PROST.win         =  20;
Params_PROST.offset      =  4;
Params_PROST.debug       =  1;
Params_PROST.recon_mode  =  6;% 3: 2D / 4: 3D
Params_PROST.sharpness   =  0;

Params_PROST.type        =  0;% 3: 2D / 4: 3D

% Parameters: MR

Params_MR.ADMM_maxit    = 4;
Params_MR.CG_minres     = 1e-10;
Params_MR.CG_maxit_ini  = 5;
Params_MR.CG_maxit      = 5;
Params_MR.CG_lambda     = 0.01;

%%
disp('************ MC reconstruction with 3D HD-PROST **************');
tic();
[x, Rx_it, y_it, x_it] = HDPROST_NON_RIGID(Params_acqui, Params_MR, Params_PROST);
toc();


%%
for repetition = 1:n_repetitions
    for set = 1:n_sets
        for echo = 1:n_echoes
            recon_mc_hdprost{echo,set,repetition} = flip(flip(flip(x(:,:,:,set),1),2),3);
        end
    end
end
disp("******** NON RIGID HD-PROST Reconstruction DONE ********")

%%
bright_blood_HB1 = recon_mc_hdprost{1}(10:200,40:247,9:96);
bright_blood_HB2 = recon_mc_hdprost{2}(10:200,40:247,9:96);
black_blood = abs(bright_blood_HB2) - abs(bright_blood_HB1);

imagine(abs(bright_blood_HB1),'w',[0 max(abs(bright_blood_HB1),[],'all')],abs(bright_blood_HB2),'w',[0 max(abs(bright_blood_HB2),[],'all')], ...
    abs(black_blood),'w',[0 max(abs(black_blood),[],'all')])
%% DICOM WRITE
file_dir_out = "ISMRM2023/GC/";
%%
filename_1 = file_dir_out + "GR_DIAS_MLEV8_60ms_TI85_HB1.dcm";
disp(filename_1)
image_scanner_1 = squeeze(dicomread(filename_1));
info_1 = dicominfo(filename_1);
filename_2 = file_dir_out + "GCR_MLEV8_DIAS_HB2.dcm";
image_scanner_2 = squeeze(dicomread(filename_2));
info_2 = dicominfo(filename_2);
filename_3 = file_dir_out + "GC_DIAS_MLEV(_60ms_TI85_BB.dcm";
info_3 = dicominfo(filename_3);

%%
write_dicom_volume(abs(bright_blood_HB1),'HB1',info_1,[]);
write_dicom_volume(abs(bright_blood_HB2),'HB2',info_2,[]);
write_dicom_volume(abs(black_blood),'BB',info_3,[]);
disp("Dicom over-writed")

%%

hb1 = flip(flip(flip(recon_mc_prost_CM{1},1),2),3);
hb2 = flip(flip(flip(recon_mc_prost_CM{2},1),2),3);

%black_blood = abs(hb2) - abs(hb1);



save('AORTA_data/hb1_CM_test.mat', 'hb1','-v7.3');
save('AORTA_data/hb2_CM_test.mat', 'hb2','-v7.3');
%%
imagine(hb1)