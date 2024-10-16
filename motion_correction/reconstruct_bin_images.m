function bin_images = reconstruct_bin_images( ...
    k_spaces, sampling_masks, csm, bin_limits, motion_curve, params_moco)
% RECONSTRUCT_BIN_IMAGES Reconstruct one image per bin
%
% Arguments:
%     k_spaces shape: cell{n_bins}: n_kx, n_ky, n_kz, n_coils
%     sampling_masks shape: cell{n_bins}: n_kx, n_ky, n_kz

    switch lower(params_moco.bin_recon_type)
        case "it_sense"
            bin_images_raw = reconstruct_bin_images_it_sense(k_spaces, sampling_masks, csm, params_moco.it_sense_params);
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
    E_operators = build_operator_rigid(sampling_masks, csm);

    % Reconstruct
    bin_images = reconstruct_admm(k_spaces, E_operators, params_admm, params_PROST);
end

function bin_images = reconstruct_bin_images_it_sense(k_spaces, sampling_masks, csm, it_sense_params)
    % Apply filter to kspace
    filter_dims = size(k_spaces{1}, 1:3);
    filter_std = 40;
    filter = fspecial3('gaussian', filter_dims, filter_std);
    filtered_k_space = cellfun(@(kspace) kspace .* filter, k_spaces, "UniformOutput", false);

    % Prepare E_operators
    E_operators = build_operator_rigid(sampling_masks, csm);

    % Reconstruct
    bin_images = reconstruct_it_SENSE(filtered_k_space, E_operators, it_sense_params);
end
