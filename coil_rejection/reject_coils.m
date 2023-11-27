function data = reject_coils(data, coils_to_reject)
    
    [n_echoes, n_sets, n_repetitions] = size(data.k_spaces);

        for repetition = 1:n_repetitions
            for set = 1:n_sets
                for echo = 1:n_echoes
                    data.k_spaces{echo,set,repetition}(:,:,:,coils_to_reject) = [];
                end
            end
        end

end