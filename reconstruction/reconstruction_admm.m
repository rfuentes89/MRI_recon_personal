function images = reconstruction_admm(data, csm, params_CG, params_PROST)
    assert(isfield(data, "k_spaces_corrected"), "ADMM requires k_spaces_corrected");
    assert(isfield(data, "binned_sampling_masks"), "ADMM requires binned_sampling_masks");
    assert(isfield(data, "interpolation_matrix"), "ADMM requires interpolation_matrix");

    if ~exist('params_PROST', 'var')
        params_PROST.sig         =  0.055;
        params_PROST.patch_sz    =  5;
        params_PROST.max_patch   =  20;
        params_PROST.win         =  20;
        params_PROST.offset      =  4;
        params_PROST.debug       =  1;
        params_PROST.recon_mode  =  6;
        params_PROST.sharpness   =  0;
        params_PROST.type        =  0;
    end

    if ~exist('params_CG', 'var')
        params_CG.ADMM_maxit    = 5;
        params_CG.CG_minres     = 1e-10;
        params_CG.CG_maxit_ini  = 5;
        params_CG.CG_maxit      = 5;
        params_CG.CG_lambda     = 0.01;
    end

    [n_echoes, n_sets, n_repetitions] = size(data.k_spaces_corrected);
    params_CG.E_CSbins = cell(size(data.sampling_masks));

    for repetition = 1:n_repetitions
        for set = 1:n_sets
            for echo = 1:n_echoes
                params_CG.E_CSbins{echo,set,repetition} = Cruz_E_3D_CART_BATCH(...
                    data.interpolation_matrix{echo,set,repetition}, ...
                    data.binned_sampling_masks{echo,set,repetition}, ...
                    csm.coil_sensitivity_maps, ...
                    size(data.k_spaces_corrected{echo,set,repetition},4), ...
                    size(data.k_spaces_corrected{echo,set,repetition},1:3), ...
                    size(data.k_spaces_corrected{echo,set,repetition}));
            end
        end
    end

    Params_acqui.kdata_OUT = data.k_spaces_corrected;

    %
    disp('************ MC reconstruction with 3D HD-PROST **************');
    tic();
    [x, Rx_it, y_it, x_it] = HDPROST_NON_RIGID(Params_acqui, params_CG, params_PROST);
    toc();


    %
    images = cell(n_echoes, n_sets, n_repetitions);
    for repetition = 1:n_repetitions
        for set = 1:n_sets
            for echo = 1:n_echoes
                images{echo,set,repetition} = flip(flip(flip(x(:,:,:,set),1),2),3);
            end
        end
    end
    disp("******** NON RIGID HD-PROST Reconstruction DONE ********")

end

