function images = reconstruct_images( ...
    data, coil_sensitivity_maps, reconstruction_type, motion_correction_type, admm_params, prost_params)

    switch lower(reconstruction_type)
        case "it_sense"
            if motion_correction_type == "non_rigid"
                images = reconstruction_non_rigid_it_SENSE(data, coil_sensitivity_maps);
            else
                images = reconstruction_it_SENSE(data, coil_sensitivity_maps);
            end
        case "admm"
            assert(motion_correction_type == "non_rigid", ...
                "ADMM only supported for non-rigid motion correction");
            images = reconstruction_admm(data, coil_sensitivity_maps, admm_params, prost_params);
        otherwise
            error("unknown reconstruction method: %s", reconstruction_type);
    end
end
