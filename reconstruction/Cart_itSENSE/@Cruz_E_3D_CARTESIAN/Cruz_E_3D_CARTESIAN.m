function  res = Cruz_E_3D_CARTESIAN(At,csm)
% Operator used for translational MoCo or no MoCo
%
% Args:
%     - At: sampling masks: array of size (nx, ny, nz)
%     - csm: coil sensitivity map, cell with (n_coils, 1), each of size (nx, ny, nz)

res.adjoint = 0; % flag
res.At = At; % sampled points
res.coils = csm; % coils
res = class(res,'Cruz_E_3D_CARTESIAN');

end