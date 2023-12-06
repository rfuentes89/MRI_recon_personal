%% OFFLINE MRI RECON MATLAB CODE - SIEMENS
%
% This code for the offline MRI reconstruction can be used for multi-coil
% and multi-echo mri data. 
%
%
% Matlab version: 
%
% Authors: Alina Schneider, Camila Munoz, Carlos Velasco, Donovan Tripp, Lina Felsner (2022)

addpath(genpath("./"))

%% STEP 0: Parameters
% This section defines the parameters

file_dir_out = "ISMRM2023/RDLS/";
twix_pattern = file_dir_out + 'meas_MID00020_FID16030_FANTOMA_SYS_BOOST_T2MLEV8_T2p60_TI85_1_5mm3_NoScout.dat';
%twix_pattern = file_dir_out + 'meas_MID00066_FID15619_parameters_v1_NoScout.dat';

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


%% Compress coils
disp("compressing coils")
    n_coils = size(data.k_spaces{1}, 4);
    if parameters.n_compressed_coils < n_coils
        data = compress_coils(data, parameters.n_compressed_coils);
    end

%% STEP 4: CSM Estimation

disp("step 4: estimating coil maps")

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

%% STEP 5: Reading iNavs

% TODO: only use coils that weren't rejected?
% TODO: use iNavs from DICOM if available (not necessary)

if (0)
    load('AORTA_data/motion_curves.mat','motion_curves'); % Variable is csm_load.csm

else   
    if motion_correction_type ~= "none"
        disp("step 5: estimating motion")
        motion_curves = estimate_motion_curves(twix, selected_navigators);
    end
end

%% STEP 6: Motion Correction
% Uncorrected
% Rigid
%   - Autofocus YES/NO
%   - Translational (3D)
% Non-Rigid
%   - Binning
%   - Image-bin reconstruction
%   - NR Image registration

if motion_correction_type ~= "none"
    disp("step 6: correcting motion")
    motion_corrected_data = correct_motion(data, motion_curves, csm, motion_correction_type);
end

%% STEP 7: Reconstructions:
% Zero/filled
% itSENSE
% CS reco
% HD-PROST

disp("step 7: reconstructing images")

%images = reconstruct_images(data, csm, reconstruction_type);
if motion_correction_type ~= "none"
    images_moco = reconstruct_images(motion_corrected_data, csm, reconstruction_type);
end

%% Black Blood
disp("Black Blood")
black_blood = abs(images_moco{2}) - abs(images_moco{1});

%% STEP 8: PROST Denoising

if denoising_type ~= "none"
    disp("step 8: denoising")
    %denoised_images = denoise(images_moco, denoising_type);
    denoised_images = denosing_HD_PROST_MULTICONTRAST(images_moco);
end
disp("Done")


%% Save variable for Non rigid detach mode
save('ISMRM2023/GCR/csm_diatole.mat', 'csm','-v7.3');
save('ISMRM2023/GCR/motion_corrected_data_diatole.mat', 'motion_corrected_data','-v7.3');
save('ISMRM2023/GCR/At_bins_diatole.mat', 'At_bins','-v7.3');
disp("SAVED")

%% STEP 7: Reconstructions + Denoising (ADMM + HDPROST)


[n_echoes, n_sets, n_repetitions] = size(motion_corrected_data.k_spaces);
E_CSbins = cell(size(motion_corrected_data.sampling_masks));

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

Params_acqui.kdata_OUT = data.k_spaces_corrected;
Params_MR.E_CSbins      = E_CSbins;

% New Parameters:
% Parameters: PROST
Params_PROST.sig         =  0.055;
Params_PROST.patch_sz    =  5;
Params_PROST.max_patch   =  20;
Params_PROST.win         =  20;
Params_PROST.offset      =  4;
Params_PROST.debug       =  1;
Params_PROST.recon_mode  =  6;% 3: 2D / 4: 3D
Params_PROST.sharpness   =  0;

Params_PROST.type        =  0;% 3: 2D / 4: 3D

% Parameters: MR

Params_MR.ADMM_maxit    = 5;
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

%%
denoised_images{1} = denoised_images{1}(10:200,40:247,9:96);
denoised_images{2} = denoised_images{2}(10:200,40:247,9:96);
%%
deno_blackblood = abs(denoised_images{2}) - abs(denoised_images{1});

%%
imagine(abs(denoised_images{1}),'w',[0 max(abs(denoised_images{1}),[],'all')],abs(denoised_images{2}),'w',[0 max(abs(denoised_images{2}),[],'all')], ...
    abs(deno_blackblood),'w',[0 max(abs(deno_blackblood),[],'all')])

%% DICOM WRITE
file_dir_out = "ISMRM2023/RDLS/";
%%
filename_1 = file_dir_out + "RDLS_SYS_T2MLEV8_TI85_HB1.dcm";
disp(filename_1)
image_scanner_1 = squeeze(dicomread(filename_1));
info_1 = dicominfo(filename_1);
filename_2 = file_dir_out + "RDLS_T2MLEV860_TI85_HB2.dcm";
image_scanner_2 = squeeze(dicomread(filename_2));
info_2 = dicominfo(filename_2);
filename_3 = file_dir_out + "RDLS_SYS_T2_MLEV860_TI85_BB.dcm";
info_3 = dicominfo(filename_3);

%%
write_dicom_volume(abs(denoised_images{1}),'HB1',info_1,[]);
write_dicom_volume(abs(denoised_images{2}),'HB2',info_2,[]);
write_dicom_volume(abs(deno_blackblood),'BB',info_3,[]);
disp("Dicom over-writed")
