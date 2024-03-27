function [weighted_k_spaces, weighted_sampling_masks] = soft_binning(k_space, segment_masks, fh_motion, bin_limits, decay)
    if nargin < 5
        decay = 1;
    end

    n_bins = numel(bin_limits);

    mean_bin_range = mean(cellfun(@(s) s.upper - s.lower, bin_limits));

    weighted_k_spaces = cell(size(bin_limits));
    weighted_sampling_masks = cell(size(bin_limits));
    for bin = 1:n_bins
        mean_displacement = (bin_limits{bin}.lower + bin_limits{bin}.upper) / 2;
        deviations = abs(fh_motion - mean_displacement);

        % deviation == mean_bin_range => weight = 1
        % deviation >  mean_bin_range => weight < 1
        % deviation <  mean_bin_range => weight > 1 but then clipped to 1
        % deviation    within limits  => weight = 1 regardless
        weights = exp(-decay * (deviations / mean_bin_range - 1));
        weights = min(weights, 1); % clip large values to 1

        outside_bin = fh_motion < bin_limits{bin}.lower | bin_limits{bin}.upper <= fh_motion;

        % Segment_masks must be a double to apply the weights
        weighted_segment_masks = double(segment_masks);

        weights = reshape(weights, 1, 1, 1, []);
        weighted_segment_masks(:,:,:,outside_bin) = weighted_segment_masks(:,:,:,outside_bin) .* weights(outside_bin);

        weighted_sampling_masks{bin} = sum(weighted_segment_masks, 4);
        weighted_k_spaces{bin} = k_space(:,:,:,:,bin) .* weighted_sampling_masks{bin};

    end

end