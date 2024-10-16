function bin_images = reconstruct_orcca(k_spaces, sampling_masks, csm, bin_limits, motion_curve, params_moco)
%RECONSTRUCT_ORCCA Reconstruct bin images with ORCCA-XD
    n_bins = numel(k_spaces);
    [kx_size, ky_size, kz_size, n_coils] = size(k_spaces{1});
    k_size = [kx_size, ky_size, kz_size];

    % TODO(pdpino): optimize: try to use cell{n_bins} instead of array
    kdata = zeros([k_size, n_coils, n_bins]);
    At_bins = zeros([k_size, n_bins]);
    for i_bin = 1:n_bins
        kdata(:,:,:,:,i_bin) = k_spaces{i_bin};
        At_bins(:,:,:,i_bin) = sampling_masks{i_bin};
    end

    params_orcca = params_moco.orcca_params;

    % Prepare operator
    E_CSbins = Cruz_E_BINS_3D_CARTESIAN( ...
        At_bins, ...
        csm.coil_sensitivity_maps, ...
        n_bins, ...
        n_coils, ...
        k_size, ...
        k_size, ...
        params_orcca.n_threads);

    % Sparsity operators and respective weights
    if params_orcca.weight_scale > 0
        weight_scale = params_orcca.weight_scale*max(abs(kdata(:)));

        params_orcca.weight_L1 = params_orcca.weight_L1*weight_scale;
        params_orcca.weight_TV = params_orcca.weight_TV*weight_scale;
        params_orcca.weight_TV_Temp = params_orcca.weight_TV_Temp*weight_scale;
        params_orcca.weight_MTV = params_orcca.weight_MTV*weight_scale;
        params_orcca.weight_id = params_orcca.weight_id*weight_scale;
    end

    params_orcca.E = E_CSbins;
    params_orcca.W = TempFFT(3);
    params_orcca.TV = TVOP();
    params_orcca.TV_Temp = TV_Temp();
    %params_orcca.MTV = MTV(interpolationMatrices); % nonrigid correction
    params_orcca.MTV = TC_XMR_MTVi(motion_curve, bin_limits, params_moco.ref_bin(1));   % translational correction

    params_orcca.y = kdata;


    disp('************ XD-ORCCA reconstruction **************')
    images = CSL1NlCg_ORCCA(params_orcca);

    % Return as cell
    bin_images = cell(n_bins, 1);
    for i_bin = 1:n_bins
        bin_images{i_bin} = images(:,:,:,i_bin);
    end
end
