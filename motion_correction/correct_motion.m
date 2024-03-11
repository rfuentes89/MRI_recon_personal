function data = correct_motion(data, motion_curves, csm, params)

    switch lower(params.type)
        case "translational"
            data = motion_correction_translational(data, motion_curves);
        case "non_rigid"
            data = motion_correction_non_rigid(data, motion_curves, csm, params);
        otherwise
            error("unknown reconstruction type: " + string(params.type))
    end
end

