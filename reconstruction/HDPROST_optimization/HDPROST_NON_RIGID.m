%  This C function implements the motion-compensated reconstruction using 3D patch-based regularization (3D-PROST)
%
%  Information:
%         gsl package is required for the SVD and HOSVD decompositions and is freely available here:
%         https://www.gnu.org/software/gsl/m
%
%  For installation on linux system please read the INSTALL file
%
%  Usage Example:
%         [x, Rx_it, y_it, x_it] = HDPROST_NON_RIGID(Params_acqui, Params_MR, Params_PROST)
%
%  Inputs:
%        Params_acqui : consists of the (undersampled) k-spaces (with multiple respiratory bins)
%        Params_PROST : consists of all the parameters related to the PROST optimization (2)
%                           - patch_zs:size of 3D patches (in pixels)
%                           - max_patch:maximum number of similar 3D patches to search
%                           - win:size of search window
%                           - offset:offset between patches (to accelerate the reconstruction)
%                                    no visual difference was seen between offset = 1 and offset = 4 (but x4 faster)
%                           - debug:display information on the optimization 2 (patch-based) when debug==1
%                           - recon_mode: for 3D reconstruction use 4
%        Params_MR : consists of all the parameters related to the MR reconstruction (1)
%                           - ADMM_maxit:total number of ADMM iterations
%                           - CG_minres: conjugate gradient tolerance (usually set to 1e-10)
%                           - CG_maxit_ini: maximum number of iterations at the first MR optimization
%                           - CG_maxit: maximum number of iterations for the MR optimization (1)
%                           - CG_lambda: regularization parameters (weighting data fidelity and denoised prior: mu in the paper)
%                           - E_CSbins: motion compensated operator
%
%
%  Outputs:
%        output : - x: the reconstructed motion-compensated image
%                 - Rx_it: the images obtained after optimization 2 (patch-based)
%                 - y_it: the lagragian images
%                 - x_it: the images obtained after optimization 1 (MR reconstruction)
%
%
%  Recommended parameters for a typical CMRA reconstruction (1.2mm3, acc x5):
%     optimization 2: sig = 0.04 / patch_sz = 5 / max_patch = 20 / win = 10 / offset = 4
%     optimization 1: ADMM_maxit = 6 / CG_minres = 1e-10 / CG_maxit_ini = 5 / CG_maxit = 5 / CG_lambda = 0.6
%
% Some comments on the parameters:
% The large number of parameters can be scary at first sight but allows
% more flexibility in the reconstruction. In general, only 3 parameters
% need attention:
% 1) patch size: this parameter needs to be tuned according to your resolution (range: [5-10])
% 2) sig: controls the amount of denoising to perform (important parameter)
% 3) CG_lambda: controls the weight to give to the denoised prior to the MR reconstruction (represented by mu in the paper)
% Parameter win: this parameter sets a windows limit for the search of the
% patches. The code has been developped such that the reconstruction time
% is quite insensitive to the size of search. Therefore we recommend win in
% the range [20-60].
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


function [x, Rx_it, y_it, x_it] = HDPROST_NON_RIGID(Params_acqui, Params_MR, Params_PROST)

% Parameters Acquisition

kdata_OUT = Params_acqui.kdata_OUT;

% Parameters for MR recon

ADMM_maxit    = Params_MR.ADMM_maxit;
CG_minres     = Params_MR.CG_minres;
CG_maxit_ini  = Params_MR.CG_maxit_ini;
CG_maxit      = Params_MR.CG_maxit;
CG_lambda     = Params_MR.CG_lambda;

% Parameters for PROST recon

sig         = Params_PROST.sig;
patch_sz    = Params_PROST.patch_sz;
max_patch   = Params_PROST.max_patch;
win         = Params_PROST.win;
offset      = Params_PROST.offset;
debug       = Params_PROST.debug;
recon_mode  = Params_PROST.recon_mode;
type        = Params_PROST.type;
sharpness   = Params_PROST.sharpness;

% Build E operators

E_MR       = Params_MR.E_CSbins;
nContrast  = size(kdata_OUT,2);

clear Params_MR Params_PROST Params_acqui

% other tested parameters:
% E_3D_PROST = Bustin_E_3D_PROST(sig, patch_sz, max_patch, win, offset, debug, recon_mode);
% E_3D_PROST = Bustin_E_3D_PROST(0.06, 5, 20, 10, 4, 1, 4);
% E_3D_PROST = Bustin_E_3D_PROST(0.1, 5, 20, 10, 4, 1, 4);
% E_3D_PROST = Bustin_E_3D_PROST(sig, 5, 20, 10, 4, 1, 4);

for ttt = 1:ADMM_maxit

    fprintf('<strong> Iteration: %d/%d </strong>\n', ttt, ADMM_maxit);

    %  OPTIMIZATION 1: Data consistency (x): MR reconstruction

    fprintf('<strong> Running MR reconstruction step </strong>\n');

    for ccc = 1:nContrast

        if ttt == 1 && ccc == 1

            tic();
            x_tmp        = solve_CG(kdata_OUT{ccc}, E_MR{ccc}, CG_maxit_ini, CG_minres);
            x            = zeros([size(x_tmp) nContrast]);
            x(:,:,:,ccc) = x_tmp; clear x_tmp

            sz    = size(x);
            y     = zeros(sz);
            if numel(sz) == 3
                sz(4) = 1;
            end
            x_it  = zeros([sz(1) sz(2) sz(3) sz(4) ADMM_maxit]);
            Rx_it = zeros([sz(1) sz(2) sz(3) sz(4) ADMM_maxit]);
            y_it  = zeros([sz(1) sz(2) sz(3) sz(4) ADMM_maxit]);
            toc();

        elseif ttt == 1 && ccc ~= 1

            tic();
            x(:,:,:,ccc) = solve_CG(kdata_OUT{ccc}, E_MR{ccc}, CG_maxit_ini, CG_minres);
            toc();

        else

            tic();
            x(:,:,:,ccc) = solve_reg_LLR(kdata_OUT{ccc}, E_MR{ccc}, ...
                Rx(:,:,:,ccc), y(:,:,:,ccc), CG_lambda, CG_maxit, CG_minres, x_it(:,:,:,ccc,ttt-1));
            toc();

        end

        x_it(:,:,:,ccc,ttt) = x(:,:,:,ccc);
    end
        if ttt == ADMM_maxit
            break;
        end

%     end

    %  OPTIMIZATION 2: Tensor Decomposition (Rx - denoising)
    fprintf('OPTIMIZATION 2: Tensor Decomposition (Rx - denoising)')

    Tensor = double(x + y);

    ref_img = abs(Tensor(:,:,:,end)); % reference = 4th contrast <--
    E_3D_PROST = Bustin_E_3D_HDPROST_v3(sig, patch_sz, max_patch, win, offset, debug, recon_mode, type, sharpness, ref_img);

    Rx = E_3D_PROST * Tensor;
    if any(any(any(any(isnan(Rx)))))
        fprintf("some NaN founds after denoisins in it %i. break\n",ccc)
        return;
    end
    Rx_it(:,:,:,:,ttt) = Rx;

	%  STEP 3: Lagrangian Update (y)

    y = y + x - Rx;
    y_it(:,:,:,:,ttt) = y;

end


end
