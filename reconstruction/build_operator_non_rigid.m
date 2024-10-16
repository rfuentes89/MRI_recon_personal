function E_operators = build_operator_non_rigid(binned_sampling_masks, interpolation_matrices, csm)
%BUILD_OPERATOR_NON_RIGID Create E_operators for non-rigid reconstruction
%
% Args:
%       - binned_sampling_masks: cell{n_contrasts}, cell{n_bins} each with (kx_size, ky_size, kz_size)
%       - interpolation_matrices: cell{n_contrasts}, cell {n_bins}
%       - csm: coil sensitivities
%
% Returns:
% cell with n_contrasts, each element with the E_operator for that contrast
    E_operators = cell(size(binned_sampling_masks));
    n_images = numel(binned_sampling_masks);
    for i_image = 1:n_images
        E_operators{i_image} = Cruz_E_3D_CART_BATCH(...
            interpolation_matrices{i_image}, ...
            binned_sampling_masks{i_image}, ...
            csm.coil_sensitivity_maps);
    end

end

