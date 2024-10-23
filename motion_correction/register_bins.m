function displacement_fields = register_bins(bin_images, ref_bin, params)
% REGISTER_BINS Calculate displacement fields by register bin images to one
% another
    if ~exist("params", "var"), params = struct(); end
    params = fill_struct_values(params, struct( ...
        zero_ref_bin=true, ...
        nifty_params='--nmi -be 0.0005 -sx 14', ...
        clip_df=[-1, -1, -1], ...
        tmp_dir=fullfile(getenv("WORKSPACE"), ".nifty/tmp")));

    n_bins = numel(bin_images);
    if ref_bin == 0, ref_bin = 1:n_bins; end

    displacement_fields = cell(n_bins, n_bins);
    image_size = size(bin_images{1});

    for i_ref = 1:numel(ref_bin)
        ref_bin_idx = ref_bin(i_ref);

        reference_image = rescale(abs(bin_images{ref_bin_idx}), 0, 1);

        for i_floating_idx = 1:n_bins
            if params.zero_ref_bin && i_floating_idx == ref_bin_idx
                df = zeros([image_size, 3]);
            else
                floating_image = rescale(abs(bin_images{i_floating_idx}),0,1);

                [~, df] = niftyreg_wrapper( ...
                    reference_image, ...
                    floating_image, ...
                    params.nifty_params, ...
                    params.tmp_dir);

                df = squeeze(df);
                % size: (image_size, 3)
            end
            displacement_fields{i_floating_idx, ref_bin_idx} = df;
        end
    end

    % Clip values
    displacement_fields = cellfun(@(df) clip_df(df, params.clip_df), displacement_fields, 'UniformOutput', false);
end

function df = clip_df(df, clip_limits)
    for i_dim = 1:3
        limit = clip_limits(i_dim);
        if limit < 0, continue; end
        df(:,:,:,i_dim) = clip_values(df(:,:,:,i_dim), -limit, limit);
    end
end
