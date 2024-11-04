function plot_df_arrows(df, i_slice, params)
    [n_fh, n_rl, n_z, n_dims] = size(df);
    assert(n_dims == 3, "DF should be 3D, got %d dims", n_dims);
    assert(i_slice <= n_z, "i_slice must be less than n_z=%d", n_z);

    params = fill_struct_values(params, struct( ...
        downsample_factor=0.2, ...
        linewidth=1, ...
        color='red'));

    df_fh = imresize(df(:,:,i_slice,1), params.downsample_factor);
    df_rl = imresize(df(:,:,i_slice,2), params.downsample_factor);
    
    [n_fh_ds, n_rl_ds] = size(df_fh); % downsampled sizes
    [mesh_cols, mesh_rows] = meshgrid( ...
        linspace(1, n_rl, n_rl_ds), ...
        linspace(1, n_fh, n_fh_ds));
    quiver(mesh_cols, mesh_rows, df_rl, df_fh, 'linewidth', params.linewidth, 'Color', params.color);
    xlim([1 n_rl]);
    ylim([1 n_fh]);
    pbaspect([n_rl n_fh 1])
    set(gca,'xtick',[])
    set(gca,'ytick',[])
end

