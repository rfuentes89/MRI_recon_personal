function denoised_images = denosing_HD_PROST_MULTICONTRAST(images)

    input_type          = 6; % 3D, multi contrast, complex

    thresholding_type   = 0; % "fixed" threshold for singular values
    threshold           = 0.05;
    
    patch_size          = 5;
    max_n_patches       = 20;
    window_size         = 20;
    window_stride       = 4;

    sharpening_strength = 0; % no sharpening filter applied

    debug               = true; % no console output

    assert(patch_size > window_stride) % otherwise patches do not overlap    

    input = nan([size(images{1}), numel(images)]);
    for image = 1:numel(images)
        input(:,:,:,image) = double(images{image});
    end
    
    input(input == 0) = 1e-12; % fixes NaN values in regions with zero-filled patches.

    scaling = max(abs(input), [], "all");

    input_real = real(input) ./ scaling;
    input_imag = imag(input) ./ scaling;

    reference_image = abs(input(:,:,:,1)); % TODO: expose this as a parameter
                
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

    output = scaling .* (output_real + 1i * output_imag);

    denoised_images = cell(size(images));
    for image = 1:numel(images)
        denoised_images{image} = output(:,:,:,image);
    end

end
