function bin_images = reconstruct_bin_images(k_spaces, sampling_masks, csm)
% RECONSTRUCT_BIN_IMAGES Reconstruct one image per bin

    n_bins = numel(k_spaces);

    filter_dims = size(k_spaces{1}, 1:3);
    filter_std = 40;

    filter = fspecial3('gaussian', filter_dims, filter_std);

    bin_images = cell(size(k_spaces));
    for bin = 1:n_bins

        filtered_k_space = k_spaces{bin} .* filter;

        bin_image = it_SENSE(filtered_k_space, sampling_masks{bin}, csm);
        bin_images{bin} = Normalize(abs(bin_image), 0, 1);

    end
end
