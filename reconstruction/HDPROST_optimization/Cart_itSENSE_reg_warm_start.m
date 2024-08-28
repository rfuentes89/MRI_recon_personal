function [image, residual_history] = Cart_itSENSE_reg_warm_start(k_space,E_operator,image_reg,image_initial,lambda,params)
%
% Uses conjugate gradient iteration to solve:
%   (E^H*E + lambda) rho = E^H*k_space + lambda*image_reg
%
%  INPUT ARGUMENTS:
%   - k_space              : Measured k_space [kx, ky, kz, coils].
%   - E_operator           : Encoding operator.
%   - image_reg            : Regularization image used to maintain data
%                            consistency after HD PROST denoising process.
%   - image_initial        : Initial solution for a warm start based on 
%                            the last iteration reconstructed image. 
%   - lambda               : Regularization strength.

%   - params.max_iter      : Maximum number of iterations of CG. Defaults
%                            to 3.
%   - params.residual_tol  : Minimum residual threshold expected. Defaults
%                            to 1e-6.
%   - params.verbose       : If 1, provides detailed output information.
%                            Defaults to 0.
%
%
%  OUTPUT:
%   - image               : Reconstructed image.
%
%   See also BUILD_OPERATOR_RIGID, BUILD_OPERATOR_NON_RIGID




if ~exist('params', 'var')
    params = struct();
end

if ~isfield(params, 'max_iter'),       params.max_iter = 3; end
if ~isfield(params, 'residual_tol'),   params.residual_tol = 1e-6; end
if ~isfield(params, 'verbose'),        params.verbose = 0; end

% NOTE: CG VARIABLES
%       rho          : image reconstructed
%       residual     : Measures how far the current approximate solution rho
%                      is from completely satisfying the system.
%       p            : Search direction vector of residual greatest decrease.
%       alpha        : Magnitude of vector p to minimize the objective function.
%       beta         : Used to compute p to determine the next search direction.


% Initial solution
rho = image_initial;

% Form left hand side (lhs)
lhs = E_operator'*(E_operator*rho) + lambda*rho;


% Form right hand side (rhs)
rhs = E_operator'*k_space + lambda*image_reg;

% Calculate initial residuals
residual = rhs - lhs;

% Initial values
p = residual;
rr = residual(:)'*residual(:); % residual norm squared

initial_rr = rr;
if nargout > 1
    residual_history = zeros(params.max_iter,1);
end

% Run iterations
if params.verbose >= 1
    fprintf('\tStarting it-sense...\n');
end

for i_iter = 1:params.max_iter
    q = E_operator'*(E_operator*p) + lambda*p;

    alpha = rr/(p(:)'*q(:));

    % Update result
    rho = rho + alpha*p;
    residual = residual - alpha*q;

    improvement = rr/initial_rr;
    if (improvement < params.residual_tol)
       if params.verbose >= 1
            fprintf('\tStopping: residuals improved less than tolerance: %12.8e\n', improvement);
        end
        break;
    end

    if nargout > 1
        residual_history(i_iter) = rr;
    end

    if params.verbose >= 1
        fprintf('\tite=%d, residual=%12.8e, intensity=%12.8e\n', i_iter, rr, mean(rho(:)));
    end

    improvement = rr/initial_rr;
    if (improvement < params.residual_tol)
        if params.verbose >= 1
            fprintf('\tStopping: residuals improved less than tolerance: %12.8e\n', improvement);
        end
        break;
    end

    rr_old = rr;
    rr = residual(:)'*residual(:);
    beta = rr / rr_old;
    p = residual + beta*p;
end

if params.verbose >= 1 && i_iter >= params.max_iter
    fprintf("\tStopped: reached max iter = %d\n", i_iter);
end

image = rho;
end