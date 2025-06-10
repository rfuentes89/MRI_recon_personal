function roi = get_inav_roi_from_scanner(twix, image_size, params)
% Extract inav ROI from the twix
%
% Use params.length_factor to multiply both height and width.
% In some cases the ROI is too large, 0.5 might be a good value
    if nargin < 3
        params.length_factor = 1;
    end
    cuboid = twix.hdr.MeasYaps.sNavigatorArray.asElm{1}.sCuboid;
    pos = cuboid.sPosition;

    % Get resolution
    fh_resolution = twix.hdr.Config.ReadFoV  / twix.hdr.Config.RawCol;
    rl_resolution = twix.hdr.Config.PhaseFoV / twix.hdr.Config.RawLin;

    % Frame of reference has origin (0, 0) in the center of the image/inav
    n_fh = image_size(1);
    n_rl = image_size(2);
    fh_zero = n_fh / 2;
    rl_zero = n_rl / 2;

    % "sPosition" struct has center of BB
    fh_center = fh_zero - pos.dTra / fh_resolution; % top is positive, bottom is negative
    rl_center = rl_zero + pos.dSag / rl_resolution; % right is positive, left is negative

    % "cuboid" struct has height and width of BB
    fh_length = cuboid.dReadoutFOV / fh_resolution * params.length_factor;
    rl_length = cuboid.dPhaseFOV / rl_resolution * params.length_factor;

    % Return corners
    roi.fh_min = fh_center - fh_length / 2;
    roi.fh_max = fh_center + fh_length / 2;
    roi.rl_min = rl_center - rl_length / 2;
    roi.rl_max = rl_center + rl_length / 2;
end
