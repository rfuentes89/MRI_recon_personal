function bin_images = reconstruct_bin_images( ...
    k_spaces, sampling_masks, csm, bin_limits, motion_curve, params_moco)
% RECONSTRUCT_BIN_IMAGES Reconstruct one image per bin
%
% Arguments:
%     k_spaces shape: cell{n_bins}: n_kx, n_ky, n_kz, n_coils
%     sampling_masks shape: cell{n_bins}: n_kx, n_ky, n_kz
    if params_moco.filter_bin_kspace_gaussian > 0
        k_spaces = filter_k_spaces(k_spaces, params_moco.filter_bin_kspace_gaussian);
    end

    switch lower(params_moco.bin_recon_type)
        case "it_sense"
            bin_images = reconstruct_bin_images_it_sense( ...
                k_spaces, ...
                sampling_masks, ...
                csm, ...
                params_moco.it_sense_params);
        case "orcca"
            bin_images = reconstruct_bin_images_orcca( ...
                k_spaces, ...
                sampling_masks, ...
                csm, ...
                bin_limits, ...
                motion_curve, ...
                params_moco);
        case "admm"
            bin_images = reconstruct_bin_images_admm( ...
                k_spaces, ...
                sampling_masks, ...
                csm, ...
                params_moco.admm_params, ...
                params_moco.bin_prost_params);
        otherwise
            error("unknown bin reconstruction method: %s", params_moco.bin_recon_type);
    end
end

function filtered_k_spaces = filter_k_spaces(k_spaces, filter_std)
    filter_dims = size(k_spaces{1}, 1:3);
    filter = fspecial3('gaussian', filter_dims, filter_std);
    filtered_k_spaces = cellfun(@(kspace) kspace .* filter, k_spaces, "UniformOutput", false);
end

function bin_images = reconstruct_bin_images_admm(k_spaces, sampling_masks, csm, params_admm, params_PROST)
    % Prepare E_operators
    E_operators = build_operator_rigid(sampling_masks, csm);

    % Reconstruct
    bin_images = reconstruct_admm(k_spaces, E_operators, params_admm, params_PROST);
end

function bin_images = reconstruct_bin_images_it_sense(k_spaces, sampling_masks, csm, it_sense_params)
    % Prepare E_operators
    E_operators = build_operator_rigid(sampling_masks, csm);

    % Reconstruct
    bin_images = reconstruct_it_SENSE(k_spaces, E_operators, it_sense_params);
end
