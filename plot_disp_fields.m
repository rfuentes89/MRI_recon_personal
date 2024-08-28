%%% Plot displacement fields
% Calculate DF from bin images and plot DFs

%% Imports
addpath(genpath("./"))

% Params: choose recon
CONFIG.acq_folder = fullfile(getenv("WORKSPACE"), "acquisitions/2024-01-01_JR_BOOST");
CONFIG.run_name = "2024-05-22_itsense_n-intraTL_decayINF_DFbefore-flip";
CONFIG.contrast_name = "HB1";

%% Load bin images
bin_images = load_bin_images(CONFIG.acq_folder, CONFIG.run_name, CONFIG.contrast_name);
n_bins = numel(bin_images);
fprintf("Loaded %d bin images\n", n_bins);

%% Calculate DFs
% Params
ref_bin = 4;

% Call Nifty
params.nifty_params = '--nmi -be 0.01 -vel -sx 1 -omp 5';
dfs = register_bins(bin_images, ref_bin, params);
% size: n_x, n_y, n_z, 3, n_bins

fprintf("Finished register_bins() %s\n", params.nifty_params);

%% Plot as colorfields
plot_dfs_colorfield(bin_images, dfs, 68, params.nifty_params)

%% Plot image with DF arrows on top
% Params
slices = [9, 14, 20];
downsample_factor = 0.4;

% Subplot grid
n_rows = numel(slices);
n_cols = n_bins;

for i_slice = 1:numel(slices)
    i_slice_number = slices(i_slice);
    for i_bin = 1:n_bins
        subplot(n_rows, n_cols, (i_slice-1)*n_bins + i_bin);
        plot_image(bin_images{i_bin}(:,:,i_slice_number));
        hold on;
        plot_disp_field_2d(dfs(:,:,:,:,i_bin) * -1, i_slice_number, downsample_factor);
        title(sprintf("Bin %d, slice=%d", i_bin, i_slice_number))
        hold off;
    end
    sgtitle(sprintf("ref bin = %d", ref_bin));
end


%% Util functions
function plot_image(img)
    imshow(uint8(rescale(img, 0, 255)));
end

function plot_disp_field_2d(df, i_slice, downsample_factor)
    [n_fh, n_rl, n_z, n_dims] = size(df);
    assert(n_dims == 3, "DF should be 3D, got %d dims", n_dims);
    assert(i_slice <= n_z, "i_slice must be less than n_z=%d", n_z);

    df_fh = imresize(df(:,:,i_slice,1), downsample_factor); % foot-head
    df_rl = imresize(df(:,:,i_slice,2), downsample_factor); % right-left
    
    [n_fh_ds, n_rl_ds] = size(df_fh); % downsampled sizes
    [mesh_cols, mesh_rows] = meshgrid( ...
        linspace(1, n_rl, n_rl_ds), ...
        linspace(1, n_fh, n_fh_ds));
    quiver(mesh_cols, mesh_rows, df_rl, df_fh, 'linewidth', 2, 'Color', 'red');
    xlim([1 n_rl]);
    ylim([1 n_fh]);
    title(sprintf("Disp field slice=%d, ds=%.1f", i_slice, downsample_factor));
    pbaspect([n_rl n_fh 1])
end
