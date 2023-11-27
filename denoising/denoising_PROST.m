function denoised_images = denoising_PROST(images)

    input_type          = 7; % 3D, single contrast, complex

    thresholding_type   = 0; % Rank fixed to sigma
    threshold           = 0.05;
    
    patch_size          = 5;
    max_n_patches       = 20;
    window_size         = 40;
    window_stride       = 3;

    sharpening_strength = 0; % no sharpening filter applied

    debug               = true; % no console output

    assert(patch_size > window_stride) % otherwise patches do not overlap
    
    denoised_images = cell(size(images));
    
    [n_echoes, n_sets, n_repetitions] = size(images);

    for repetition = 1:n_repetitions
        for set = 1:n_sets
            for echo = 1:n_echoes

                image = double(images{echo,set,repetition});
                image(image == 0) = 1e-12; % fixes NaN values in regions with zero-filled patches.

                scaling = max(abs(image), [], "all");

                input_real = real(image) ./ scaling;
                input_imag = imag(image) ./ scaling;

                reference_image = abs(image);
                
                [output_real, output_imag] = Bustin_denoising_patch_mex_v3( ...
                    input_real, input_imag, ...
                    threshold, ...
                    patch_size, ...
                    max_n_patches, ...
                    window_size, ...
                    window_stride, ...
                    debug, ...
                    input_type, ...
                    thresholding_type, ...
                    sharpening_strength, ...
                    reference_image ...
                );

                denoised_images{echo,set,repetition} = scaling .* (output_real + 1i * output_imag);

            end
        end
    end

end