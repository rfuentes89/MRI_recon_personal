function image_out = apply_window_level(image, window, level)
%APPLY_WINDOW_LEVEL Apply window and level LUT to image
% Args:
%    image: array of any shape
%    window: number
%    level: number
%
% Returned image is in range [0,1], same type as input array
    min_out = level - window / 2;
    max_out = level + window / 2;
    image_out = clip_values(image, min_out, max_out);
    image_out = ((image_out - min_out) / window);
end
