function motion_curves = compute_scanner_motion_curve(twix, selected_contrasts, params)
% Compute motion curve using ROI from the scanner
    navigators = read_navigators(twix, selected_contrasts);
    scanner_roi = get_inav_roi_from_scanner(twix, size(navigators{1}), params);
    cropped_navigators = crop_roi(navigators, scanner_roi);
    motion_curves = register_navigators(cropped_navigators);
end
