function  res = Cruz_E_3D_CART_BATCH(interpolation_matrices,At,csm,siz,Ksiz)
% Operator used for non-rigid MoCo
% reconstructs considering binned data and displacement fields (MF)

res.adjoint = 0; % flag
res.interpolation_matrices = interpolation_matrices;
res.At = At; % sampled points [Nx,Ny,Nz,Nm] logical matrix
res.coils = csm; % coils [Nx,Ny,Nz,Nc]
res.siz = siz; % size in image space
res.Ksiz = Ksiz; % size in k-space
res = class(res,'Cruz_E_3D_CART_BATCH');

% Validate input
assert(iscell(interpolation_matrices));
n_bins = size(At, 4);
n_matrices = numel(interpolation_matrices);
assert(n_matrices == n_bins, ...
    "interp_matrix should have nbins=%d elements, got %d", n_bins, n_matrices);

end