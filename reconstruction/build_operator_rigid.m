function E_operators = build_operator_rigid(sampling_masks, csm)
%BUILD_OPERATOR_RIGID Create E_operator for rigid reconstruction
% i.e. for motion_correction translational or none
%
% Args:
%       - sampling_masks: cell{n_contrasts}, array(kx_size, ky_size, kz_size)
%       - csm: coil sensitivities
%
% Returns:
% cell with n_contrasts, each element with the E_operator for that contrast

    E_operators = cell(size(sampling_masks));
    n_images = numel(sampling_masks);
    for i_image = 1:n_images
        E_operators{i_image} = Cruz_E_3D_CARTESIAN( ...
            sampling_masks{i_image}, ...
            csm.coil_sensitivity_maps);
    end
end

