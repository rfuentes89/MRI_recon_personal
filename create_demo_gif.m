%%% Create GIF for demos
% Steps:
% 1. Create a config file, see configs/example_gif.json for an example
% 2. Select the config_fname in the first lines
% 3. Run this script
%
% GIFs will be saved as: acq_folder/recons/recon_name/gif/mode/*.gif

%% Import files
addpath(genpath("./"))

%% Load config
config_fname = "configs/base_gif.json";
CONFIG = load_config(config_fname);

%% Prepare DCM filenames
base_recons_folder = fullfile(CONFIG.acq_folder, "recons");

switch CONFIG.mode
    % TODO(pdpino): use load_bin_images() and load_final_recons() instead
    case "gif_bin_images"
        get_filepaths = @get_bin_dcm_filepaths;
    case "gif_refpos"
        get_filepaths = @get_refpos_dcm_filepaths;
    case "gif_xyz"
        get_filepaths = @get_final_dcm_filepaths;
    otherwise
        error("Mode not recognized: %s", CONFIG.mode);
end

% Get filepaths
dcm_fpaths = get_filepaths(base_recons_folder, CONFIG.run_name, CONFIG.contrast_name);

% Build output folder
folder_output = build_output_folder(CONFIG);

%% Load data into images array
n_paths = numel(dcm_fpaths);
images = cell(n_paths,1);
for i_dcm = 1:n_paths
    dcm_filepath = dcm_fpaths{i_dcm};
    images{i_dcm} = double(squeeze(dicomread(dcm_filepath)));
end

%% Apply images corrections
images = apply_image_corrections(images, CONFIG.image_params);

%% Apply MIP
if CONFIG.mip_params.apply && ~contains(CONFIG.mode, "xyz")
    for i_image = 1:numel(images)
        images{i_image} = calc_mip_image(images{i_image}, CONFIG.mip_params);
    end
end

%% Animate in a cycle
if CONFIG.cyclic
    n_new = n_paths - 2;
    n_from = n_paths;
    for i_dcm = 1:n_new
        images{n_from + i_dcm} = double(images{n_paths - i_dcm});
    end
end

%% Concatenate images into one array
images = cat(4, images{:});

if CONFIG.verbose
    disp("Images size: (nx, ny, nz, n_dcms)")
    disp(size(images))
end

%% Generate and save GIFs
if CONFIG.mode == "gif_xyz"
    % Generate three 3D GIFs: through x, y and z

    CONFIG.gif_params.norm = true; % required for proper output

    axes = ["x", "y", "z"];
    for i_axis = 1:numel(axes)
        axis = axes(i_axis);

        fname = fullfile(folder_output, sprintf("3d_%s.gif", axis));
        CONFIG.gif_params.axis = axis;

        if CONFIG.mip_params.apply
            CONFIG.mip_params.axis = axis;
            mipped_images = calc_mip_image(images, CONFIG.mip_params);
        else
            mipped_images = images;
        end

        save_gif(mipped_images, fname, CONFIG.gif_params);
    end
    fprintf("%d .gifs saved in %s\n", numel(axes), folder_output);

elseif startsWith(CONFIG.mode, "gif")
    % Generate one GIF per slice, across multiple DICOMs loaded
    CONFIG.gif_params.norm = true; % required for proper output

    slice_axis = CONFIG.gif_params.axis;
    CONFIG.gif_params.axis = "z";
    % axis must be z, last dimension is animated (across multiple DCMs)

    write_gif = @(volume, fname) save_gif(volume, fname, CONFIG.gif_params);

    write_output_per_slice( ...
        images, ...
        write_gif, ...
        slice_axis, ...
        folder_output, ...
        ".gif");
end

save_config(folder_output, CONFIG, CONFIG.verbose);

%% Utils
function write_output_per_slice(volume, write_output, axis, folder_output, extension)
% WRITE_OUTPUT_PER_SLICE Iterate slices in a volume executing write_output
    [slice_at_axis, axis_dim] = get_slicer(axis);
    n_slices = size(volume, axis_dim);

    for i_slice = 1:n_slices
        sliced_im = slice_at_axis(volume, i_slice);
        filename = fullfile(folder_output, sprintf("slice%03d%s", i_slice, extension));

        write_output(sliced_im, filename);
    end

    fprintf("%d %ss saved in %s\n", n_slices, extension, folder_output);
end

function folder_output = build_output_folder(config)
    axis = config.gif_params.axis;

    output_name = sprintf("%s_%s", ...
        extractAfter(config.mode, 4), ...
        config.contrast_name);

    if ~contains(config.mode, "xyz")
        output_name = output_name + "_" + axis;
    end

    if config.cyclic && startsWith(config.mode, "gif")
        output_name = output_name + "_cyc";
    end

    if config.mip_params.apply
        output_name = output_name + "_MIP";
    end

    if strlength(config.name_suffix) > 0
        output_name = output_name + "_" + string(config.name_suffix);
    end

    folder_output = fullfile( ...
        config.acq_folder, ...
        "recons", ...
        config.run_name, ...
        "gif", ...
        output_name);

    if ~exist(folder_output, "dir"), mkdir(folder_output); end
end

function targets = get_bin_dcm_filepaths(base_recons_folder, recon_name, contrast_name)
%get_bin_dcm_filepaths Get bin images filepaths for a given recon

    dcm_folder = fullfile(base_recons_folder, recon_name, "dcm");
    assert(isfolder(dcm_folder), "Recon folder does not exist: %s", dcm_folder);

    prefix = string(contrast_name) + "-binimage";
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
