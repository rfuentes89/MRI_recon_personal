%% OFFLINE MRI RECON MATLAB CODE - SIEMENS
%
% This code for the offline MRI reconstruction can be used for multi-coil
% and multi-echo mri data.
%
%
% Matlab version:
%
% Authors: Alina Schneider, Camila Munoz, Carlos Velasco, Donovan Tripp, Lina Felsner (2022)

addpath(genpath("./"));

assert(~isempty(getenv('NIFTY_PATH')));
warning('off','backtrace');

% Choose your config file here
%config_fname = "configs/example_recon.json";

%% STEP 0: Read parameters from file
assert(exist("config_fname", "var"), "config_fname variable must exist");

CONFIG = load_config(config_fname);
CONFIG = clean_config_recon(CONFIG);

%% Step 0.1: Check if run exists
if exist(CONFIG.run_folder, "dir")
    if CONFIG.override_if_exists
        warning("Will override run %s", CONFIG.run_name);
    else
        error("Won't override run %s", CONFIG.run_name);
    end
else
    mkdir(CONFIG.run_folder);
end

%% Step 0.2: Setup diary
if isfield(CONFIG, 'save_stdout') && CONFIG.save_stdout
    diary_fname = fullfile(CONFIG.run_folder, "stdout.txt");
    diary(diary_fname);
end

%% Step 0.3: Save configuration file
disp("Running reconstruction with run name: " + CONFIG.run_name);

save_config(CONFIG.run_folder, CONFIG);

%% STEP 1: Read Twix

disp("step 0.1: reading twix")
path_to_twix = find_twix_file(fullfile(CONFIG.acq_folder, "raw", CONFIG.twix_fname));
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
csm = get_csm(data, CONFIG.coil_params.csm_algorithm, CONFIG.selected_contrasts_for_rating);

if CONFIG.save_csm
    filename = fullfile(CONFIG.run_folder, "csm.mat");
    save(filename, "csm");
    disp("Saved csm to " + filename);
end

%% STEP 5: Reading iNavs

% TODO: only use coils that weren't rejected?
% TODO: use iNavs from DICOM if available (not necessary)

if CONFIG.motion_correction_params.type ~= "none"
    motion_curves_folder = fullfile(CONFIG.acq_folder, "motion_curves");
    motion_curves_file = fullfile(motion_curves_folder, CONFIG.motion_curve.name + ".mat");
    if (~CONFIG.motion_curve.recompute && isfile(motion_curves_file))
        disp("step 5: loading motion_curves")
        load(motion_curves_file, 'motion_curves');
    else
        disp("step 5: estimating motion")
        base_fname = fullfile(motion_curves_folder, CONFIG.motion_curve.name);
        if ~exist(motion_curves_folder, 'dir'), mkdir(motion_curves_folder), end

        motion_curves = estimate_motion_curves(twix, CONFIG.selected_contrasts, base_fname);
        save(motion_curves_file, 'motion_curves')
    end
end

%% Step 5.1: Ignore right-left motion
if CONFIG.motion_correction_params.type ~= "none" && CONFIG.zero_rl_motion
    disp("Zeroing right-left motion")
    for i_contrast = 1:numel(motion_curves)
        motion_curves{i_contrast}.rl = zeros(size(motion_curves{i_contrast}.fh));
    end
end

%% STEP 5.2: Reduce data for debugging
if isfield(CONFIG, "debug_ksize") && CONFIG.debug_ksize > 0
    [data, csm] = reduce_data_debug(data, csm, CONFIG.debug_ksize);
end


%% STEP 6: Motion Correction
if CONFIG.motion_correction_params.type ~= "none"
    disp("step 6: correcting motion")
    motion_corrected_data = correct_motion(data, motion_curves, csm, CONFIG.motion_correction_params);
else
    motion_corrected_data = data;
end

%% Save bin images
if CONFIG.save_dcm_intrabin && isfield(motion_corrected_data, "bin_images")
    for i_contrast = 1:numel(motion_corrected_data.bin_images)
        cname = string(CONFIG.seq_params.contrast_names{i_contrast});
        info_name = string(CONFIG.seq_params.scanner_dcms{i_contrast});
        for i_bin = 1:numel(motion_corrected_data.bin_images{i_contrast})
            save_dicom( ...
                CONFIG, ...
                motion_corrected_data.bin_images{i_contrast}{i_bin}, ...
                info_name, ...
                cname + "-binimage" + sprintf("%02d", i_bin))
        end
    end
end

%% STEP 7: Reconstruction
disp("step 7: reconstructing and denoising images")

n_ref_bins = numel(CONFIG.motion_correction_params.ref_bin);
for i_ref_bin = 1:n_ref_bins
    ref_bin = CONFIG.motion_correction_params.ref_bin(i_ref_bin);
    fprintf("Reconstructing with ref_bin=%d (recon %d/%d)\n", ref_bin, i_ref_bin, n_ref_bins);

    suffix = ternary(n_ref_bins > 1, sprintf("_refpos%02d", ref_bin), "");

    if CONFIG.motion_correction_params.type == "non_rigid"
        fprintf("\tCalculating displacement fields\n");
        motion_corrected_data = calculate_disp_fields( ...
            motion_corrected_data, ...
            CONFIG.motion_correction_params.selected_contrast_for_disp_fields, ...
            ref_bin);

        % Save to .mat file
        if CONFIG.save_disp_fields
            filename = fullfile(CONFIG.run_folder, "displacement_fields" + suffix + ".mat");
            save(filename, "-struct", "motion_corrected_data", "displacement_fields");
            disp("\tSaved DFs to " + filename);
        end
    end

    fprintf("\tReconstructing images\n");
    images = reconstruct_images( ...
        motion_corrected_data, ...
        csm, ...
        CONFIG.reconstruction_type, ...
        CONFIG.motion_correction_params.type, ...
        CONFIG.cg_params, ...
        CONFIG.prost_params);

    % Check for nan and inf
    images = fix_nan_and_inf(images);

    % PROST Denoising
    if CONFIG.denoising_type ~= "none"
        fprintf("\tPROST denoising\n");
        images = denoising_HD_PROST(images, CONFIG.prost_params);
    end

    if CONFIG.save_images
        filename = fullfile(CONFIG.run_folder, sprintf("images%s.mat", suffix));
        save(filename, "images");
        disp("Saved denoised images to " + filename);
    end

    if ~CONFIG.save_dcm, continue; end

    % Write main DICOM
    for image_i = 1:numel(images)
        cname = string(CONFIG.seq_params.contrast_names{image_i}) + suffix;
        info_name = CONFIG.seq_params.scanner_dcms{image_i};
        save_dicom(CONFIG, images{image_i}, info_name, cname);
    end

    % Write black blood DICOM
    if (numel(images) == 2) && isstruct(CONFIG.seq_params.bb)
        bb = CONFIG.seq_params.bb;
        deno_blackblood = abs(images{2}) - abs(images{1});
        bb_name = string(bb.contrast_name) + suffix;
        save_dicom(CONFIG, deno_blackblood, bb.scanner_dcm, bb_name);
    end
end

%% Write config at end
CONFIG.timestamp_end = string(datetime("now"), "yyyy-MM-dd_HH:mm:ss");
save_config(CONFIG.run_folder, CONFIG);

%% Small util functions
function save_dicom(config, image, input_info_name, contrast_name)
    contrast_name = string(contrast_name);

    % Load or create empty info
    info_fpath = fullfile(config.acq_folder, "dcm", string(input_info_name) + ".dcm");
    if isfile(info_fpath)
        info_base = dicominfo(info_fpath);
    else
        info_base = build_empty_dicominfo();
    end

    % Replace SeriesDescription
    run_wo_datestamp = regexprep(config.run_name, "^\d\d\d\d-\d\d-\d\d_", "");
    info_base.SeriesDescription = convertStringsToChars(contrast_name + "-" + run_wo_datestamp);

    % Write output
    folder = fullfile(config.run_folder, "dcm");
    if ~exist(folder, "dir"), mkdir(folder), end
    filename = fullfile(folder, contrast_name + ".dcm");
    write_dicom_volume(abs(image), filename, info_base, config.dicom_params);
end
