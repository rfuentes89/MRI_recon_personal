function images = reconstruct_images(data, coil_sensitivity_maps, reconstruction_type)

    switch reconstruction_type
        case "it_SENSE"
            %if isfield(data, "interpolation_matrix")
            if isfield(data, 'interpolation_matrix') || isfield(data, 'displacement_fields')
                images = reconstruction_non_rigid_it_SENSE(data, coil_sensitivity_maps);
            else
                images = reconstruction_it_SENSE(data, coil_sensitivity_maps);
            end
        otherwise
            error("please select a supported reconstruction method")
    end

end