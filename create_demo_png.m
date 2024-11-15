%%% Create PNGs for demos
%% Import files
addpath(genpath("./"));

%% Load config
config_fname = "configs/base_png.json";
CONFIG = load_config(config_fname);

%% Load images
images = load_final_recons(CONFIG.acq_folder, CONFIG.run_name, CONFIG.contrast_name);

%% Apply images corrections
images = apply_image_corrections(images, CONFIG.image_params);
images = cat(4, images{:});
% size: nx, ny, nz, n_refpos

%% Choose axis
[slice_at_axis, axis_dim] = get_slicer(CONFIG.axis);

%% Choose slices
if isstring(CONFIG.slices)
    target_slices = eval(CONFIG.slices);
elseif isnumeric(CONFIG.slices) && all(CONFIG.slices > 0)
    target_slices = CONFIG.slices;
else
    target_slices = 1:size(images, axis_dim);
end

%% Generate and save PNGs
folder_output = build_output_folder(CONFIG);
n_refpos = size(images, 4);

for i_slice = target_slices
    for i_refpos = 1:n_refpos
        target_image = slice_at_axis(images, i_slice); % slice x, y or z
        target_image = target_image(:,:,i_refpos); % slice refpos
        target_image = uint8(rescale(target_image, 0, 255)); % normalize

        filename = fullfile(folder_output, sprintf("slice%03d_refpos%02d.png", i_slice, i_refpos));    
        imwrite(target_image, filename);
    end
end

fprintf("%d pngs saved in %s\n", numel(target_slices) * n_refpos, folder_output);

save_config(folder_output, CONFIG, false);

%% Utils
function folder_output = build_output_folder(config)
    output_name = sprintf("%s_%s", config.contrast_name, config.axis);

    folder_output = fullfile( ...
        config.acq_folder, ...
        "recons", ...
        config.run_name, ...
        "png", ...
        output_name);

    if ~exist(folder_output, "dir"), mkdir(folder_output); end
end
