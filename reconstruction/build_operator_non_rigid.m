function E_operators = build_operator_non_rigid(k_spaces_corrected, binned_sampling_masks, interpolation_matrices, csm)
%BUILD_OPERATOR_NON_RIGID Create E_operators for non-rigid reconstruction
%
% Args:
%       - k_spaces_corrected: cell with n_contrasts, each with size (kx_size, ky_size, kz_size, n_coils, n_bins)
%       - binned_sampling_masks: cell with n_contrasts, each with (kx_size, ky_size, kz_size, n_bins)
%       - interpolation_matrices: cell with n_contrasts, each a cell with n_bins
%       - csm: coil sensitivities
%
% Returns:
% cell with n_contrasts, each element with the E_operator for that contrast

    E_operators = cell(size(k_spaces_corrected));
    n_images = numel(k_spaces_corrected);
    for i_image = 1:n_images
        k_space = k_spaces_corrected{i_image};

        E_operators{i_image} = Cruz_E_3D_CART_BATCH(...
            interpolation_matrices{i_image}, ...
            binned_sampling_masks{i_image}, ...
            csm.coil_sensitivity_maps, ...
            size(k_space,1:3), ...
            size(k_space));
    end

end

