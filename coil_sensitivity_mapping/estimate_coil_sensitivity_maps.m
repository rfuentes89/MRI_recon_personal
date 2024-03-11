function csm = estimate_coil_sensitivity_maps(data, algorithm_name, selected)

    k_space_for_csm = data.k_spaces{selected.echo,selected.set,selected.repetition};

    filter_dims = size(k_space_for_csm, 1:3);
    filter_std = 10;
    filtered_k_space = k_space_for_csm .* fspecial3('gaussian', filter_dims, filter_std);

    switch algorithm_name
        case "SOS"
            coil_sensitivity_maps = coil_sensitivity_SOS(filtered_k_space);
        case "ESPIRiT"
            coil_sensitivity_maps = coil_sensitivity_ESPIRiT(filtered_k_space);
        case "WALSH"
            coil_sensitivity_maps = coil_sensitivity_WALSH(filtered_k_space);
        case "scanner"
            error("coil maps from the scanner are not implemented yet")
        otherwise
            error("please select a supported csm algorithm")

    end

    root_sum_of_squares = sqrt(sum(abs(coil_sensitivity_maps) .^ 2, 4));

    csm.coil_sensitivity_maps = coil_sensitivity_maps./root_sum_of_squares;
    csm.coil_sensitivity_maps_raw = coil_sensitivity_maps;

end

