function E_operators = build_operator_rigid(k_spaces, sampling_masks, csm)
%BUILD_OPERATOR_RIGID Create E_operator for rigid reconstruction
% i.e. for motion_correction translational or none
%
% Args:
%       - k_spaces: cell with n_contrasts, each with size (kx_size, ky_size, kz_size, n_coils)
%       - sampling_masks: cell with n_contrasts, each with size (kx_size, ky_size, kz_size)
%       - csm: coil sensitivities
%
% Returns:
% cell with n_contrasts, each element with the E_operator for that contrast

    E_operators = cell(size(k_spaces));
    n_images = numel(k_spaces);
    for i_image = 1:n_images
        k_space = k_spaces{i_image};

        E_operators{i_image} = Cruz_E_3D_CARTESIAN( ...
            sampling_masks{i_image}, ...
            csm.coil_sensitivity_maps, ...
            size(k_space, 1:3), ...
            size(k_space, 1:3) ...
        );
    end
end

