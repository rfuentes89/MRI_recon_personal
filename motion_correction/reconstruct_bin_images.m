function bin_images = reconstruct_bin_images( ...
    k_spaces, sampling_masks, csm, bin_limits, motion_curve, params_moco)
% RECONSTRUCT_BIN_IMAGES Reconstruct one image per bin
%
% Arguments:
%     k_spaces shape: cell{n_bins}: n_kx, n_ky, n_kz, n_coils
%     sampling_masks shape: cell{n_bins}: n_kx, n_ky, n_kz

    switch lower(params_moco.bin_recon_mode)
        case "it_sense"
            bin_images = reconstruct_bin_images_it_sense(k_spaces, sampling_masks, csm);
        case "orcca"
            bin_images = reconstruct_bin_images_orcca( ...
                k_spaces, ...
                sampling_masks, ...
                csm, ...
                bin_limits, ...
                motion_curve, ...
                params_moco);
        otherwise
            error("unknown bin reconstruction method: " + string(params_moco.bin_recon_mode))
    end
end

function bin_images = reconstruct_bin_images_it_sense(k_spaces, sampling_masks, csm)
    n_bins = numel(k_spaces);

    filter_dims = size(k_spaces{1}, 1:3);
    filter_std = 40;

    filter = fspecial3('gaussian', filter_dims, filter_std);

    bin_images = cell(size(k_spaces));
    for bin = 1:n_bins

        filtered_k_space = k_spaces{bin} .* filter;

        bin_image = it_SENSE(filtered_k_space, sampling_masks{bin}, csm);
        bin_images{bin} = Normalize(abs(bin_image), 0, 1);

    end
end

function bin_images = reconstruct_bin_images_orcca( ...
    k_spaces, sampling_masks, csm, bin_limits, motion_curve, params_moco)

    % TODO(pdpino): clean ORCCA parameters (pass as arg, better names)

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

    % TODO(pdpino): pass this as arg?
    % Compute mean per bin
    target_pos_mean = cell(n_bins, 1);
    for i_bin = 1:n_bins
        curr_shots = motion_curve.Tx >= bin_limits{i_bin}.lower & motion_curve.Tx < bin_limits{i_bin}.upper;

	    target_pos_mean{i_bin}.X = mean(motion_curve.Tx(curr_shots));
	    target_pos_mean{i_bin}.Y = mean(motion_curve.Ty(curr_shots));
    end


    % Prepare operator
    E_CSbins = Cruz_E_BINS_3D_CARTESIAN( ...
        At_bins, ...
        csm.coil_sensitivity_maps, ...
        n_bins, ...
        n_coils, ...
        k_size, ...
        k_size, ...
        csm.coil_sensitivity_sum);
    
    lambda_base = (1*10^-5)*max(abs(kdata(:))); 
    
    %Sparsity operators and respective weights
    param.E                 = E_CSbins;
    param.W                 = TempFFT(3);
    param.L1Weight          = 0.00; 
    
    param.TV                = TVOP();
    lambdas                 = 1;
    param.TVWeight          = lambdas*lambda_base; % Here use 1
        
    param.TV_Temp           = TV_Temp(); 
    param.TV_TempWeight     = 0;
    
    %param.MTV               = MTV(interpolationMatrices); % nonrigid correction
    param.MTV               = TC_XMR_MTVi(target_pos_mean, params_moco.ref_bin);   % translational correction
    lambdat                 = 150;
    param.MTVWeight         = lambdat*lambda_base;
    
    param.nite              = 1;
    param.display           = 1;
    param.lsiter_max        = 1;
    param.IdWeight          = 0;
    param.y = kdata;


    disp('************ XD-ORCCA reconstruction **************')
    recon_dft = param.E'*param.y;

    images = CSL1NlCg_ORCCA_gui(recon_dft, param);
    
    % Flip dimensions (image is returned upside down)
    images = images(end:-1:1,end:-1:1,end:-1:1,:);

    % Return as cell
    bin_images = cell(n_bins, 1);
    for i_bin = 1:n_bins
        bin_images{i_bin} = images(:,:,:,i_bin);
    end
end
