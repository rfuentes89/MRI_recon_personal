function images = reconstruct_images( ...
    data, csm, reconstruction_type, motion_correction_type, admm_params, prost_params, it_sense_params)

    % Prepare E-operators
    switch lower(motion_correction_type)
        case "non_rigid"
            E_operators = build_operator_non_rigid( ...
                data.binned_sampling_masks, ...
                data.interpolation_matrices, ...
                csm);
            target = "k_spaces_corrected"; % TODO(pdpino): could this be named k_spaces?
        case {"translational", "none"}
            E_operators = build_operator_rigid( ...
                data.sampling_masks, ...
                csm);
            target = "k_spaces";
        otherwise
            error("unknown motion correction type: %s", motion_correction_type);
    end

    % Run reconstruction
    switch lower(reconstruction_type)
        case "it_sense"
            images = reconstruct_it_SENSE(data.(target), E_operators, it_sense_params);
        case "admm"
            images = reconstruct_admm(data.(target), E_operators, admm_params, prost_params);
        otherwise
            error("unknown reconstruction method: %s", reconstruction_type);
    end
end
