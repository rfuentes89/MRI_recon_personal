function  images = reconstruction_non_rigid_it_SENSE(data, csm)

    images = cell(size(data.k_spaces_corrected));

    [n_echoes, n_sets, n_repetitions] = size(data.k_spaces_corrected);

    for repetition = 1:n_repetitions
        for set = 1:n_sets
            for echo = 1:n_echoes
                % Change the displacement_field, just for test
                images{echo,set,repetition} = non_rigid_it_SENSE( ...
                    data.k_spaces_corrected{echo,set,repetition}, ...
                    data.binned_sampling_masks{echo,set,repetition}, ...
                    data.interpolation_matrix{echo,set,repetition}, ...
                    csm ...
                );
            end
        end
    end
end