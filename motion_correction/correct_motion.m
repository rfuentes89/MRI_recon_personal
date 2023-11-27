function data = correct_motion(data, motion_curves, csm, motion_correction_type)

    switch motion_correction_type
        case "translational"
            data = motion_correction_translational(data, motion_curves);
        case "non_rigid"
            data = motion_correction_non_rigid(data, motion_curves, csm);
        otherwise
            error("please select a supported reconstruction type")
    end
end

