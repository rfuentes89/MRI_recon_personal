function water_fat_maps = separate_water_fat(images, twix, water_fat_algorithm, CREAM_PDFF_path)

    [n_echoes, n_sets, n_repetitions] = size(images);

    % params as expected by toolbox
    % TODO: can we get these from the twix?
    %       otherwise should be parameters
    image_data.FieldStrength            = twix{end}.hdr.Dicom.flMagneticFieldStrength; % T
    image_data.PrecessionIsClockwise    = false; % TODO: something about this
    image_data.voxelSize                = [1, 1, 1]; % TODO: check what units this uses
    image_data.TE                       = cell2mat(twix{end}.hdr.MeasYaps.alTE(1:n_echoes)) * 1e-6; % s

    water_fat_maps = cell(n_sets, n_repetitions);

    for repetition = 1:n_repetitions
        for set = 1:n_sets
                
            % ISMRM toolbox format
            image_data.images = nan([size(images{1}), 1, n_echoes]);

            for echo = 1:n_echoes
                image_data.images(:,:,:,1,echo) = images{echo,set,repetition};
            end
            
            switch water_fat_algorithm
                case "B0_NICE_V1"
                    output_params = water_fat_B0_NICE_V1(image_data);
                case "B0_NICE_V2"
                    output_params = water_fat_B0_NICE_V2(image_data, CREAM_PDFF_path);
                otherwise
                    error("please select a supported water-fat separation algorithm")
            end

            water_fat_maps{set,repetition}.water        = output_params.W;
            water_fat_maps{set,repetition}.fat          = output_params.F;
            water_fat_maps{set,repetition}.fat_fraction = output_params.FF;

        end
    end

end

