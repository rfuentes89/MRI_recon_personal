%% Params for Reconstruction

% E_CSbins = Cruz_E_3D_CART_BATCH(interpolationMatrices, At_bins_hard, csm_total, nCoils, siz, size(kdata_OUT), coil_rss);

% Parameters: acquisition

Params_acqui.kdata_OUT = kdata_OUT;

% Parameters: Patch-based optimization (2)

Params_PROST.sig         =  0.04;
Params_PROST.patch_sz    =  5;
Params_PROST.max_patch   =  20;
Params_PROST.win         =  10; % this parameter can be increased (time insensitive)
Params_PROST.offset      =  4;
Params_PROST.debug       =  1;
Params_PROST.recon_mode  =  4;% 3: 2D / 4: 3D

% Parameters: MR reconstruction optimization (1)

Params_MR.ADMM_maxit    = 6;
Params_MR.CG_minres     = 1e-10;
Params_MR.CG_maxit_ini  = 5;
Params_MR.CG_maxit      = 5;
Params_MR.CG_lambda     = 0.6;
Params_MR.E_CSbins      = E_CSbins;


disp('************ NMC reconstruction with 3D PROST **************');

[x, Rx_it, y_it, x_it] = PROST_NON_RIGID(Params_acqui, Params_MR, Params_PROST);

disp('************ ALL DONE! **************')

% Display

imagine(abs(x))


