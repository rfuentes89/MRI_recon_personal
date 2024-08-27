function [image, residual_history] = Cart_itSENSE(k_space, E_operator, params)
%
% Uses conjugate gradient (CG) iteration to solve objective function:
%   (E^H*E)*rho = (E^H)*kspace
%
%  INPUT ARGUMENTS:
%   - k_space              : Measured k_space [kx, ky, kz, coils].
%   - E_operator           : E_operator of the constrast.
%   - params.max_iter      : Maximum number of iterations of CG. Defaults
%                            to 4.
%   - params.residual_tol  : Minimum residual threshold expected. Defaults
%                            to 1e-6.
%   - params.verbose       : If 1, provides detailed output information.
%                            Defaults to 1.
%
%  OUTPUT:
%   - image                  : Reconstructed image
%
%   See also BUILD_OPERATOR_RIGID


if ~exist('params', 'var')
    params = struct();
end

if ~isfield(params, 'max_iter'),       params.max_iter = 4; end
if ~isfield(params, 'residual_tol'),   params.residual_tol = 1e-6; end
if ~isfield(params, 'verbose'),        params.verbose = 0; end

% NOTE: CG VARIABLES
%       rho          : reconstructed image
%       residual     : Measures how far the current approximate solution rho
%                      is from completely satisfying the system.
%       p            : Search direction vector of residual greatest decrease.
%       alpha        : Magnitude of vector p to minimize the objective function.
%       beta         : Used to compute p to determine the next search direction.



% Form right hand side (rhs):
rhs = E_operator'*k_space;

% Initial solution
rho = zeros(size(rhs));

% Calculate initial residuals
% NOTE: the formula is:
% residual = rhs - E^H*(E*rho)
% but since rho is zero, is just residual = rhs.
residual = rhs;

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

    q = E_operator'*(E_operator*p);
    alpha = rr/(p(:)'*q(:));

    % Update result
    rho = rho + alpha*p;
    residual = residual - alpha*q;

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
