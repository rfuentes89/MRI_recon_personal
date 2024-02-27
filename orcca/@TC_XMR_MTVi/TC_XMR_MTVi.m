function  res = TC_XMR_MTVi(target_pos, ref_bin)

% MTV measures temporal total variation on a set of motion corrected 3D
% volumes

res.adjoint = 0;
res.target_pos = target_pos;
res.ref_bin = ref_bin;
res = class(res,'TC_XMR_MTVi');

