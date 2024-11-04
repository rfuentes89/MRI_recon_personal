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
% Nifty params
params.nifty_params = '--nmi -be 0.01 -omp 16 -sx 14 --rbn 64 --fbn 64';
params.method = "chain";
params.ascending = true;

% Call Nifty
tic();
dfs = register_bins(bin_images, 0, params);
toc();
fprintf("Finished register_bins() %s\n", params.nifty_params);

%% Plot one reference
plot_dfs_oneref(bin_images, dfs, 88, 4, params.nifty_params)

%% Plot matrix
plot_dfs_allref(dfs, 88, 1);

%% Interploate
dfs_interp = interpolate_dfs(dfs, 8);

%% Plot matrix (interpolated)
plot_dfs_allref(dfs_interp, 88, 1);

%% Plot arrow DF matrix
i_slice = 68;
plot_params.downsample_factor = 0.14;

[n_float, n_ref] = size(dfs);

n_rows = n_ref;
n_cols = n_float;

t = tiledlayout(n_rows, n_cols, 'Padding', 'compact', 'TileSpacing', 'compact');

for i_float = 1:n_float
    for i_ref = 1:n_ref
        nexttile;
        df = flip(dfs{i_float, i_ref}, 1);
        plot_df_arrows(df, i_slice, plot_params);
    end
end

%% Plot image with DF arrows on top
% Params
slices = [36, 56, 80];
ref_bin = 4;
plot_params.downsample_factor = 0.4;

% Subplot grid
n_rows = numel(slices);
n_cols = n_bins;

for i_slice = 1:numel(slices)
    i_slice_number = slices(i_slice);
    for i_bin = 1:n_bins
        subplot(n_rows, n_cols, (i_slice-1)*n_bins + i_bin);
        plot_image(bin_images{i_bin}(:,:,i_slice_number));
        hold on;
        plot_df_arrows(dfs{i_bin,ref_bin} * -1, i_slice_number, plot_params);
        title(sprintf("Bin %d, slice=%d", i_bin, i_slice_number))
        hold off;
    end
    sgtitle(sprintf("ref bin = %d", ref_bin));
end


%% Util functions
function plot_image(img)
    imshow(rescale(img, 0, 1));
end
