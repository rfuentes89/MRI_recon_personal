function denoised_images = denoise(images, denoising_type)

    [n_echoes, n_sets, n_repetitions] = size(images);
    denoised_images.deno_images= cell(size(images));
    switch denoising_type
        case "PROST"
            denoised_images = denoising_PROST(images);
        case "HD_PROST"
            for repetition = 1:n_repetitions
                for set = 1:n_sets
                    for echo = 1:n_echoes
                        % Set has to be considerated independently
                        image_cell = cell(1,1,1);
                        image_cell{1,1,1} = images{echo,set,repetition};
                        denoised_images.deno_images{echo,set,repetition} = denoising_HD_PROST(image_cell);
                    end
                end
            end
        otherwise
            error("please select a supported denoising method")
    end

end

