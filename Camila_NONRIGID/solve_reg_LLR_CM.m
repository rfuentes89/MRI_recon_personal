function x = solve_reg_LLR_CM(kdata,E,Rx,y,CG_lambda,CG_maxit,CG_minres,x0)

    % Call CG 
%     [nav_it,residuals] = reg_CG_MRF(kdata,E,R,y,CG_lambda,CG_maxit,CG_minres);
    if nargin < 8
        [nav_it,residuals] = Cart_itSENSE_dict_reg(kdata,E,Rx-y,CG_lambda,CG_maxit,CG_minres);
    else
        [nav_it,residuals] = Cart_itSENSE_reg_warm_start_CM(kdata, E, Rx-y, CG_lambda, CG_maxit, CG_minres, x0);
    end

    if ndims(nav_it) == 4
        
        x= nav_it(:,:,:,end);
        
    elseif ndims(nav_it) == 3
            
        x= nav_it(:,:,end);
        
    elseif ndims(nav_it) == 5
        % Chose iteration
        it = find(residuals<CG_minres);
        if ~isempty(it)
            x = nav_it(:,:,:,:,it(1));
        else
            [~,it] = min(residuals(:));
            x(:,:,:,:) = nav_it(:,:,:,:,it);
        end
        
    else
        
        % Chose iteration
        it = find(residuals<CG_minres);
        if ~isempty(it)    
            x = nav_it(:,:,:,it(1));
        else
            [~,it] = min(residuals(:));
            x(:,:,:) = nav_it(:,:,:,it);
        end
    end

end

