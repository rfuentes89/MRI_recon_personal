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

if isfield(CONFIG, "run_name_prepend_datestamp") && CONFIG.run_name_prepend_datestamp
    CONFIG.run_name = string(datetime("now"), "yyyy-MM-dd") + "_" + CONFIG.run_name;
end

CONFIG.folder_input = strrep(CONFIG.folder_input, "$WORKSPACE", getenv("WORKSPACE"));
CONFIG.folder_output = strrep(CONFIG.folder_output, "$WORKSPACE", getenv("WORKSPACE"));

%% Step 0.1: Save configuration file
disp("Running reconstruction with run name: " + CONFIG.run_name);

CONFIG.timestamp = string(datetime("now"), "yyyy-MM-dd_HH:mm:ss");

%% STEP 1: Read Twix

disp("step 0.1: reading twix")
path_to_twix = find_twix_file(fullfile(CONFIG.folder_input, CONFIG.twix_fname));
twix = read_twix(path_to_twix);

%% STEP 1.1: Unpack raw data

disp("step 1: unpacking raw data")
data = read_raw_data(twix, CONFIG.selected_contrasts, CONFIG.coil_params.use_only);

%% STEP 2: Remove Oversampling

disp("step 2: removing oversampling")
data = remove_readout_oversampling(data);

%% STEP 3: Coil Rejection
% Assume that if coils have already been specified then no further
% rejection required since they are removed in step 1

disp("step 3: rejecting coils")

if CONFIG.coil_params.reject_via_ui && any(structfun(@isempty, CONFIG.selected_contrasts_for_rating))
    % TODO: allow partial selection
    CONFIG.selected_contrasts_for_rating = select_for_coil_rating(data);
end

if CONFIG.coil_params.reject_via_ui && isempty(CONFIG.coil_params.use_only)
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

save_variable_if_config(CONFIG, "csm", CONFIG.save_csm)

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

%% Step 5.1: Ignore right-left motion

if CONFIG.zero_rl_motion
    disp("Zeroing right-left motion")
    for i_contrast = 1:numel(motion_curves)
        motion_curves{i_contrast}.rl = zeros(size(motion_curves{i_contrast}.fh));
    end
end

%% STEP 5.2: Reduce data for debugging

if isfield(CONFIG, "debug_ksize") && CONFIG.debug_ksize > 0
    warning("Reducing data for debugging: " + string(CONFIG.debug_ksize));
    new_size = CONFIG.debug_ksize;
    data.padded_dimensions = [new_size, new_size, new_size];
    data.specified_image_dimensions = [new_size, new_size, new_size];
    n_contrasts = numel(data.k_spaces);
    for i_contrast = 1:n_contrasts
        data.k_spaces{i_contrast} = data.k_spaces{i_contrast}(1:new_size, 1:new_size, 1:new_size, :);
        data.sampling_masks{i_contrast} = data.sampling_masks{i_contrast}(1:new_size, 1:new_size, 1:new_size);
        data.segment_masks{i_contrast} = data.segment_masks{i_contrast}(1:new_size, 1:new_size, 1:new_size, :);
    end

    csm.coil_sensitivity_maps = csm.coil_sensitivity_maps(1:new_size, 1:new_size, 1:new_size, :);
    csm.coil_sensitivity_sum = csm.coil_sensitivity_sum (1:new_size, 1:new_size, 1:new_size);
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

save_variable_if_config(CONFIG, "motion_corrected_data", CONFIG.save_data);

%% STEP 7: Reconstructions:
disp("step 7: reconstructing images")
images = reconstruct_images( ...
    motion_corrected_data, ...
    csm, ...
    CONFIG.reconstruction_type, ...
    CONFIG.motion_correction_params.type, ...
    CONFIG.cg_params, ...
    CONFIG.prost_params);

save_variable_if_config(CONFIG, "images", CONFIG.save_images);

%% STEP 8: PROST Denoising

if CONFIG.denoising_type ~= "none"
    disp("step 8: PROST denoising")
    denoised_images = denoising_HD_PROST(images, CONFIG.prost_params);

    % TODO(pdpino): fixme: HD_PROST requires cell with more than 1 contrast
    % if CONFIG.save_dcm_intrabin
    %     disp("   denoising intrabin images")
    %     for i_contrast = 1:numel(motion_corrected_data.bin_images)
    %         for i_bin = 1:numel(motion_corrected_data.bin_images{i_contrast})
    %             motion_corrected_data.bin_images{i_contrast}{i_bin} = denoising_HD_PROST( ...
    %                 motion_corrected_data.bin_images{i_contrast}{i_bin}, ...
    %                 CONFIG.prost_params);
    %         end
    %     end
    % end
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
    save_dicom(CONFIG, denoised_images{1}, "HB1", "HB1")
    
    if (length(denoised_images) == 2)
        save_dicom(CONFIG, denoised_images{2}, "HB2", "HB2")
        save_dicom(CONFIG, deno_blackblood, "BB", "BB")
    end
end

%% Write Bin images
if CONFIG.save_dcm_intrabin && isfield(motion_corrected_data, "bin_images")
    for i_contrast = 1:numel(motion_corrected_data.bin_images)
        for i_bin = 1:numel(motion_corrected_data.bin_images{i_contrast})
            save_dicom( ...
                CONFIG, ...
                motion_corrected_data.bin_images{i_contrast}{i_bin}, ...
                "HB" + string(i_contrast) + "-bin" + string(i_bin), ...
                "HB" + string(i_contrast))
        end
    end
end

CONFIG.timestamp_end = string(datetime("now"), "yyyy-MM-dd_HH:mm:ss");
save_config_to_file(CONFIG);

%% Small util functions
function save_dicom(config, image, contrast_name, input_info_name)
    folder = fullfile(config.folder_output, "dcm", config.run_name);
    if ~exist(folder, "dir"), mkdir(folder), end

    contrast_name = string(contrast_name);

    info_base = dicominfo(fullfile(config.folder_input, string(input_info_name) + ".dcm"));
    info_base.SeriesDescription = convertStringsToChars(contrast_name + "-" + config.run_name);

    filename = fullfile(folder, contrast_name + ".dcm");
    write_dicom_volume(abs(image), filename, info_base, config.dicom_params);
end

function save_variable_if_config(config, var_name, should_save)
    if should_save
        % HACK: make variable available
        eval("global " + string(var_name))

        folder = fullfile(config.folder_output, var_name);
        if ~exist(folder, "dir"), mkdir(folder), end
        filename = fullfile(folder, config.run_name + ".mat");

        save(filename, var_name);
        disp("Saved " + var_name + " to " + filename);
    end
end


function save_config_to_file(config)
    folder = fullfile(config.folder_output, "config");
    if ~exist(folder, "dir"), mkdir(folder), end

    filename = fullfile(folder, config.run_name + ".json");
    if exist(filename, "file")
        if config.override_if_exists
            warning("Will override run " + filename);
        else
            error("Won't override run " + filename);
        end
    end

    txt = jsonencode(config);

    fid = fopen(filename, "w");
    fprintf(fid, txt);
    fclose(fid);
    disp("Saved config to " + filename);
end

