function  res = Cruz_E_BINS_3D_CARTESIAN(At,csm,nbins,ncoils,siz,Ksiz,coil_rss)

res.adjoint = 0; % flag for forward and inverse operations
res.At = At; % logical sampling matrices
res.csm = csm; % coil maps
res.nbins = nbins; % number of bins (i.e. dynamics in the 4th dimension)
res.ncoils = ncoils; % number of coils
res.siz = siz; % size in image space
res.Ksiz = Ksiz; % size in kspace
res.coil_rss = coil_rss; % coil normalization
res = class(res,'Cruz_E_BINS_3D_CARTESIAN');

