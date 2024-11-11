%%% Plot displacement fields
% Calculate DF from bin images and plot DFs

%% Imports
addpath(genpath("./"))

% Params: choose recon
CONFIG.acq_folder = fullfile(getenv("WORKSPACE"), "acquisitions/2024-01-01_JR_BOOST");
CONFIG.run_name = "2024-05-22_itsense_n-intraTL_decayINF_DFbefore-flip";
CONFIG.contrast_name = "HB1";
CONFIG.i_slice = 77;

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
dfs_og = register_bins(bin_images, 0, params);
toc();
fprintf("Finished register_bins() %s\n", params.nifty_params);

%% Plot one reference
plot_dfs_oneref(bin_images, dfs_og, CONFIG.i_slice, 4, params.nifty_params)

%% Plot matrix
plot_dfs_allref(dfs_og, CONFIG.i_slice, 1);

%% Interpolate
dfs_interp = interpolate_dfs(dfs_og, 8, struct(method='linear'));

%% Plot matrix (interpolated)
plot_dfs_allref(dfs_interp, CONFIG.i_slice, 1);

%% Plot DF matrix
i_slice = CONFIG.i_slice;
plot_params.downsample_factor = 0.14;
use_arrows = false;
dfs = dfs_og;

[n_float, n_ref] = size(dfs);

n_rows = n_ref;
n_cols = n_float;

t = tiledlayout(n_rows, n_cols, 'Padding', 'compact', 'TileSpacing', 'compact');

for i_float = 1:n_float
    for i_ref = 1:n_ref
        df = dfs{i_float, i_ref};
        ax = nexttile;
        if use_arrows
            plot_df_arrows(flip(df, 1), i_slice, plot_params);
        else
            plot_image_as_colorfield(df(:,:,i_slice,1), ax, struct(cbar=true));
        end
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
