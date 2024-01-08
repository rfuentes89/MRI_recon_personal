function images = reconstruct_images(data, coil_sensitivity_maps, reconstruction_type, params_CG, params_PROST)

    switch lower(reconstruction_type)
        case "it_sense"
            if isfield(data, 'interpolation_matrix') || isfield(data, 'displacement_fields')
                images = reconstruction_non_rigid_it_SENSE(data, coil_sensitivity_maps);
            else
                images = reconstruction_it_SENSE(data, coil_sensitivity_maps);
            end
        case "admm"
            images = reconstruction_admm(data, coil_sensitivity_maps, params_CG, params_PROST);
        otherwise
            error("please select a supported reconstruction method")
    end

end