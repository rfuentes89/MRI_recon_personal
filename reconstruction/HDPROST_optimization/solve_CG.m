function x = solve_CG(kdata,E,CG_maxit,CG_minres)

    % Call CG 
    [nav_it,residuals] = Cart_itSENSE_NRP(kdata,E,CG_maxit,CG_minres,0);

    if ndims(nav_it) == 5
        
        x= nav_it(:,:,:,:,end);
        
    elseif ndims(nav_it) == 4
        
        x= nav_it(:,:,:,end);
        
    elseif ndims(nav_it) == 3
            
        x= nav_it(:,:,end);
        
    end
%     if ndims(nav_it) == 5 
%     
%         % Chose iteration
%         it = find(residuals<CG_minres);
%         if ~isempty(it)    
%             x = nav_it(:,:,:,:,it(1));
%         else
%             [~,it] = min(residuals(:));
%             x = nav_it(:,:,:,:,it);
%         end
%     else
%         % Chose iteration
%         it = find(residuals<CG_minres);
%         if ~isempty(it)    
%             x = nav_it(:,:,:,it(1));
%         else
%             [~,it] = min(residuals(:));
%             x = nav_it(:,:,:,it);
%         end
%     end

end

