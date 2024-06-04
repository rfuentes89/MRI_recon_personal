function [data, csm] = reduce_data_debug(data, csm, new_size)
%REDUCE_DATA_DEBUG Reduce data for debugging
    warning("Reducing data for debugging: %d", new_size);
    data.padded_dimensions = [new_size, new_size, new_size];
    data.specified_image_dimensions = [new_size, new_size, new_size];

    n_contrasts = numel(data.k_spaces);
    for i_contrast = 1:n_contrasts
        data.k_spaces{i_contrast} = data.k_spaces{i_contrast}(1:new_size, 1:new_size, 1:new_size, :);
        data.sampling_masks{i_contrast} = data.sampling_masks{i_contrast}(1:new_size, 1:new_size, 1:new_size);
        data.segment_masks{i_contrast} = data.segment_masks{i_contrast}(1:new_size, 1:new_size, 1:new_size, :);
    end

    csm.coil_sensitivity_maps = csm.coil_sensitivity_maps(1:new_size, 1:new_size, 1:new_size, :);
    csm.coil_sensitivity_maps_raw = csm.coil_sensitivity_maps_raw(1:new_size, 1:new_size, 1:new_size);
end

