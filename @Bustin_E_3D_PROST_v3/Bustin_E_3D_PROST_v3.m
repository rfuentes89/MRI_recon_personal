function  res = Bustin_E_3D_PROST_v3(sig, patch_sz, max_patch, win, offset, debug, recon_mode, sharpness, type)

res.adjoint     = 0;          % flag
res.sig         = sig;        % regularization
res.patch_sz    = patch_sz;   % size of patches
res.max_patch   = max_patch;  % maximum nb of patches to select
res.win         = win;        % search window for patch selection
res.offset      = offset;     % patch offset (to accelerate)
res.debug       = debug;      % display infos
res.recon_mode  = recon_mode; % recon_mode
res.sharpness   = sharpness;  % sharpness
res.type        = type;       % sharpness

res = class(res,'Bustin_E_3D_PROST_v3');

end