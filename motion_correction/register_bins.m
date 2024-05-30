function displacement_fields = register_bins(bin_images, ref_bin_idx)
% REGISTER_BINS Register all bin images to one bin (e.g. expiration)

    n_bins = numel(bin_images);
    assert(ref_bin_idx <= n_bins);
    reference_image = abs(bin_images{ref_bin_idx});

    displacement_fields = nan([size(bin_images{1}, 1:3), 3, n_bins]);
    for bin = 1:n_bins
        [~, displacement_field] = nifty_reg( ...
            rescale(reference_image,0,1), ...
            rescale(abs(bin_images{bin}),0,1), ...
            ' --nmi -be 0.0005 -sx 14', ...
            fullfile(getenv("WORKSPACE"), ".nifty-tmp"));

        displacement_field = squeeze(displacement_field);
        displacement_fields(:,:,:,:,bin) = displacement_field;
    end
end
