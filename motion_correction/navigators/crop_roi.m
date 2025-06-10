function cropped_navigators = crop_roi(navigators, navigator_roi, padding)
%CROP_ROI Crop a ROI from navigators
    if nargin < 3
        padding.fh = 0;
        padding.rl = 0;
    end
    fh_min = round(navigator_roi.fh_min - padding.fh);
    fh_max = round(navigator_roi.fh_max + padding.fh);
    rl_min = round(navigator_roi.rl_min - padding.rl);
    rl_max = round(navigator_roi.rl_max + padding.rl);

    cropped_navigators = cellfun( ...
        @(nav) crop_and_norm(nav, fh_min, fh_max, rl_min, rl_max), navigators, ...
        "UniformOutput", false);
end

function navigator = crop_and_norm(navigator, fh_min, fh_max, rl_min, rl_max)
    cropped_navigator = navigator(fh_min:fh_max, rl_min:rl_max);
    navigator = mat2gray(abs(cropped_navigator));
end
