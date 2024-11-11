function images = apply_image_corrections(images, params)
%APPLY_IMAGE_CORRECTIONS Applies multiple image corrections
    % Normalize to same brightness
    if params.norm_brightness_params.apply
        images = norm_image_brightness(images, params.norm_brightness_params.target);
    end
    
    % Apply LUT
    if params.lut_params.apply
        for i_image = 1:numel(images)
            images{i_image} = apply_window_level(images{i_image}, params.lut_params.window, params.lut_params.level);
        end
    end
    
    % Clip percentiles
    if params.percentile_params.apply
        perc_params = params.percentile_params;
        for i_image = 1:numel(images)
            images{i_image} = clip_percentiles(images{i_image}, perc_params.min_perc, perc_params.max_perc);
        end
    end
end

