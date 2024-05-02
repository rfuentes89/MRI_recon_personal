function x = CSL1NlCg_ORCCA(params)
    % 
    % res = CSL1NlCg(param)
    %
    % Compressed sensing reconstruction of undersampled k-space MRI data
    %
    % L1-norm minimization using non linear conjugate gradient iterations
    % 
    % Given the acquisition model y = E*x, and the sparsifying transform W, 
    % the program finds the x that minimizes the following objective function:
    %
    % f(x) = ||E*x - y||^2 + lambda1 * ||W*x||_1 + lambda2 * TV(x) 
    %
    % Based on the paper: Sparse MRI: The application of compressed sensing for rapid MR imaging. 
    % Lustig M, Donoho D, Pauly JM. Magn Reson Med. 2007 Dec;58(6):1182-95.
    %
    % Ricardo Otazo 2008
    %
    
    fprintf('\n Non-linear conjugate gradient algorithm')
    fprintf('\n ---------------------------------------\n')
    
    % starting point
    x0 = params.E'*params.y;

    x=single(x0);
    
    % line search parameters
    ls_params = params.line_search_params;
    %ls_params.grad_toll = 1e-3;
    %ls_params.relchg_tol = 1e-3;    
    
    % compute g0  = grad(f(x))
    g0 = grad(x,params);
    dx = -g0;
    
    % iterations
    step_i = 0;
    while(1)
	    step_i = step_i + 1;
        
        % backtracking line-search
	    f0 = objective(x,dx,0,params);
	    t = ls_params.t0;
        f1 = objective(x,dx,t,params);

        if params.verbose
            fprintf(' ite = %d, cost = %f \n',step_i,f1);
        end
        
        % Line search (i.e. find optimal step_size)
        lsiter = 0;
        % TODO(pdpino): check if power of 2 should be inside parenthesis
        while (f1 > f0 - ls_params.alpha*t*abs(g0(:)'*dx(:)))^2 & (lsiter<ls_params.max_iter)
    %         msg = sprintf('Current f1 = %f',f1); disp(msg);
            lsiter = lsiter + 1;
            t = t * ls_params.beta;
            f1 = objective(x,dx,t,params);
        end

        if lsiter >= ls_params.max_iter
            warning("Line search reached max iter = %d", ls_params.max_iter);
            return;
        end
        
	    % control the number of line searches by adapting the initial step search
	    if lsiter > 2, ls_params.t0 = ls_params.t0 * ls_params.beta;end 
	    if lsiter < 1, ls_params.t0 = ls_params.t0 / ls_params.beta; end
    
        % update x
	    x = (x + t*dx);
         
        % diff_rel = x - x0; relchg = norm(diff_rel(:))/max(norm(x0(:)),eps);
        % fprintf('itr=%d relchg=%4.1e', k, relchg);
        % fprintf('\n');
        % if relchg < ls_params.relchg_tol
        %     return;
        % end
        
	    
        %conjugate gradient calculation
	    g1 = grad(x,params);
	    bk = g1(:)'*g1(:)/(g0(:)'*g0(:)+eps);
	    g0 = g1;
	    dx =  - g1 + bk* dx;
	    
	    % stopping criteria (to be improved)
    	% if (k > param.n_iterations) || (norm(dx(:)) < ls_params.grad_toll  ), break;end
        if (step_i > params.max_iter), break;end
    
    end

end

function res = objective(x,dx,t,params)
    % L2-norm part with preconditioning
    w=params.E*(x+t*dx)-params.y;
    L2Obj=w(:)'*w(:);
    
    % L1-norm part
    if params.weight_L1
        w = params.W*(x+t*dx);
        L1Obj = sum((conj(w(:)).*w(:)+params.L1_smooth).^(1/2));
    else
        L1Obj = 0;
    end
    
    % TV part
    if params.weight_TV
        w = params.TV*(x+t*dx);
        TVObj = sum((w(:).*conj(w(:))+params.L1_smooth).^(1/2));
    else
        TVObj = 0;
    end
    
    % Temporal TV part
    if params.weight_TV_Temp
        w = params.TV_Temp*(x+t*dx);
        TV_TempObj = sum((w(:).*conj(w(:))+params.L1_smooth).^(1/2));
    else
        TV_TempObj = 0;
    end
    
    % MTV (Motion corrected temporal TV)
    if params.weight_MTV
        w = params.MTV*(x+t*dx);
        MTV_TempObj = sum((w(:).*conj(w(:))+params.L1_smooth).^(1/2));
    else
        MTV_TempObj = 0;
    end
    
    % L1 in image space
    if params.weight_id
        x = x+t*dx;
        IdObj = sum((x(:).*conj(x(:))+params.L1_smooth).^(1/2));
    else
        IdObj = 0;
    end

    % objective function
    res = L2Obj ...
        + params.weight_L1      * L1Obj ...
        + params.weight_TV      * TVObj ...
        + params.weight_TV_Temp * TV_TempObj ...
        + params.weight_MTV     * MTV_TempObj ...
        + params.weight_id      * IdObj;

end

function g = grad(x, params)
    % L2-norm part with preconditioning in E'
    L2Grad = 2.*(params.E'*(params.E*x-params.y));

    % L1-norm part
    if params.weight_L1
        w = params.W*x;
        L1Grad = params.W'*(w.*(w.*conj(w)+params.L1_smooth).^(-0.5));
    else
        L1Grad = 0;
    end

    % TV part
    if params.weight_TV
        w = params.TV*x;
        TVGrad = params.TV'*(w.*(w.*conj(w)+params.L1_smooth).^(-0.5));
    else
        TVGrad = 0;
    end

    % Temporal TV part
    if params.weight_TV_Temp
        w = params.TV_Temp*x;
        TV_TempGrad = params.TV_Temp'*(w.*(w.*conj(w)+params.L1_smooth).^(-0.5));
    else
        TV_TempGrad = 0;
    end

    % MTV (Motion corrected temporal TV)
    if params.weight_MTV
        w = params.MTV*x;
        MTV_TempGrad = params.MTV'*(w.*(w.*conj(w)+params.L1_smooth).^(-0.5));
    else
        MTV_TempGrad = 0;
    end

    % L1 in image space
    if params.weight_id
        % TODO(pdpino): is TV_Temp ok here?
        IdGrad = params.TV_Temp'*(x.*(x.*conj(x)+params.L1_smooth).^(-0.5));
    else
        IdGrad = 0;
    end

    % complete gradient
    g = L2Grad ...
       + params.weight_L1*L1Grad ...
       + params.weight_TV*TVGrad ...
       + params.weight_TV_Temp*TV_TempGrad ...
       + params.weight_id*IdGrad ...
       + params.weight_MTV*MTV_TempGrad;
end
