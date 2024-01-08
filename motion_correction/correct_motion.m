function data = correct_motion(data, motion_curves, csm, params)

    switch params.type
        case "translational"
            data = motion_correction_translational(data, motion_curves);
        case "non_rigid"
            data = motion_correction_non_rigid(data, motion_curves, csm, params.nr_ref_bin);
        otherwise
            error("please select a supported reconstruction type")
    end
end

