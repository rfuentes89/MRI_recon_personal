function image_out = apply_window_level(image, window, level)
%APPLY_WINDOW_LEVEL Apply window and level LUT to image
    min_im = level - window / 2;
    max_im = level + window / 2;

    max_value = max(image(:));

    image_out = uint16(max_value * (image - min_im) / (max_im - min_im));
end