%%% Create GIF or PNGs for demos
% Steps:
% 1. Create a config file, see configs/example_gif.json for an example
% 2. Select the config_fname in the first lines
% 3. Run this script
%
% GIFs will be saved as: acq_folder/recons/recon_name/gif/mode/*.gif
% PNGs will be saved as: acq_folder/recons/recon_name/png/mode/*.png

%% Import files
addpath(genpath("./"))

%% Load config
%config_fname = "configs/example_gif.json";
CONFIG = load_config(config_fname);

%% Prepare DCM filenames
base_recons_folder = fullfile(CONFIG.acq_folder, "recons");

requires_more_than_one = false;
switch CONFIG.mode
    case "png_final_recon"
        get_filepaths = @get_final_dcm_filepaths;
    case "gif_bin_images"
        get_filepaths = @get_bin_dcm_filepaths;
    case "gif_final_recons"
        requires_more_than_one = true;
        get_filepaths = @get_final_dcm_filepaths;
    case "gif_refpos"
        get_filepaths = @get_refpos_dcm_filepaths;
    otherwise
        error("Mode not recognized: %s", CONFIG.mode);
end

% Get filepaths
if requires_more_than_one
    assert(length(CONFIG.recon_name) > 1, "mode %s requires more than 1 recon_name", CONFIG.mode);
else
    assert(length(CONFIG.recon_name) == 1, "mode %s requires exactly 1 recon_name", CONFIG.mode);
end
dcm_fpaths = get_filepaths(base_recons_folder, CONFIG.recon_name, CONFIG.contrast_name);

% Build output folder
folder_output = build_output_folder(CONFIG);

%% Use arrays in window and level
n_targets = length(dcm_fpaths);

if CONFIG.lut_params.apply
    if length(CONFIG.lut_params.window) == 1
        CONFIG.lut_params.window = repmat(CONFIG.lut_params.window, [n_targets, 1]);
    end
    if length(CONFIG.lut_params.level) == 1
        CONFIG.lut_params.level = repmat(CONFIG.lut_params.level, [n_targets, 1]);
    end
end

%% Load data into images array
images = cell(n_targets,1);
for i_dcm = 1:n_targets
    dcm_filepath = dcm_fpaths{i_dcm};
    images{i_dcm} = double(squeeze(dicomread(dcm_filepath)));
end

%% Normalize to same brightness
if CONFIG.norm_brightness_params.apply
    images = norm_image_brightness(images, CONFIG.norm_brightness_params.target);
end

%% Apply LUT
if CONFIG.lut_params.apply
    for i_image = 1:numel(images)
        window = CONFIG.lut_params.window(i_image);
        level = CONFIG.lut_params.level(i_image);
        images{i_image} = apply_window_level(images{i_image}, window, level);
    end
end

%% Apply MIP
if CONFIG.mip_params.apply
    for i_image = 1:numel(images)
        images{i_image} = calc_mip_image(images{i_image}, CONFIG.mip_params);
    end
end

%% Concatenate images into one array
images = cat(4, images{:});

if CONFIG.verbose
    disp("Images size: (nx, ny, nz, n_dcms)")
    disp(size(images))
end

%% Normalize images for output
images = rescale(images, 0, 255);
images = uint8(images);

%% Generate PNGs/GIFs
if startsWith(CONFIG.mode, "png")
    axis = CONFIG.png_params.axis;
    extension = ".png";

    write_output = @(slice, fname) imwrite(slice, fname);
elseif startsWith(CONFIG.mode, "gif")
    axis = CONFIG.gif_params.axis;
    extension = ".gif";

    CONFIG.gif_params.axis = "z"; % must be z (last dimension will be animated)

    write_output = @(volume, fname) save_gif(volume, fname, CONFIG.gif_params);
else
    error("Mode not png or gif: %s", CONFIG.mode);
end

[slice_at_axis, axis_dim] = get_slicer(axis);
n_slices = size(images, axis_dim);
for i_slice = 1:n_slices
    sliced_im = slice_at_axis(images, i_slice);
    filename = fullfile(folder_output, "slice" +sprintf("%03d", i_slice)+ extension);

    write_output(sliced_im, filename);
end

save_config(folder_output, CONFIG, CONFIG.verbose);
disp(string(n_slices) + " " + extension + "s saved in " + string(folder_output));

%% Utils
function folder_output = build_output_folder(config)
    folder_name = extractBefore(config.mode, 4); % i.e. "gif" or "png"
    switch folder_name
        case "gif"
            axis = config.gif_params.axis;
        case "png"
            axis = config.png_params.axis;
    end

    output_name = sprintf("%s_%s_%s", ...
        extractAfter(config.mode, 4), ...
        config.contrast_name, ...
        axis);

    if strlength(config.name_suffix) > 0
        output_name = output_name + "_" + string(config.name_suffix);
    end

    folder_output = fullfile( ...
        config.acq_folder, ...
        "recons", ...
        config.recon_name(end), ... % save in the last recon if >1
        folder_name, ...
        output_name);

    if ~exist(folder_output, "dir"), mkdir(folder_output); end
end

function targets = get_bin_dcm_filepaths(base_recons_folder, recon_name, contrast_name)
%get_bin_dcm_filepaths Get bin images filepaths for a given recon

    dcm_folder = fullfile(base_recons_folder, recon_name, "dcm");
    assert(isfolder(dcm_folder), "Recon folder does not exist: %s", dcm_folder);

    prefix = string(contrast_name) + "-bin";
    targets = get_filepaths_with_prefix(dcm_folder, prefix);

    assert(numel(targets) > 0, "No DCM with prefix %s found in %s", prefix, dcm_folder);
end

function targets = get_final_dcm_filepaths(base_recons_folder, recon_names, contrast_name)
%get_final_dcm_filepaths Get final recon filepaths for a set of recons

    n_recons = length(recon_names);
    contrast_name = string(contrast_name);

    assert(isfolder(base_recons_folder), "Recons folder does not exist: %s", base_recons_folder);

    i_target = 1;
    for i_recon = 1:n_recons
        recon_name = recon_names(i_recon);
        dcm_folder = fullfile(base_recons_folder, recon_name, "dcm");

        dcm_fpath = fullfile(dcm_folder, contrast_name + ".dcm");
        if ~isfile(dcm_fpath)
            % Try with suffix _refpos
            fpaths = get_filepaths_with_prefix(dcm_folder, contrast_name + "_refpos");
            dcm_fpath = fpaths{end};
            fprintf("Chose DCM with refpos: %s\n", dcm_fpath);
        end

        if isfile(dcm_fpath)
            targets{i_target} = dcm_fpath;
            i_target = i_target + 1;
        else
            warning("Contrast not found for recon %s", dcm_fpath);
        end
    end

    assert(exist("targets", "var"), "No DCM for contrast %s for recons", contrast_name);
end

function targets = get_refpos_dcm_filepaths(base_recons_folder, recon_name, contrast_name)
%get_refpos_dcm_filepaths Get filepaths for final recons with different ref
%positions (for a given recon)
    dcm_folder = fullfile(base_recons_folder, recon_name, "dcm");
    assert(isfolder(dcm_folder), "Recon folder does not exist: %s", dcm_folder);

    prefix = string(contrast_name) + "_refpos";
    targets = get_filepaths_with_prefix(dcm_folder, prefix);
    assert(numel(targets) > 0, "No DCM with prefix %s found in %s", prefix, dcm_folder);
end

function filepaths = get_filepaths_with_prefix(folder_name, prefix)
    folder_and_prefix = fullfile(folder_name, prefix);
    raw_filepaths = dir([convertStringsToChars(folder_and_prefix), '*']);

    concat_folder_with_name = @(fpath) fullfile(fpath.folder, fpath.name);
    filepaths = arrayfun( ...
        concat_folder_with_name, raw_filepaths, ...
        "UniformOutput", false);

    filepaths = sort(filepaths);
end
