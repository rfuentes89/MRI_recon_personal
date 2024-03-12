function csm = get_csm(data, algorithm_name, selected)
%GET_CSM Wrapper to call csm calculation function

    k_space_for_csm = data.k_spaces{selected.echo,selected.set,selected.repetition};

    filter_dims = size(k_space_for_csm, 1:3);
    filter_std = 10;
    filtered_k_space = k_space_for_csm .* fspecial3('gaussian', filter_dims, filter_std);

    csm = estimate_coil_sensitivity_maps(filtered_k_space, algorithm_name);
end

