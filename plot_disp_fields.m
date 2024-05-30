%%% Plot displacement fields
% Calculate DF from bin images and plot DFs

%% Imports
addpath(genpath("./"))

% Params: choose recon
CONFIG.acq_folder = fullfile(getenv("WORKSPACE"), "acquisitions/2024-01-01_JR_BOOST");
CONFIG.run_name = "2024-05-22_itsense_n-intraTL_decayINF_DFbefore-flip";
contrast_name = "HB1";

%% Load bin images
CONFIG.run_folder = fullfile(CONFIG.acq_folder, "recons", CONFIG.run_name);
prefix = fullfile(CONFIG.run_folder, "dcm", contrast_name + "-bin");
fpaths = dir([convertStringsToChars(prefix), '*', '.dcm']);

assert(numel(fpaths) > 0, "Found zero bin images with prefix: %s", prefix);
bin_images = cell(length(fpaths), 1);
for i_fpath = 1:length(fpaths)
    fpath = fpaths(i_fpath);
    fpath = fullfile(fpath.folder, fpath.name);
    bin_images{i_fpath} = squeeze(dicomread(fpath));
end

fprintf("Loaded %d bin images\n", numel(bin_images));

%% Calculate DFs
% Params
ref_bin = 1;

% Call Nifty
dfs = register_bins(bin_images, ref_bin);
% size: n_x, n_y, n_z, 3, n_bins

fprintf("Finished register_bins()\n");

%% Plot image with DF on top
% Params
target_bin = 4;
i_slice = 40;
downsample_factor = 0.1;

bin_df = dfs(:,:,:,:,target_bin);

% Subplot grid
n_rows = 1;
n_cols = 2;

subplot(n_rows, n_cols, 1);
plot_image(bin_images{ref_bin}(:,:,i_slice));
hold on;
plot_disp_field_2d(bin_df, i_slice, downsample_factor);
title(sprintf("Reference image (bin %d) with DF", ref_bin))
hold off;

subplot(n_rows, n_cols, 2);
plot_image(bin_images{target_bin}(:,:,i_slice));
hold on;
plot_disp_field_2d(bin_df * -1, i_slice, downsample_factor);
title(sprintf("Target image (bin %d) with DF * -1", target_bin))

%% Util functions
function plot_image(img)
    imshow(uint8(rescale(img, 0, 255)));
end

function plot_disp_field_2d(df, i_slice, downsample_factor)
    [n_x, n_y, n_z, n_dims] = size(df);
    assert(n_dims == 3, "DF should be 3D, got %d dims", n_dims);
    assert(i_slice <= n_z, "i_slice must be less than n_z=%d", n_z);

    df_u = imresize(df(:,:,i_slice,1), downsample_factor);
    df_v = imresize(df(:,:,i_slice,2), downsample_factor);
    
    [n_x_ds, n_y_ds] = size(df_u);
    [mesh_x, mesh_y] = meshgrid( ...
        linspace(1, n_y, n_y_ds), ...
        linspace(1, n_x, n_x_ds));
    quiver(mesh_x, mesh_y, df_u, df_v, 'linewidth', 2, 'Color', 'red');
    xlim([1 n_y]);
    ylim([1 n_x]);
    title(sprintf("Disp field slice=%d, ds=%.1f", i_slice, downsample_factor));
    pbaspect([n_y n_x 1])
end
