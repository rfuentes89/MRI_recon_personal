function  res = Cruz_E_3D_CARTESIAN(At,csm,siz,Ksiz)
% Operator used for translational MoCo or no MoCo

res.adjoint = 0; % flag
res.At = At; % sampled points
res.coils = csm; % coils
res.siz  = siz; % size in image space
res.Ksiz = Ksiz; % size in k-space
res = class(res,'Cruz_E_3D_CARTESIAN');

end