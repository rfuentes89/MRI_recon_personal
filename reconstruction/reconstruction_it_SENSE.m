function images = reconstruction_it_SENSE(data, csm)

    images = cell(size(data.k_spaces));

    [n_echoes, n_sets, n_repetitions] = size(data.k_spaces);

    for repetition = 1:n_repetitions
        for set = 1:n_sets
            for echo = 1:n_echoes

                images{echo,set,repetition} = it_SENSE( ...
                    data.k_spaces{echo,set,repetition}, ...
                    data.sampling_masks{echo,set,repetition}, ...
                    csm ...
                );

             end
        end
    end

end

