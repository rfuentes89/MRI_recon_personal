function bin_images = reconstruct_bin_images( ...
    k_spaces, sampling_masks, csm, bin_limits, motion_curve, params_moco)
% RECONSTRUCT_BIN_IMAGES Reconstruct one image per bin
%
% Arguments:
%     k_spaces shape: cell{n_bins}: n_kx, n_ky, n_kz, n_coils
%     sampling_masks shape: cell{n_bins}: n_kx, n_ky, n_kz

    switch lower(params_moco.bin_recon_type)
        case "it_sense"
            bin_images_raw = reconstruct_bin_images_it_sense(k_spaces, sampling_masks, csm);
        case "orcca"
            bin_images_raw = reconstruct_bin_images_orcca( ...
                k_spaces, ...
                sampling_masks, ...
                csm, ...
                bin_limits, ...
                motion_curve, ...
                params_moco);
        case "admm"
            bin_images_raw = reconstruct_bin_images_admm( ...
                k_spaces, ...
                sampling_masks, ...
                csm, ...
                params_moco.admm_params, ...
                params_moco.bin_prost_params);
        otherwise
            error("unknown bin reconstruction method: %s", params_moco.bin_recon_type);
    end

    % Flip to the correct orientation
    n_bins = numel(k_spaces);
    bin_images = cell(n_bins, 1);
    for i_bin = 1:n_bins
        bin_images{i_bin} = flip(flip(flip(bin_images_raw{i_bin}, 1), 2), 3);
    end
end

function bin_images = reconstruct_bin_images_admm(k_spaces, sampling_masks, csm, params_admm, params_PROST)
    % Prepare E_operators
    E_operators = build_operator_rigid(k_spaces, sampling_masks, csm);

    % Reconstruct
    bin_images = reconstruct_admm(k_spaces, E_operators, params_admm, params_PROST);
end

function bin_images = reconstruct_bin_images_it_sense(k_spaces, sampling_masks, csm)
    % Apply filter to kspace
    filter_dims = size(k_spaces{1}, 1:3);
    filter_std = 40;
    filter = fspecial3('gaussian', filter_dims, filter_std);
    filtered_k_space = cellfun(@(kspace) kspace .* filter, k_spaces, "UniformOutput", false);

    % Prepare E_operators
    E_operators = build_operator_rigid(k_spaces, sampling_masks, csm);

    % Reconstruct
    n_iter = 3;
    verbose = false;
    bin_images = reconstruct_it_SENSE(filtered_k_space, E_operators, n_iter, verbose);
end

function bin_images = reconstruct_bin_images_orcca( ...
    k_spaces, sampling_masks, csm, bin_limits, motion_curve, params_moco)

    n_bins = numel(k_spaces);
    [kx_size, ky_size, kz_size, n_coils] = size(k_spaces{1});
    k_size = [kx_size, ky_size, kz_size];

    % TODO(pdpino): standardize n_bins dimensions
    kdata = zeros([k_size, n_coils, n_bins]);
    At_bins = zeros([k_size, n_bins]);
    for i_bin = 1:n_bins
        kdata(:,:,:,:,i_bin) = k_spaces{i_bin};
        At_bins(:,:,:,i_bin) = sampling_masks{i_bin};
    end

    % Compute mean per bin
    target_pos_mean = cell(n_bins, 1);
    for i_bin = 1:n_bins
        curr_shots = motion_curve.Tx >= bin_limits{i_bin}.lower & motion_curve.Tx < bin_limits{i_bin}.upper;

	    target_pos_mean{i_bin}.X = mean(motion_curve.Tx(curr_shots));
	    target_pos_mean{i_bin}.Y = mean(motion_curve.Ty(curr_shots));
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
    params_orcca.MTV = TC_XMR_MTVi(target_pos_mean, params_moco.ref_bin(1));   % translational correction

    params_orcca.y = kdata;


    disp('************ XD-ORCCA reconstruction **************')
    images = CSL1NlCg_ORCCA(params_orcca);

    % Return as cell
    bin_images = cell(n_bins, 1);
    for i_bin = 1:n_bins
        bin_images{i_bin} = images(:,:,:,i_bin);
    end
end
