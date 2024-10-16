function  res = Cruz_E_3D_CART_BATCH(interpolation_matrices,binned_sampling_masks,csm)
% Operator used for non-rigid MoCo
% reconstructs considering binned data and displacement fields (MF)
%
% Args:
%     - interpolation_matrices
%     - binned_sampling_masks: cell with (n_bins, 1), each with an
%       array of size (nx, ny, nz)
%     - csm: coil sensitivity map, cell with (n_coils, 1), each of size (nx, ny, nz)

res.adjoint = 0; % flag

res.interpolation_matrices = interpolation_matrices;
res.At = binned_sampling_masks;
res.coils = csm;

res = class(res,'Cruz_E_3D_CART_BATCH');

% Validate input
assert(iscell(interpolation_matrices));
n_bins = numel(binned_sampling_masks);
n_matrices = numel(interpolation_matrices);
assert(n_matrices == n_bins, ...
    "interp_matrix should have nbins=%d elements, got %d", n_bins, n_matrices);

end