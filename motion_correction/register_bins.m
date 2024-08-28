function displacement_fields = register_bins(bin_images, ref_bin_idx, params)
% REGISTER_BINS Register all bin images to one bin (e.g. expiration)
    if ~exist("params", "var"), params = struct(); end
    params = fill_struct_values(params, struct( ...
        zero_ref_bin=true, ...
        nifty_params='--nmi -be 0.0005 -sx 14', ...
        tmp_dir=fullfile(getenv("WORKSPACE"), ".nifty-tmp")));

    n_bins = numel(bin_images);
    assert(ref_bin_idx <= n_bins);
    reference_image = rescale(abs(bin_images{ref_bin_idx}), 0, 1);

    displacement_fields = nan([size(bin_images{1}, 1:3), 3, n_bins]);
    for i_bin = 1:n_bins
        if params.zero_ref_bin && i_bin == ref_bin_idx
            displacement_field = zeros(size(displacement_fields, 1:4));
        else
            [~, displacement_field] = nifty_reg( ...
                reference_image, ...
                rescale(abs(bin_images{i_bin}),0,1), ...
                params.nifty_params, ...
                params.tmp_dir);

            displacement_field = squeeze(displacement_field);
        end
        displacement_fields(:,:,:,:,i_bin) = displacement_field;
    end
end
