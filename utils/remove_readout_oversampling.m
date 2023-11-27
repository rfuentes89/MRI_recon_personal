function raw_data_no_os = remove_readout_oversampling(raw_data)

    raw_data_no_os = raw_data;

    image_x_size  = raw_data.specified_image_dimensions(1);
    padded_x_size = raw_data.padded_dimensions(1);    

    if image_x_size ~= padded_x_size

        half_difference = (padded_x_size - image_x_size) / 2;

        oversampled_locations = [1:half_difference, (padded_x_size - half_difference + 1):padded_x_size];

        [n_echoes, n_sets, n_repetitions] = size(raw_data.k_spaces);

        for repetition = 1:n_repetitions
            for set = 1:n_sets
                for echo = 1:n_echoes               
                    
                    transformed_along_readout_direction = ktoi(raw_data.k_spaces{echo,set,repetition}, 1);            
                    transformed_along_readout_direction(oversampled_locations,:,:,:) = [];            
                    raw_data_no_os.k_spaces{echo,set,repetition} = itok(transformed_along_readout_direction, 1);
                    
                    raw_data_no_os.segment_masks{echo,set,repetition}(oversampled_locations,:,:,:) = [];
                    raw_data_no_os.sampling_masks{echo,set,repetition}(oversampled_locations,:,:) = [];

                end
            end
        end

        % Correct stored dimensions accordingly
        raw_data_no_os.padded_dimensions(1)  = image_x_size;

    end

end


