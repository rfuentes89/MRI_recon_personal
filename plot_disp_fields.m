%%% Plot displacement fields
% Calculate DF from bin images and plot DFs

%% Imports
addpath(genpath("./"))

% Params: choose recon
CONFIG.acq_folder = fullfile(getenv("WORKSPACE"), "acquisitions/2024-01-01_JR_BOOST");
CONFIG.run_name = "2024-05-22_itsense_n-intraTL_decayINF_DFbefore-flip";
CONFIG.run_folder = fullfile(CONFIG.acq_folder, "recons", CONFIG.run_name);
contrast_name = "HB1";

%% Load bin images
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
ref_bin = 4;
target_bin = 1;

% Call Nifty
reference_image = bin_images{ref_bin};
target_image = bin_images{target_bin};
[reg_image, out_df] = nifty_reg( ...
            rescale(abs(reference_image),0,1), ...
            rescale(abs(target_image),0,1), ...
            ' --nmi -be 0.0005 -sx 14', ...
            fullfile(getenv("WORKSPACE"), ".nifty-tmp"));

out_df = squeeze(out_df);

% Post-process (see register_bins.m)
flipped_df = flip(flip(flip(out_df, 1), 2), 3);
out_df_withmesh = Add_mesh_to_DF(out_df);

fprintf("Finished nifty_reg()\n");

%% Plot images and DF
% Params
i_slice = 40;
downsample_factor = 0.3;

% Subplot grid
n_rows = 2;
n_cols = 3;

subplot(n_rows, n_cols, 1)
plot_image(reference_image(:,:,i_slice));
title(sprintf("Reference image (bin %d)", ref_bin));

subplot(n_rows, n_cols, 2)
plot_image(target_image(:,:,i_slice));
title(sprintf("Target image (bin %d)", target_bin));

subplot(n_rows, n_cols, 3)
plot_image(reg_image(:,:,i_slice));
title("Registered image")

subplot(n_rows, n_cols, 4)
plot_disp_field_2d(out_df, i_slice, downsample_factor);
title("original DF");

subplot(n_rows, n_cols, 5)
plot_disp_field_2d(flipped_df, i_slice, downsample_factor);
title("DF flipped");

subplot(n_rows, n_cols, 6)
plot_disp_field_2d(out_df_withmesh, i_slice, downsample_factor);
title("DF after add_mesh_to_DF", 'Interpreter', 'none');

%% Plot image with DF on top
% Params
i_slice = 40;
downsample_factor = 0.1;

% Subplot grid
n_rows = 1;
n_cols = 2;

subplot(n_rows, n_cols, 1);
plot_image(reference_image(:,:,i_slice));
hold on;
plot_disp_field_2d(out_df, i_slice, downsample_factor);
title(sprintf("Reference image (bin %d) with DF", ref_bin))
hold off;

subplot(n_rows, n_cols, 2);
plot_image(target_image(:,:,i_slice));
hold on;
plot_disp_field_2d(out_df * -1, i_slice, downsample_factor);
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
    quiver(mesh_x, mesh_y, df_u, df_v);
    xlim([1 n_y]);
    ylim([1 n_x]);
    title(sprintf("Disp field slice=%d, ds=%.1f", i_slice, downsample_factor));
    pbaspect([n_y n_x 1])
end
