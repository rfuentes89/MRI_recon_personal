function x = CSL1NlCg_ORCCA_gui(x0,params)
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
    x=single(x0);
    
    % line search parameters
    maxlsiter = 150 ;
    gradToll = 1e-3 ;
    params.l1Smooth = 1e-15;	
    alpha = 0.01;  
    beta = 0.6;
    t0 = 1 ; 
    k = 0;
    relchg_tol = 1e-3;
    
    
    % compute g0  = grad(f(x))
    g0 = grad(x,params);
    dx = -g0;
    
    % iterations
    while(1)
	    k = k + 1;
    %     x0=x;
        
        % backtracking line-search
	    f0 = objective(x,dx,0,params);
    %     msg = sprintf('Target f0 = %d',f0); disp(msg);
	    t = t0;
        f1 = objective(x,dx,t,params);
        % print some numbers	
        if params.display
            fprintf(' ite = %d, cost = %f \n',k,f1);
        end
        
	    lsiter = 0;
    %     disp('Looping objective');
        % TODO(pdpino): check if power of 2 should be inside parenthesis
        while (f1 > f0 - alpha*t*abs(g0(:)'*dx(:)))^2 & (lsiter<params.lsiter_max)
    %         msg = sprintf('Current f1 = %f',f1); disp(msg);
            lsiter = lsiter + 1;
            t = t * beta;
            f1 = objective(x,dx,t,params);
        end
    
        if lsiter == maxlsiter
            disp('Error - line search ...');
            return;
        end
        %disp(lsiter)
        
	    % control the number of line searches by adapting the initial step search
	    if lsiter > 2, t0 = t0 * beta;end 
	    if lsiter < 1, t0 = t0 / beta; end
    
        % update x
	    x = (x + t*dx);
         
    %         diff_rel = x - x0; relchg = norm(diff_rel(:))/max(norm(x0(:)),eps);
    %         fprintf('itr=%d relchg=%4.1e', k, relchg);
    %         fprintf('\n');
    %         if relchg < relchg_tol
    %             return;
    %         end
        
	    
        
        %conjugate gradient calculation
	    g1 = grad(x,params);
	    bk = g1(:)'*g1(:)/(g0(:)'*g0(:)+eps);
	    g0 = g1;
	    dx =  - g1 + bk* dx;
	    
	    % stopping criteria (to be improved)
    % 	if (k > param.nite) || (norm(dx(:)) < gradToll  ), break;end
        if (k > params.nite), break;end
    
    end

end

function res = objective(x,dx,t,params)
    % L2-norm part with preconditioning
    w=params.E*(x+t*dx)-params.y;
    L2Obj=w(:)'*w(:);
    
    % L1-norm part
    if params.L1Weight
        w = params.W*(x+t*dx);
        L1Obj = sum((conj(w(:)).*w(:)+params.l1Smooth).^(1/2));
    else
        L1Obj = 0;
    end
    
    % TV part
    if params.TVWeight
        w = params.TV*(x+t*dx);
        TVObj = sum((w(:).*conj(w(:))+params.l1Smooth).^(1/2));
    else
        TVObj = 0;
    end
    
    % Temporal TV part
    if params.TV_TempWeight
        w = params.TV_Temp*(x+t*dx);
        TV_TempObj = sum((w(:).*conj(w(:))+params.l1Smooth).^(1/2));
    else
        TV_TempObj = 0;
    end
    
    % MTV (Motion corrected temporal TV)
    if params.MTVWeight
        w = params.MTV*(x+t*dx);
        MTV_TempObj = sum((w(:).*conj(w(:))+params.l1Smooth).^(1/2));
    else
        MTV_TempObj = 0;
    end
    
    % L1 in image space
    if params.IdWeight
        x = x+t*dx; 
        IdObj = sum((x(:).*conj(x(:))+params.l1Smooth).^(1/2));
    else
        IdObj = 0;
    end

    % objective function
    res = L2Obj ...
        + params.L1Weight*L1Obj ...
        + params.TVWeight*TVObj ...
        + params.TV_TempWeight*TV_TempObj ...
        + params.IdWeight*IdObj ...
        + params.MTVWeight*MTV_TempObj;

end

function g = grad(x, params)
    % L2-norm part with preconditioning in E'
    L2Grad = 2.*(params.E'*(params.E*x-params.y));
    
    % L1-norm part
    if params.L1Weight
        w = params.W*x;
        L1Grad = params.W'*(w.*(w.*conj(w)+params.l1Smooth).^(-0.5));
    else
        L1Grad = 0;
    end
    
    % TV part
    if params.TVWeight
        w = params.TV*x;
        TVGrad = params.TV'*(w.*(w.*conj(w)+params.l1Smooth).^(-0.5));
    else
        TVGrad = 0;
    end
    
    % Temporal TV part
    if params.TV_TempWeight
        w = params.TV_Temp*x;
        TV_TempGrad = params.TV_Temp'*(w.*(w.*conj(w)+params.l1Smooth).^(-0.5));
    else
        TV_TempGrad = 0;
    end
    
    % MTV (Motion corrected temporal TV)
    if params.MTVWeight
        w = params.MTV*x;
        MTV_TempGrad = params.MTV'*(w.*(w.*conj(w)+params.l1Smooth).^(-0.5));
    else
        MTV_TempGrad = 0;
    end
    
    % L1 in image space
    if params.IdWeight
        IdGrad = params.TV_Temp'*(x.*(x.*conj(x)+params.l1Smooth).^(-0.5));
    else
        IdGrad = 0;
    end
    
    
    % complete gradient
    g = L2Grad ...
       + params.L1Weight*L1Grad ...
       + params.TVWeight*TVGrad ...
       + params.TV_TempWeight*TV_TempGrad ...
       + params.IdWeight*IdGrad ...
       + params.MTVWeight*MTV_TempGrad;

end
