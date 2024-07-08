function images = norm_image_brightness(images, target)
%NORM_IMAGE_BRIGHTNESS Normalize images brightness
%   Arguments:
%       images: cell with multiple greyscale images (of any size or shape)

    % Parse target
    if isnumeric(target)
        n_images = numel(images);
        assert(target >= 1 && target <= n_images, ...
            "target must be between 1 and n_images=%d", n_images);
        target_brightness = get_brightness(images{target});
    else
        all_brightness = cellfun(@get_brightness, images);
        switch string(target)
            case {"mean","avg"}
                get_target_brightness = @mean;
            case "median"
                get_target_brightness = @median;
            case "max"
                get_target_brightness = @max;
            case "min"
                get_target_brightness = @min;
            otherwise
                error("target not recognized: %s", target);
        end
        target_brightness = get_target_brightness(all_brightness);
    end

    % Convert images to target brightness
    for i_image = 1:numel(images)
        images{i_image} = images{i_image} / get_brightness(images{i_image}) * target_brightness;
    end
end

function brightness = get_brightness(image)
    flat_img = image(:);
    brightness = sum(flat_img) / numel(flat_img);
end
