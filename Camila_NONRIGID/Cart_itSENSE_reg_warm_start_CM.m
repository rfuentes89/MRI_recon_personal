function [best_rho,residuals] = Cart_itSENSE_reg_warm_start_CM(m,E,x_prior,lambda,maxit,limit,x0)
%
% Uses conjugate gradient iteration to solve:
%   (E^H*E + R^H*R * lambda) rho = E^H*m
%
%  INPUT ARGUMENTS:
%   - m                 : measured data [k,coil]
%   - E                 : encoding operator
%   - R                 : regularization operator
%   - lambda            : regularization strenght
%   - maxit:            : maximum number of iterations of CG
%   - precision:        : precision of gridding
%
%  OUTPUT:
%   - rho               : reconstruction result

% Variable parameters:

if nargin < 4           
    limit = 5e-3;
end


% Get dimensions
% siz = tformdata.siz;
% coils = size(m,2);
% num_ft_elements = prod(siz);

% fhandle_E = @get_E;
% fhandle_EH = @get_EH;

% coil_rss = tformdata.coil_rss;

% Form right hand side:
% fprintf('Forming right hand side...');

rhs = E'*m + lambda*x_prior;
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
% fprintf('Calculate initial residual...');
if nargin > 6
    rho = (E'*(E*x0)) + (lambda*x0);
    warm_start = 1;
else
    rho = zeros(siz);
    warm_start = 0;
end

% rho = rho ./ coil_rss;
% rho(coil_rss==0) = 0;
% rho(isnan(rho)) = 0;    

rho = rho(:);
res = rho;

% fprintf('...done\n');

% Iterations
%---------------
rhs = reshape(rhs, siz); 
res = reshape(res, siz); 
rho = reshape(rho, siz); 

r0 = rhs - res;
rr_0 = r0(:)'*r0(:);
rr = 0;

d1 = r0;
z1 = (E'*(E*d1)) + (lambda*d1);
c1 = (r0(:)'*r0(:)) / (d1(:)'*z1(:));

x1 = x0 + c1*d1;
r1 = r0 - c1*z1;


r_m1 = r1;
r_m2 = r0;
d = d1;
x = x1;

% Init some output variables
residuals = zeros(maxit,1);
if numel(siz) == 4 
    best_rho = single(zeros(siz(1),siz(2),siz(3),siz(4),maxit));
    best_rho(:,:,:,:,1) = single(x1);
elseif numel(siz) == 3
    best_rho = single(zeros(siz(1),siz(2),siz(3),maxit));
    best_rho(:,:,:,1) = single(x1);
else
    best_rho = single(zeros(siz(1),siz(2),maxit));
    best_rho(:,:,1) = single(x1);
end

it = 1;
rr = (r1(:)'*r1(:));
residuals(1) = rr/rr_0;
% fprintf('Iteration %d, rho = %12.8e\n', it, residuals(it));drawnow;

it = 2;
% Run iteration

% fprintf('Iterating...\n');
for it = 2:maxit,
    
    d = r_m1 + ( (r_m1(:)'*r_m1(:))/((r_m2(:)'*r_m2(:))) * d );
    z = (E'*(E*d)) + (lambda*d);
    c = (r_m1(:)'*r_m1(:)) / (d(:)'*z(:));
    
    x = x + c*d;
    r = r_m1 - c*z;
    
    r_m2 = r_m1;
    r_m1 = r;
    
    rr = (r(:)'*r(:));
    
    if numel(siz) == 4 
        best_rho(:,:,:,:,it) = single(x);
        residuals(it) = rr/rr_0;
    elseif numel(siz) == 3
        best_rho(:,:,:,it) = single(x);
        residuals(it) = rr/rr_0;
    else
        best_rho(:,:,it) = single(x);
        residuals(it) = rr/rr_0;
    end
    
%     fprintf('Iteration %d, rho = %12.8e\n', it, residuals(it));drawnow;
    
%     if (rr/rr_0 < limit)
%        break;
%     end
    
end

%     
%     rr_1 = rr;
%     rr = r(:)'*r(:);
%     if (it == 1) 
%         p = r;
%     else        
%         beta = rr/rr_1;
%         p =  r + beta*p;    
%     end
%     
%     q1 = E'*(E*p);
%     q2 = p; % regularization transform is identity
%     q = q1 + (lambda*q2);
%     
% %     %divide by sum of squares
% %     p_1 = p ./ coil_rss;
% %     p_1(coil_rss==0) = 0;
% %     p_1(isnan(p_1)) = 0;
% % 
% %     parfor c = 1:coils,
% %         tmp = fhandle_E(p_1(:),tformdata,S(:,c),kpos, precision);
% %         q(:,c) = fhandle_EH(tmp, tformdata,S(:,c),precision);
% %     end
% %     
% %     q = sum(q,2);
% %  
% %     %divide by sum of squares
% %     q = q ./ coil_rss(:);
% %     q(coil_rss==0) = 0;
% %     q(isnan(q)) = 0;
% 
%     % CG magnitude and direction
%     q = reshape(q, siz);      
%     alpha = rr/(p(:)'*q(:)); 
%     rho = rho + alpha*p;
%     rho1 = reshape(rho,siz);
%     r = r - alpha*q;
%  
%     clear q;
%     fprintf('Iteration %d, rho = %12.8e\n', it, rr/rr_0);drawnow;
%     
%     normalized_rho = rho1;
%     
%     % with warm start the results come scaled. unsure about the source.
%     % hot fixing it instead.
% %     if (warm_start)
% %         if it == 1
% %             a = sum(abs(x0(:)));
% %             b = sum(abs(normalized_rho(:)));
% %             warm_norm = b/a;
% %         end
% %         normalized_rho = normalized_rho / warm_norm;
% %     end
%             
%         
%     
% %     normalized_rho = rho1 ./ coil_rss;
% %     normalized_rho(coil_rss==0) = 0;
% %     normalized_rho(isnan(normalized_rho)) = 0;    
%     
% %     if numel(siz) == 3
% %         best_rho(:,:,:,it) = normalized_rho;
% %         residuals(it) = rr/rr_0;
% %     else
% %         best_rho(:,:,it) = normalized_rho;
% %         residuals(it) = rr/rr_0;
% %     end
%     if numel(siz) == 4 
%         best_rho(:,:,:,:,it) = single(normalized_rho);
%         residuals(it) = rr/rr_0;   
%     elseif numel(siz) == 3
%         best_rho(:,:,:,it) = single(normalized_rho);
%         residuals(it) = rr/rr_0;
%     else
%         best_rho(:,:,it) = single(normalized_rho);
%         residuals(it) = rr/rr_0;
%     end
%     
%     if (rr/rr_0 < limit)
%        break;
%     end
%     
% end

% fprintf('...done\n');

