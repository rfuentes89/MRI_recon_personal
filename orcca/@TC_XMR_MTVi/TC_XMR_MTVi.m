function  res = TC_XMR_MTVi(target_pos)

% MTV measures temporal total variation on a set of motion corrected 3D
% volumes

res.adjoint = 0;
res.target_pos = target_pos;
res = class(res,'TC_XMR_MTVi');

