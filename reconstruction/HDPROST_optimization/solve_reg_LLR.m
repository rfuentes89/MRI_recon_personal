function x = solve_reg_LLR(kdata,E,Rx,y,CG_lambda,CG_maxit,CG_minres,x0)
    % Call CG
    [nav_it,residuals] = Cart_itSENSE_reg_warm_start(kdata, E, Rx-y, CG_lambda, CG_maxit, CG_minres, x0);

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

