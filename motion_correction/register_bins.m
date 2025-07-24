function displacement_fields = register_bins(bin_images, ref_bin, voxel_size, params)
% REGISTER_BINS Calculate displacement fields by register bin images to one
% another
    if ~exist("params", "var"), params = struct(); end
    params = fill_struct_values(params, struct( ...
        nifty_params='--nmi -be 0.0005 -sx 14', ...
        clip_df=[-1, -1, -1], ...
        method="pairwise", ...
        orientation="ascending", ...
        tmp_dir=fullfile(getenv("WORKSPACE"), ".nifty/tmp"), ...
        rm_tmp_dir=true));

    % Different tmp_dir for each run
    params.tmp_dir = fullfile(params.tmp_dir, string(datetime('now', 'Format', 'yyyy-MM-dd_HH-mm-ss')));

    if ref_bin == 0, ref_bin = 1:numel(bin_images); end

    switch params.method
        case "pairwise"
            displacement_fields = niftyreg_pairwise(bin_images, ref_bin, voxel_size, params);
        case "chain"
            displacement_fields = niftyreg_chain(bin_images, voxel_size, params);
        otherwise
            error("Method %s not recognized", params.method);
    end

    % Clip values
    displacement_fields = cellfun(@(df) clip_df(df, params.clip_df), displacement_fields, 'UniformOutput', false);

    % Clean directory
    if params.rm_tmp_dir
        delete(fullfile(params.tmp_dir, "*.nii"));
        [~] = rmdir(params.tmp_dir);
    end
end

function df = clip_df(df, clip_limits)
    for i_dim = 1:3
        limit = clip_limits(i_dim);
        if limit < 0, continue; end
        df(:,:,:,i_dim) = clip_values(df(:,:,:,i_dim), -limit, limit);
    end
end
