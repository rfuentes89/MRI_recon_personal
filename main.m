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

assert(~isempty(getenv('NIFTY_PATH')))

%% STEP 0: Read parameters from file
% Choose your config file here
%config_fname = "configs/example.json";

assert(exist("config_fname", "var"), "config_fname variable must exist");

CONFIG = readstruct(config_fname);
[~, RUN_NAME, ~] = fileparts(config_fname);

CONFIG.folder_input = strrep(CONFIG.folder_input, "$WORKSPACE", getenv("WORKSPACE"));
CONFIG.folder_output = strrep(CONFIG.folder_output, "$WORKSPACE", getenv("WORKSPACE"));

disp("Running reconstruction with config file " + string(config_fname));

%% STEP 0.1: Read Twix

disp("step 0.1: reading twix")
path_to_twix = find_twix_file(fullfile(CONFIG.folder_input, CONFIG.twix_fname));
twix = read_twix(path_to_twix);

%% STEP 1: Unpack raw data

disp("step 1: unpacking raw data")
data = read_raw_data(twix, CONFIG.selected_contrasts, CONFIG.coil_params.use_only);

%% STEP 2: Remove Oversampling

disp("step 2: removing oversampling")
data = remove_readout_oversampling(data);

%% STEP 3: Coil Rejection
% Assume that if coils have already been specified then no further
% rejection required since they are removed in step 1

disp("step 3: rejecting coils")

if CONFIG.coil_params.reject_ui && any(structfun(@isempty, CONFIG.selected_contrasts_for_rating))
    % TODO: allow partial selection
    CONFIG.selected_contrasts_for_rating = select_for_coil_rating(data);
end

if CONFIG.coil_params.reject_ui && isempty(CONFIG.coil_params.use_only)
    [yes_indices, maybe_indices, no_indices] = rate_coils(data, CONFIG.selected_contrasts_for_rating);
    data = reject_coils(data, vertcat(maybe_indices, no_indices)); % TODO include variable if use maybe or not?
end


%% STEP 3.1: Compress coils
n_coils = size(data.k_spaces{1}, 4);
if CONFIG.coil_params.n_compressed_coils > 0 && CONFIG.coil_params.n_compressed_coils < n_coils
    disp("step 3.1: compressing coils")
    data = compress_coils(data, CONFIG.coil_params.n_compressed_coils);
end

%% STEP 4: CSM Estimation

disp("step 4: estimating coil maps")
csm = estimate_coil_sensitivity_maps(data, CONFIG.coil_params.csm_algorithm, CONFIG.selected_contrasts_for_rating);

save_variable_if_config(CONFIG.save_csm, "csm")

%% STEP 5: Reading iNavs

% TODO: only use coils that weren't rejected?
% TODO: use iNavs from DICOM if available (not necessary)

if CONFIG.motion_correction_params.type ~= "none"
    motion_curves_folder = fullfile(CONFIG.folder_output, "motion_curves");
    motion_curves_file = fullfile(motion_curves_folder, strrep(CONFIG.twix_fname, ".dat", ".mat"));
    if (CONFIG.load_motion_curves && isfile(motion_curves_file))
        disp("step 5: loading motion_curves")
        load(motion_curves_file, 'motion_curves');  
    else
        disp("step 5: estimating motion")
        motion_curves = estimate_motion_curves(twix, CONFIG.selected_contrasts);
        if ~exist(motion_curves_folder, 'dir'), mkdir(motion_curves_folder), end
        save(motion_curves_file, 'motion_curves')
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

if CONFIG.motion_correction_params.type ~= "none"
    disp("step 6: correcting motion")
    motion_corrected_data = correct_motion(data, motion_curves, csm, CONFIG.motion_correction_params);
else
    motion_corrected_data = data;
end

save_variable_if_config(CONFIG.save_data, "motion_corrected_data");

%% STEP 7: Reconstructions:
disp("step 7: reconstructing images")
images = reconstruct_images( ...
    motion_corrected_data, csm, CONFIG.reconstruction_type, CONFIG.cg_params, CONFIG.prost_params);

save_variable_if_config(CONFIG.save_images, "images");

%% STEP 8: PROST Denoising

if CONFIG.denoising_type ~= "none"
    disp("step 8: PROST denoising")
    denoised_images = denoising_HD_PROST(images, CONFIG.prost_params);

    if CONFIG.save_dcm_intrabin
        disp("   denoising intrabin images")
        for i_contrast = 1:numel(motion_corrected_data.bin_images)
            for i_bin = 1:numel(motion_corrected_data.bin_images{i_contrast})
                motion_corrected_data.bin_images{i_contrast}{i_bin} = denoising_HD_PROST( ...
                    motion_corrected_data.bin_images{i_contrast}{i_bin}, ...
                    CONFIG.prost_params);
            end
        end
    end
    disp("PROST done")
else
    denoised_images = images;
end


%% Remove borders
% for image_i = 1:length(denoised_images)
%     denoised_images{image_i} = denoised_images{image_i}(10:200,40:247,9:96);
% end

%% Black blood
if (length(denoised_images) == 2)
    deno_blackblood = abs(denoised_images{2}) - abs(denoised_images{1});
end

%% Display with Imagine
% imagine(...
%     abs(denoised_images{1}),'w',[0 max(abs(denoised_images{1}),[],'all')],...
%     abs(denoised_images{2}),'w',[0 max(abs(denoised_images{2}),[],'all')], ...
%     abs(deno_blackblood),'w',[0 max(abs(deno_blackblood),[],'all')]...
%     )

%% Write main DICOM
if CONFIG.save_dcm
    save_dicom(denoised_images{1}, "HB1", "HB1")
    
    if (length(denoised_images) == 2)
        save_dicom(denoised_images{2}, "HB2", "HB2")
        save_dicom(deno_blackblood, "BB", "BB")
    end
end

%% Write Bin images
if CONFIG.save_dcm_intrabin
    for i_contrast = 1:numel(motion_corrected_data.bin_images)
        for i_bin = 1:numel(motion_corrected_data.bin_images{i_contrast})
            save_dicom( ...
                motion_corrected_data.bin_images{i_contrast}{i_bin}, ...
                "HB" + string(i_contrast) + "-bin" + string(i_bin), ...
                "HB" + string(i_contrast))
        end
    end
end

%% Small util functions
function save_dicom(image, contrast_name, input_info_name)
    folder = fullfile(CONFIG.folder_output, "dcm", RUN_NAME);
    if ~exist(folder, "dir"), mkdir(folder), end

    contrast_name = string(contrast_name);

    info_base = dicominfo(fullfile(folder_input, string(input_info_name) + ".dcm"));
    info_base.SeriesDescription = convertStringsToChars(contrast_name + "-" + RUN_NAME);

    filename = fullfile(folder, contrast_name + ".dcm");
    write_dicom_volume(abs(image), filename, info_base, CONFIG.dicom_params);
end


function save_variable_if_config(config, var_name)
    if config
        folder = fullfile(CONFIG.folder_output, var_name);
        if ~exist(folder, "dir"), mkdir(folder), end
        filename = fullfile(folder, RUN_NAME + ".mat");
    
        save(filename, var_name);
        disp("Saved " + var_name + " to " + filename);
    end
end

