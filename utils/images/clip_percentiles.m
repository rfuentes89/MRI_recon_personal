function image_out = clip_percentiles(image, min_perc, max_perc)
%CLIP_PERCENTILES Clip image outside of given percentiles
% Args:
%    image: array of any shape
%    min_perc: min percentile (everything below will be clipped)
%    max_perc: max percentile (everything above will be clipped)
%
% Returned image is in range [0,1], same type as input array
    min_out = prctile(image(:), min_perc);
    max_out = prctile(image(:), max_perc);

    value_range = max_out - min_out;

    image_out = image;
    image_out(image_out < min_out) = min_out;
    image_out(image_out > max_out) = max_out;
    image_out = ((image_out - min_out) / value_range);
end
