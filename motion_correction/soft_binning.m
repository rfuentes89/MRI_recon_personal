function [weighted_k_spaces, weighted_sampling_masks, bin_weights] = soft_binning(k_space, segment_masks, fh_motion, bin_limits, params)
    if nargin < 5
        params.soft_decay = 1;
        params.soft_fn = "bins_avg";
    end

    n_bins = numel(bin_limits);

    mean_bin_range = mean(cellfun(@(s) s.upper - s.lower, bin_limits));

    switch params.soft_fn
        case "bins_avg"
            % deviation == mean_bin_range => weight = 1
            % deviation >  mean_bin_range => weight < 1
            % deviation <  mean_bin_range => weight > 1 but then clipped to 1
            % deviation    within limits  => weight = 1 regardless
            calculate_weights_fn = @(dev, ~) exp(-params.soft_decay * (dev / mean_bin_range - 1));
        case "bin_range"
            calculate_weights_fn = @(dev, bin_range) exp(-params.soft_decay * (dev - bin_range));
        case "bin_range_scaled"
            calculate_weights_fn = @(dev, bin_range) exp(-params.soft_decay * (dev / bin_range - 1));
        otherwise
            error("Soft gating function not recognized: " + string(params.soft_fn));
    end

    weighted_k_spaces = cell(size(bin_limits));
    weighted_sampling_masks = cell(size(bin_limits));
    bin_weights = cell(n_bins, 1);

    for bin = 1:n_bins
        mean_displacement = (bin_limits{bin}.lower + bin_limits{bin}.upper) / 2;
        deviations = abs(fh_motion - mean_displacement);

        bin_range = (bin_limits{bin}.upper - bin_limits{bin}.lower) / 2;
        weights = calculate_weights_fn(deviations, bin_range);
        weights = min(weights, 1); % clip large values to 1
        bin_weights{bin} = weights;

        outside_bin = fh_motion < bin_limits{bin}.lower | bin_limits{bin}.upper <= fh_motion;

        % Segment_masks must be a double to apply the weights
        weighted_segment_masks = double(segment_masks);

        weights = reshape(weights, 1, 1, 1, []);
        weighted_segment_masks(:,:,:,outside_bin) = weighted_segment_masks(:,:,:,outside_bin) .* weights(outside_bin);

        weighted_sampling_masks{bin} = sum(weighted_segment_masks, 4);
        weighted_k_spaces{bin} = k_space(:,:,:,:,bin) .* weighted_sampling_masks{bin};

    end

end