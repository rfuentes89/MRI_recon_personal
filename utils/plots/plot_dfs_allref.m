function plot_dfs_allref(dfs, i_slice, i_dim, extra_title)
%PLOT_DFS_ALLREF Plot a matrix with DFs for all reference/floating (one of FH/RL/AP)
    [n_float, n_refs] = size(dfs);
    [n_x, n_y, n_z, n_dims] = size(dfs{1});
    assert(n_dims == 3);
    assert(i_slice <= n_z);
    assert(i_dim <= n_dims);
    if nargin < 4, extra_title = ""; end

    n_cols = n_float;
    n_rows = n_refs;

    dim_names = ["FH", "RL", "AP"];

    for i_float = 1:n_float
        for i_ref = 1:n_refs
            i_subplot = i_float + n_cols * (i_ref - 1);
            ax = subplot(n_rows, n_cols, i_subplot);

            df = dfs{i_float, i_ref};
            df_slice = df(:,:,i_slice,i_dim);
            plot_image_as_colorfield(df_slice, ax);
            title(sprintf("float %d - ref %d", i_float, i_ref));
        end
    end
    sgtitle(sprintf("dim=%s, slice=%d, %s", dim_names(i_dim), i_slice, extra_title), 'Interpreter', 'none');
end
