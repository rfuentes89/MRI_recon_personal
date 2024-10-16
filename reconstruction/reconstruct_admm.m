function [x, Rx_history, y_history, x_history] = reconstruct_admm(kdata, E_operator, admm_params, prost_params)
% RECONSTRUCT_ADMM Run ADMM optimization with HD-PROST
%  Inputs:
%        kdata: cell of arbitrary size n_images (e.g. number of contrasts,
%               or number of bins), each with an array of size
%               (n_kx, n_ky, n_kz, *), compatible with its E_operator
%        E_operator: cell of size n_images, each with motion compensated
%               operator
%        prost_params: parameters used in the second step (PROST optimization)
%        admm_params: parameters related to the first step (MR reconstruction)
%                  - max_iter: total number of ADMM iterations
%                  - cg_residual_tol: conjugate gradient tolerance (usually set to 1e-10)
%                  - cg_max_iter_first: maximum number of iterations at the first MR optimization
%                  - cg_max_iter: maximum number of iterations for the MR optimization (1)
%                  - cg_lambda: regularization parameters (weighting data fidelity and denoised prior: mu in the paper)
%
%
%  Outputs:
%        output : - x: the reconstructed motion-compensated image
%                 - Rx_history: the images obtained after optimization 2 (patch-based)
%                 - y_history: the lagragian images
%                 - x_history: the images obtained after optimization 1 (MR reconstruction)
%
%
%  Recommended parameters for a typical CMRA reconstruction (1.2mm3, acc x5):
%     optimization 2: sig = 0.04 / patch_sz = 5 / max_patch = 20 / win = 10 / offset = 4
%     optimization 1: ADMM_maxit = 6 / CG_minres = 1e-10 / CG_maxit_ini = 5 / CG_maxit = 5 / CG_lambda = 0.6
%
%  Contacts:
%  Aurelien Bustin (aurelien.bustin@kcl.ac.uk)
%  Claudia Prieto  (claudia.prieto@kcl.ac.uk)
%
% When using this code, please do cite our papers:
%  A. Bustin et al.,
%  Five-Minute Whole-Heart Coronary MRA with Sub-millimeter Isotropic Resolution,
%  100% Respiratory Scan Efficiency and 3D-PROST Reconstruction.
%  Magnetic Resonance in Medicine, 2019;81(1):102-115 doi: 10.1002/mrm.27354

% Default parameters for MR recon
admm_params = fill_struct_values(admm_params, struct( ...
    max_iter = 5,...
    cg_max_iter_first = 3, ...
    cg_max_iter = 3, ...
    cg_residual_tol = 1e-10, ...
    cg_lambda = 0.1, ...
    last_iter_skip_prost = false, ...
    verbose = 0));

% Default parameters for PROST recon
prost_params = fill_struct_values(prost_params, struct( ...
    sig = 0.055, ...
    patch_sz = 5, ...
    max_patch = 20, ...
    win = 20, ...
    offset = 4, ...
    debug = 0, ...
    recon_mode = 6, ...
    sharpness = 0, ...
    type = 0, ...
    ref_idx = 1));

n_images = numel(kdata); % e.g. n_contrasts or n_bins
x = cell(n_images, 1); % resulting images
y = cell(n_images, 1); % lagrangian images

if nargout > 1
    x_history = cell(admm_params.max_iter, 1); % images after step 1
    Rx_history = cell(admm_params.max_iter, 1); % images after step 2
    y_history = cell(admm_params.max_iter, 1);
end

for i_iter = 1:admm_params.max_iter
    if admm_params.verbose >= 1
        fprintf("\tADMM ite=%d/%d\n", i_iter, admm_params.max_iter);
    end

    % OPTIMIZATION 1: Data consistency (x): MR reconstruction
    for i_image = 1:n_images
        if i_iter == 1
            params.max_iter = admm_params.cg_max_iter_first;
            params.residual_tol = admm_params.cg_residual_tol;
            x{i_image} = Cart_itSENSE(kdata{i_image},E_operator{i_image}, params);
        else
            params.image_reg = Rx{i_image} - y{i_image};
            params.image_initial = x{i_image};
            params.lambda = admm_params.cg_lambda;
            params.max_iter = admm_params.cg_max_iter;
            params.residual_tol = admm_params.cg_residual_tol;
            x{i_image} = Cart_itSENSE(kdata{i_image},E_operator{i_image}, params);
        end
    end

    if admm_params.last_iter_skip_prost && i_iter == admm_params.max_iter
        break;
    end

    %  OPTIMIZATION 2: Tensor Decomposition (Rx - denoising)
    x = concat_cell_to_array(x);

    if i_iter == 1
        y = zeros(size(x));
    else
        y = concat_cell_to_array(y);
    end

    % Check for nans
    count_nan = sum(isnan(x(:)));
    if count_nan > 0
        warning("NaN found after ADMM-MR: ite=%i nans=%d\n", i_iter, count_nan);
        x(isnan(x)) = 0;
    end

    % Apply denoising
    added_images = double(x + y);
    Rx = denoising_HD_PROST(added_images, prost_params);

    % Check for NaNs
    count_nan = sum(isnan(Rx(:)));
    if count_nan > 0
        warning("NaN found after ADMM-denoising: ite=%i nans=%d\n", i_iter, count_nan);
        Rx(isnan(Rx)) = 0;
    end

    % STEP 3: Lagrangian Update (y)
    y = y + x - Rx;

    is_one_element_cell = n_images == 1;
    x = split_array_to_cell(x, is_one_element_cell);
    y = split_array_to_cell(y, is_one_element_cell);
    Rx = split_array_to_cell(Rx, is_one_element_cell);

    % Save history
    if nargout > 1
        x_history{i_iter} = x;
        Rx_history{i_iter} = Rx;
        y_history{i_iter} = y;
    end
end

end
