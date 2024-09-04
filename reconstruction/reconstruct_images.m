function images = reconstruct_images( ...
    data, csm, reconstruction_type, motion_correction_type, admm_params, prost_params, it_sense_params)

    % Prepare E-operators
    switch lower(motion_correction_type)
        case "non_rigid"
            E_operators = build_operator_non_rigid( ...
                data.k_spaces_corrected, ...
                data.binned_sampling_masks, ...
                data.interpolation_matrix, ...
                csm);
            target = "k_spaces_corrected"; % TODO(pdpino): could this be named k_spaces?
        case {"translational", "none"}
            E_operators = build_operator_rigid( ...
                data.k_spaces, ...
                data.sampling_masks, ...
                csm);
            target = "k_spaces";
        otherwise
            error("unknown motion correction type: %s", motion_correction_type);
    end

    % Run reconstruction
    switch lower(reconstruction_type)
        case "it_sense"
            images_raw = reconstruct_it_SENSE(data.(target), E_operators, it_sense_params);
        case "admm"
            images_raw = reconstruct_admm(data.(target), E_operators, admm_params, prost_params);
        otherwise
            error("unknown reconstruction method: %s", reconstruction_type);
    end

    % Flip to account for wrong-orientation
    images = cell(size(images_raw));
    for i_image = 1:numel(images_raw)
        images{i_image} = flip(flip(flip(images_raw{i_image},1),2),3);
    end
end
