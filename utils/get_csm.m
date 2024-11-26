function csm = get_csm(data, algorithm_name, selected,params)
%GET_CSM Wrapper to call csm calculation function

    k_space_for_csm = data.k_spaces{selected.echo,selected.set,selected.repetition};

    if algorithm_name == "scanner"
        % No need to filter kspace if loading CSMs from a file
        filtered_k_space = k_space_for_csm;
    else
        filter_dims = size(k_space_for_csm, 1:3);
        filter_std = 10;
        filtered_k_space = k_space_for_csm .* fspecial3('gaussian', filter_dims, filter_std);
    end

    csm = estimate_coil_sensitivity_maps(filtered_k_space, algorithm_name,params);
end

