function  res = Cruz_E_3D_CART_BATCH(MF,At,csm,ncoils,siz,Ksiz,coil_rss)

res.adjoint = 0; % flag
res.MF = MF; % motion field [Nx,Ny,Nz,3,Nm] matrix or a cell of size {Nm}
res.At = At; % sampled points [Nx,Ny,Nz,Nm] logical matrix
res.coils = csm; % coils [Nx,Ny,Nz,Nc]
res.ncoils = ncoils; % size(coils) ADDED FROM CAMILA's CODE
res.siz = siz; % size in image space
res.Ksiz = Ksiz; % size in k-space
res.coil_rss = coil_rss; % intensity correction (rss of the coils)
res = class(res,'Cruz_E_3D_CART_BATCH');

