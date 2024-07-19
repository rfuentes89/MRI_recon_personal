function images = reconstruction_admm(data, csm, admm_params, prost_params)
    assert(isfield(data, "k_spaces_corrected"), "ADMM requires k_spaces_corrected");
    assert(isfield(data, "binned_sampling_masks"), "ADMM requires binned_sampling_masks");
    assert(isfield(data, "interpolation_matrix"), "ADMM requires interpolation_matrix");

    [n_echoes, n_sets, n_repetitions] = size(data.k_spaces_corrected);
    E_CSbins = cell([n_echoes, n_sets, n_repetitions]);
    for repetition = 1:n_repetitions
        for set = 1:n_sets
            for echo = 1:n_echoes
                E_CSbins{echo,set,repetition} = Cruz_E_3D_CART_BATCH(...
                    data.interpolation_matrix{echo,set,repetition}, ...
                    data.binned_sampling_masks{echo,set,repetition}, ...
                    csm.coil_sensitivity_maps, ...
                    size(data.k_spaces_corrected{echo,set,repetition},4), ...
                    size(data.k_spaces_corrected{echo,set,repetition},1:3), ...
                    size(data.k_spaces_corrected{echo,set,repetition}));
            end
        end
    end

    images_raw = HDPROST_NON_RIGID(data.k_spaces_corrected, E_CSbins, admm_params, prost_params);

    % Flip to account for wrong-orientation
    images = cell(n_echoes, n_sets, n_repetitions);
    for repetition = 1:n_repetitions
        for set = 1:n_sets
            for echo = 1:n_echoes
                images{echo,set,repetition} = flip(flip(flip(images_raw{echo, set, repetition},1),2),3);
            end
        end
    end
end

