function arr = clip_values(arr, lower, upper)
%CLIP_VALUES Clips an array to range [lower, upper]
%
% Notice there is a native function for this, but only since version R2024a
% https://www.mathworks.com/help/matlab/ref/clip.html
% We can delete this in the future, but for now we keep it to support 22/23
    arr(arr < lower) = lower;
    arr(arr > upper) = upper;
end

