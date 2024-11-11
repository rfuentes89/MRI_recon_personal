function [data, csm] = reduce_data_debug(data, csm, new_size)
%REDUCE_DATA_DEBUG Reduce data for debugging
    if new_size <= 0, return; end
    warning("Reducing data for debugging: %d", new_size);

    % Calculate crop place around the center
    %[n_fh, n_rl, n_ap] = size(data.specified_image_dimensions);
    fh_range = calculate_crop_site(data.padded_dimensions(1), new_size);
    rl_range = calculate_crop_site(data.padded_dimensions(2), new_size);
    ap_range = calculate_crop_site(data.padded_dimensions(3), new_size);

    data.padded_dimensions = [new_size, new_size, new_size];
    data.specified_image_dimensions = [new_size, new_size, new_size];

    n_contrasts = numel(data.k_spaces);
    for i_contrast = 1:n_contrasts
        data.k_spaces{i_contrast} = data.k_spaces{i_contrast}(fh_range, rl_range, ap_range, :);
        data.sampling_masks{i_contrast} = data.sampling_masks{i_contrast}(fh_range, rl_range, ap_range);
        data.segment_masks{i_contrast} = data.segment_masks{i_contrast}(fh_range, rl_range, ap_range, :);
    end

    csm.coil_sensitivity_maps = csm.coil_sensitivity_maps(fh_range, rl_range, ap_range, :);
    csm.coil_sensitivity_maps_raw = csm.coil_sensitivity_maps_raw(fh_range, rl_range, ap_range);
end

function idx_range = calculate_crop_site(old_size, new_size)
    center = floor(old_size / 2);
    idx_start = floor(center - new_size / 2);
    idx_end = idx_start + new_size - 1;
    idx_range = idx_start:idx_end;
end
