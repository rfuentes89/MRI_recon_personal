%%% Create GIFs for demos
% Steps:
% 1. Create a config file, see configs/gif_example.json for an example
% 2. Select the config_fname in the first lines
% 3. Run this script
%
% GIFs will be saved as: acq_folder/recons/recon_name/gif/gif_mode/*.gif

%% Import files
addpath(genpath("./"))

% Load config
%config_fname = "configs/gif_example.json";
CONFIG = load_config(config_fname);

%% Get DCM filenames
switch lower(CONFIG.mode)
    case "bin_images"
        assert(length(CONFIG.recon_name) == 1, "in mode bin_images you must provide exactly 1 recon_name");

        CONFIG.run_folder = fullfile(CONFIG.acq_folder, "recons", CONFIG.recon_name);
        dcm_fpaths = get_bin_dcm_filepaths(CONFIG.run_folder, CONFIG.contrast_name);
    case "final_recon"
        assert(length(CONFIG.recon_name) > 1, "in mode final_recon you must provide more than 1 recon_name");

        recons_folder = fullfile(CONFIG.acq_folder, "recons");
        dcm_fpaths = get_final_dcm_filepaths(recons_folder, CONFIG.recon_name, CONFIG.contrast_name);

        % GIFs are saved in the last recon
        CONFIG.run_folder = fullfile(recons_folder, CONFIG.recon_name(end));
    otherwise
        error("Mode not recognized: " + string(CONFIG.mode));
end


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

    if CONFIG.lut_params.apply
        window = CONFIG.lut_params.window(i_dcm);
        level = CONFIG.lut_params.level(i_dcm);
        images{i_dcm} = apply_window_level(images{i_dcm}, window, level);
    end

    if CONFIG.mip_params.apply
        images{i_dcm} = calc_mip_image(images{i_dcm}, CONFIG.mip_params);
    end
end

images = cat(4, images{:});

disp("Images size: (nx, ny, nz, n_dcms)")
disp(size(images))

%% Generate GIFs
gif_name = CONFIG.mode;
if strlength(CONFIG.gif_name_suffix) > 0
    gif_name = gif_name + "_" + string(CONFIG.gif_name_suffix);
end
folder_gif = fullfile(CONFIG.run_folder, "gif", gif_name);

switch CONFIG.gif_params.axis
    case {"x", "tra", "transverse"}
        n_slices = size(images, 1);
        get_slice = @(idx) squeeze(images(idx,:,:,:));
    case {"y", "sag", "sagittal"}
        n_slices = size(images, 2);
        get_slice = @(idx) squeeze(images(:,idx,:,:));
    case {"z", "cor", "coronal"}
        n_slices = size(images, 3);
        get_slice = @(idx) squeeze(images(:,:,idx,:));
    otherwise
        error("Axis not recognized: "+ string(CONFIG.gif_params.axis));
end

for i_slice = 1:n_slices
    sliced_im = get_slice(i_slice);
    filename = fullfile(folder_gif, "slice" +sprintf("%03d", i_slice)+ ".gif");

    save_gif(sliced_im, filename, struct(axis="z", delay_time=CONFIG.gif_params.delay_time));
    % Note: axis needs to be z, as the last dimension wants to be animated
end

save_config(folder_gif, CONFIG);
disp(string(n_targets) + " GIFs saved in " + string(folder_gif));


%% Utils
function targets = get_bin_dcm_filepaths(recon_folder, contrast_name)
%get_bin_dcm_filepaths Get bin images filepaths

    dcm_folder = fullfile(recon_folder, "dcm");
    if ~isfolder(dcm_folder)
        error("Recon folder does not exist: " + string(dcm_folder));
    end

    subfiles = dir(dcm_folder);
    prefix = string(contrast_name) + "-bin";
    i_target = 1;
    
    for i_subfile = 1:length(subfiles)
        subfile = subfiles(i_subfile);
        if startsWith(subfile.name, prefix)
            targets{i_target} = fullfile(subfile.folder, subfile.name);
            i_target = i_target + 1;
        end
    end
    if ~exist("targets", "var")
        error("No DCM with prefix " + prefix + " found in " + dcm_folder);
    end
    
    targets = sort(targets);
end

function targets = get_final_dcm_filepaths(base_recons_folder, recon_names, contrast_name)
%get_final_dcm_filepaths Get final recon filepaths

    n_recons = length(recon_names);
    contrast_name = string(contrast_name);

    if ~isfolder(base_recons_folder)
        error("Recons folder does not exist: " + string(base_recons_folder));
    end

    i_target = 1;
    for i_recon = 1:n_recons
        recon_name = recon_names(i_recon);

        dcm_fname = contrast_name + ".dcm";
        dcm_fpath = fullfile(base_recons_folder, recon_name, "dcm", dcm_fname);
        if isfile(dcm_fpath)
            targets{i_target} = dcm_fpath;
            i_target = i_target + 1;
        else
            warning("Contrast not found for recon " + string(dcm_fpath));
        end
    end
    
    if ~exist("targets", "var")
        error("No DCM for contrast " + contrast_name + " for recons");
    end
end
