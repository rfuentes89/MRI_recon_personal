function plot_dfs_oneref(bin_images, dfs, i_slice, ref_bin, extra_title)
%plot_dfs_oneref Plot DFs (FH and RL) for one reference position
    assert(iscell(bin_images));
    assert(iscell(dfs));
    if nargin < 5, extra_title = ""; end

    n_bins = numel(bin_images);

    n_rows = 4;
    n_cols = n_bins;
    for i_bin = 1:n_bins
        bin_image = clip_percentiles(double(bin_images{i_bin}(:,:,i_slice)), 1, 99);

        df = dfs{i_bin, ref_bin};
        df_fh = df(:,:,i_slice,1);
        df_rl = df(:,:,i_slice,2);

        ax = subplot(n_rows, n_cols, i_bin);
        imshow(uint8(rescale(bin_image, 0, 255)));
        colormap(ax,'gray');
        pbaspect(ax, [size(bin_image, 2), size(bin_image, 1), 1]);
        title(sprintf("bin %d", i_bin));

        ax = subplot(n_rows, n_cols, i_bin + n_bins*1);
        plot_image_as_colorfield(sqrt(df_rl.^2 + df_fh.^2), ax);
        title("|FH+RL|");

        ax = subplot(n_rows, n_cols, i_bin + n_bins*2);
        plot_image_as_colorfield(df_fh, ax);
        title("FH");

        ax = subplot(n_rows, n_cols, i_bin + n_bins*3);
        plot_image_as_colorfield(df_rl, ax);
        title("RL");
    end

    sgtitle(sprintf("slice=%d, %s", i_slice, extra_title), 'Interpreter', 'none');
end
