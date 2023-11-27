function [res] = mtimes(a,b)

% a = encoding operator

if a.adjoint % EH operation

    % to implement
    
else % E operation

    res = zeros(size(b));
    
    if (a.recon_mode == 3) % 2D multi-slice
        
        scaling     = max(abs(b(:)));
    
        for id = 1:size(b,3)
            
            Tensor      = double(b(:,:,id));
            [res1, ~]   = Bustin_denoising_patch_mex_v2(abs(Tensor)./scaling, imag(Tensor)./scaling, a.sig, a.patch_sz, a.max_patch, a.win, a.offset, a.type, a.recon_mode);
            res(:,:,id) = scaling .* res1 .* exp(1i*angle(Tensor));
            
        end

    
    elseif (a.recon_mode == 4) % 3D implementation
        
        Tensor      = double(b);
        scaling     = max(abs(Tensor(:)));%6.2257e-05;%max(abs(Tensor(:)));
        [res1, res2]   = Bustin_denoising_patch_mex_v3(abs(Tensor)./scaling, zeros(size(Tensor)), a.sig, a.patch_sz, a.max_patch, a.win, a.offset, a.debug, a.recon_mode, a.type, a.sharpness);
        res         = scaling .* res1 .* exp(1i*angle(Tensor));
            
    end



end
