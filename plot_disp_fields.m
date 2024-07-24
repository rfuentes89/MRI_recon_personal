%%% Plot displacement fields
% Calculate DF from bin images and plot DFs

%% Imports
addpath(genpath("./"))

% Params: choose recon
CONFIG.acq_folder = fullfile(getenv("WORKSPACE"), "acquisitions/2024-01-01_JR_BOOST");
CONFIG.run_name = "2024-05-22_itsense_n-intraTL_decayINF_DFbefore-flip";
CONFIG.contrast_name = "HB1";

%% Load bin images
CONFIG.run_folder = fullfile(CONFIG.acq_folder, "recons", CONFIG.run_name);
prefix = fullfile(CONFIG.run_folder, "dcm", CONFIG.contrast_name + "-bin");
fpaths = dir([convertStringsToChars(prefix), '*', '.dcm']);

assert(numel(fpaths) > 0, "Found zero bin images with prefix: %s", prefix);
bin_images = cell(length(fpaths), 1);
for i_fpath = 1:length(fpaths)
    fpath = fpaths(i_fpath);
    fpath = fullfile(fpath.folder, fpath.name);
    bin_images{i_fpath} = squeeze(dicomread(fpath));
end

n_bins = numel(bin_images);
fprintf("Loaded %d bin images\n", n_bins);

%% Calculate DFs
% Params
ref_bin = 4;

% Call Nifty
dfs = register_bins(bin_images, ref_bin);
% size: n_x, n_y, n_z, 3, n_bins

fprintf("Finished register_bins()\n");

%% Plot as colorfields
i_slice = 17;

n_rows = 4;
n_cols = n_bins;
for i_bin = 1:n_bins
    bin_image = clip_percentiles(double(bin_images{i_bin}(:,:,i_slice)), 1, 99);

    df_fh = dfs(:,:,i_slice,1,i_bin);
    df_rl = dfs(:,:,i_slice,2,i_bin);

    ax = subplot(n_rows, n_cols, i_bin);
    plot_image(bin_image);
    colormap(ax,'gray');
    pbaspect(ax, [size(bin_image, 2), size(bin_image, 1), 1]);
    title(sprintf("bin %d", i_bin));

    ax = subplot(n_rows, n_cols, i_bin + n_bins);
    plot_disp_field_color(sqrt(df_rl.^2 + df_fh.^2), ax);
    title("Total magnitude");

    ax = subplot(n_rows, n_cols, i_bin + n_bins*2);
    plot_disp_field_color(df_fh, ax);
    title("FH magnitude");

    ax = subplot(n_rows, n_cols, i_bin + n_bins*3);
    plot_disp_field_color(df_rl, ax);
    title("RL magnitude");
end

sgtitle(sprintf("slice=%d", i_slice));


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


%%
function plot_disp_field_color(df, ax)
    % Plot field as image
    imagesc(ax, df, 'AlphaData', 0.8);
    colormap(ax, 'jet');

    % Set colobar limits
    min_value = min(df(:));
    max_value = max(max(df(:)), min_value + eps);
    clim(ax, [min_value, max_value]);

    % Fix aspect ratio
    pbaspect(ax, [size(df, 2), size(df, 1), 1]);
    colorbar();
    axis off;
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
