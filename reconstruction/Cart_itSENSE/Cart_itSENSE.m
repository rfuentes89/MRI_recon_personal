function [best_rho, residuals] = Cart_itSENSE(m, E, maxit, verbose)
%
% Uses conjugate gradient iteration to solve:
%   (E^H*E)rho = E^H*m
%
%  INPUT ARGUMENTS:
%   - m                 : measured data [k,coil]
%   - S                 : complex sensitivities [x,y,z,coil]
%   - weights           : density compensation
%   - maxit:            : maximum number of iterations of CG
%   - precision:        : precision of gridding
%
%  OUTPUT:
%   - rho               : reconstruction result

% Variable parameters:
limit = 1e-6;

% Get dimensions
% siz = tformdata.siz;
% coils = size(m,2);
% num_ft_elements = prod(siz);

% fhandle_E = @get_E;
% fhandle_EH = @get_EH;

% coil_rss = tformdata.coil_rss;

if nargin<4
    verbose = 1;
end

% Form right hand side:
if verbose
    fprintf('Forming right hand side...');
end
rhs = E'*m;
siz = size(rhs);

% S = reshape(S,num_ft_elements,coils);
% parfor nc = 1: coils,
%     %rhs(:,nc) = fhandle_EH(m(:,nc),tformdata,S(:,nc),precision);
%     rhs(:,nc) = fhandle_EH(m(:,nc),tformdata,S(:,nc),precision);
% end
% 
% rhs = sum(rhs,2);
% 
% %divide by rss
% rhs = rhs ./  coil_rss(:);
% %rhs = rhs ./  coil_rss(:); % additional
% rhs(coil_rss==0) = 0;
% rhs(isnan(rhs)) = 0;

% Calculate initial residuals
if verbose
    fprintf('Calculate initial residual...');
end

rho = zeros(siz);

% rho = rho ./ coil_rss;
% rho(coil_rss==0) = 0;
% rho(isnan(rho)) = 0;    

rho = rho(:);
res = rho;

if verbose
    fprintf('done\n');
end
% Iterations
%---------------
rhs = reshape(rhs, siz); 
res = reshape(res, siz); 
rho = reshape(rho, siz); 
r = rhs - res;
rr_0 = r(:)'*r(:);
rr = 0;

residuals = zeros(maxit,1);
% Run iteration
if verbose
    fprintf('Iterating...\n');
end
for it = 1:maxit
    rr_1 = rr;
    rr = r(:)'*r(:);
    if (it == 1)
        p = r;
    else        
        beta = rr/rr_1;
        p =  r + beta*p;
    end
    
    q = E'*(E*p);

    % CG magnitude and direction
    q = reshape(q, siz);      
    alpha = rr/(p(:)'*q(:)); 
    rho = rho + alpha*p;
    r = r - alpha*q;
 
    clear q;
    if verbose
        fprintf('Iteration %d, rho = %12.8e\n', it, rr/rr_0);drawnow;
    end
    
    
    residuals(it) = rr/rr_0;

    
    if (rr/rr_0 < limit)
       break;
    end
    
end

best_rho = reshape(rho, siz);

if verbose
    fprintf('Reconstruction done\n');
end
