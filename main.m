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

warning('off','backtrace');

% Choose your config file here
%config_fname = "configs/example_recon.json";

%% STEP 0: Read parameters from file
assert(exist("config_fname", "var"), "config_fname variable must exist");

CONFIG = load_config(config_fname);
CONFIG = clean_config_recon(CONFIG);

%% Step 0.1: Check if run exists
assert(isfolder(CONFIG.acq_folder), "acq_folder does not exist: %s", CONFIG.acq_folder);
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
if CONFIG.save_stdout
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
data = read_raw_data(twix{end}, CONFIG.selected_contrasts, CONFIG.coil_params.use_only);

% Make sure the number of contrasts matches
CONFIG = assert_contrasts_number(data, CONFIG);

%% STEP 1.2: Remove Oversampling

disp("step 1.2: removing oversampling")
data = remove_readout_oversampling(data);

%% STEP 2: Read motion curves from file
if CONFIG.motion_correction_params.type ~= "none"
    motion_curves_file = fullfile(CONFIG.acq_folder, "motion_curves", CONFIG.motion_curve.name + ".mat");
    assert(isfile(motion_curves_file), "motion_curves not found: %s", motion_curves_file);

    disp("step 2: loading motion_curves");
    load(motion_curves_file, 'motion_curves');

    if CONFIG.motion_curve.zero_rl
        disp("Zeroing right-left motion");
        for i_contrast = 1:numel(motion_curves)
            motion_curves{i_contrast}.rl = zeros(size(motion_curves{i_contrast}.rl));
        end
    end
    if CONFIG.motion_curve.zero_fh
        disp("Zeroing foot-head motion");
        for i_contrast = 1:numel(motion_curves)
            motion_curves{i_contrast}.fh = zeros(size(motion_curves{i_contrast}.fh));
        end
    end
end

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
    data.k_spaces = compress_coils_wrapper(data.k_spaces, CONFIG.coil_params.n_compressed_coils);
end

%% STEP 4: CSM Estimation

disp("step 4: estimating coil maps")
csm = get_csm(data, CONFIG.coil_params.csm_algorithm, CONFIG.selected_contrasts_for_rating,CONFIG.coil_params.csm_params);

if CONFIG.save_csm
    filename = fullfile(CONFIG.run_folder, "csm.mat");
    save(filename, "csm");
    disp("Saved csm to " + filename);
end

%% STEP 5: Reduce data for debugging
if CONFIG.debug_ksize > 0
    [data, csm] = reduce_data_debug(data, csm, CONFIG.debug_ksize);
end

%% STEP 6: Motion Correction
if CONFIG.motion_correction_params.type ~= "none"
    disp("step 6: correcting motion")
    data = correct_motion(data, motion_curves, csm, CONFIG.motion_correction_params);
end

%% Load or save bin images
if strlength(CONFIG.motion_correction_params.load_bin_images) > 0
    data.bin_images = load_bin_images_wrapper(CONFIG);
elseif CONFIG.save_dcm_intrabin && isfield(data, "bin_images")
    for i_contrast = 1:numel(data.bin_images)
        cname = string(CONFIG.seq_params.contrast_names{i_contrast});
        info_name = string(CONFIG.seq_params.scanner_dcms{i_contrast});
        for i_bin = 1:numel(data.bin_images{i_contrast})
            save_dicom( ...
                CONFIG, ...
                data.bin_images{i_contrast}{i_bin}, ...
                info_name, ...
                cname + "-binimage" + sprintf("%02d", i_bin))
        end
    end
end

if CONFIG.bins_only, return; end

%% STEP 7: Reconstruction
disp("step 7: reconstructing and denoising images")

n_ref_bins = numel(CONFIG.motion_correction_params.ref_bin);
for i_ref_bin = 1:n_ref_bins
    ref_bin = CONFIG.motion_correction_params.ref_bin(i_ref_bin);
    fprintf("Reconstructing with ref_bin=%d (recon %d/%d)\n", ref_bin, i_ref_bin, n_ref_bins);

    suffix = ternary(n_ref_bins > 1, sprintf("_refpos%02d", ref_bin), "");

    if CONFIG.motion_correction_params.type == "non_rigid"
        data = prepare_displacement_fields( ...
            data, ...
            CONFIG, ...
            ref_bin, ...
            suffix);
    end

    fprintf("\tReconstructing images\n");
    images = reconstruct_images( ...
        data, ...
        csm, ...
        CONFIG.reconstruction_type, ...
        CONFIG.motion_correction_params.type, ...
        CONFIG.admm_params, ...
        CONFIG.prost_params,...
        CONFIG.it_sense_params);

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

%% Functions
function data = prepare_displacement_fields(data, config, ref_bin, fname_suffix)
    df_fname = sprintf("displacement_fields%s.mat", fname_suffix);
    if strlength(config.motion_correction_params.load_disp_fields) > 0
        % Load DFs from previous run
        displacement_fields_file = fullfile( ...
            config.acq_folder, ...
            "recons", ...
            config.motion_correction_params.load_disp_fields, ...
            df_fname);
        assert(isfile(displacement_fields_file), "displacement_fields not found: %s", displacement_fields_file);

        fprintf("\tLoading displacement fields\n");
        load(displacement_fields_file, "displacement_fields");
        data.displacement_fields = displacement_fields;
    else
        fprintf("\tCalculating displacement fields\n");
        timer_df = tic();
        data.displacement_fields = calculate_disp_fields( ...
            data, ...
            ref_bin, ...
            config.motion_correction_params.registration_params);
        fprintf("\t\t\tcalculate_disp_fields() "); toc(timer_df);

        % Save to .mat file
        if config.save_disp_fields
            filename = fullfile(config.run_folder, df_fname);
            save(filename, "-struct", "data", "displacement_fields");
            fprintf("\tSaved DFs to %s\n", filename);
        end
    end

    % Compute interpolation matrices
    timer_interp_matrices = tic();
    data.interpolation_matrices = pre_compute_interpolation_matrix(data.displacement_fields);
    fprintf("\t\t\tprepare_interp_matrices() "); toc(timer_interp_matrices);

    % Point matrices to chosen contrast
    df_contrast = config.motion_correction_params.selected_contrast_for_disp_fields;
    if df_contrast.echo ~= -1
        [n_echoes, n_sets, n_repetitions] = size(data.interpolation_matrices);
        for repetition = 1:n_repetitions
            for set = 1:n_sets
                for echo = 1:n_echoes
                    data.interpolation_matrices{echo,set,repetition} = data.interpolation_matrices{...
                        df_contrast.echo,...
                        df_contrast.set,...
                        df_contrast.repetition};
                end
            end
        end
    end
end

%% Small util functions
function bin_images = load_bin_images_wrapper(config)
    % Select only chosen motion field
    chosen = config.motion_correction_params.selected_contrast_for_disp_fields;
    if chosen.echo ~= -1
        is_chosen = @(echo,set,rep) chosen.echo == echo && chosen.set == set && chosen.repetition == rep;
    else
        is_chosen = @(echo,set,rep) true;
    end

    [n_echoes, n_sets, n_repetitions] = size(config.seq_params.contrast_names);
    bin_images = cell(n_echoes, n_sets, n_repetitions);
    for echo = 1:n_echoes
        for set = 1:n_sets
            for repetition = 1:n_repetitions
                if ~is_chosen(echo,set,repetition), continue; end

                bin_images{echo,set,repetition} = load_bin_images( ...
                    config.acq_folder, ...
                    config.motion_correction_params.load_bin_images, ...
                    config.seq_params.contrast_names{echo,set,repetition});
            end
        end
    end
    fprintf("\tLoaded bin images from %s\n", config.motion_correction_params.load_bin_images);
end

function save_dicom(config, image, input_info_name, contrast_name)
    contrast_name = string(contrast_name);

    % Load or create empty info
    info_fpath = fullfile(config.acq_folder, "dcm", string(input_info_name) + ".dcm");
    if isfile(info_fpath)
        info_base = dicominfo(info_fpath);
    else
        if strlength(input_info_name) > 0, warning("dicom info not found: %s", input_info_name); end
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

function config = assert_contrasts_number(data, config)
% Make sure contrasts names given are the same number of kspaces loaded
% from the twix file.
    n_cnames = numel(config.seq_params.contrast_names);
    n_kspaces = numel(data.k_spaces);
    [n_echoes, n_sets, n_repetitions] = size(data.k_spaces);
    assert(n_cnames == n_kspaces, ...
        "Given %d contrast names for %d kspaces found (echoes=%d, sets=%d, reps=%d)", ...
        n_cnames, n_kspaces, n_echoes, n_sets, n_repetitions);

    % Reshape list of contrasts
    contrasts_shape = [n_echoes, n_sets, n_repetitions];
    config.seq_params.contrast_names = reshape(config.seq_params.contrast_names, contrasts_shape);
    config.seq_params.scanner_dcms = reshape(config.seq_params.scanner_dcms, contrasts_shape);

    % Save numbers explicitly as well
    config.seq_params.n_echoes = n_echoes;
    config.seq_params.n_sets = n_sets;
    config.seq_params.n_repetitions = n_repetitions;
end
