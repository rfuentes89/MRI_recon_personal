function [res] = mtimes(a,b)

% a = encoding operator

if a.adjoint % EH operation

    % to implement
    
else % E operation

    res = zeros(size(b));
    
    if (a.recon_mode == 5) % 2D multi-slice multi-contrast complex implementation
        
        scaling     = max(abs(b(:)));
    
        tic();
        for id = 1:size(b,3)
            
            Tensor      = double(squeeze(b(:,:,id,:)));
            ref_img     = double(a.ref_img(:,:,id));
            [res1, res2]   = Bustin_denoising_patch_mex_v3(real(Tensor)./scaling, imag(Tensor)./scaling, a.sig, a.patch_sz, a.max_patch, a.win, a.offset, 0, a.recon_mode, 0, a.sharpness, ref_img);
            res(:,:,id,:) = scaling .* (res1 + 1i.*res2);
            
        end
        toc();
    
    elseif (a.recon_mode == 4 || a.recon_mode == 6) % 3D multi-contrast complex implementation
        
        Tensor          = double(b);
        scaling         = max(abs(Tensor(:)));
        [res1, res2]    = Bustin_denoising_patch_mex_v3(real(Tensor)./scaling, imag(Tensor)./scaling, a.sig, a.patch_sz, a.max_patch, a.win, a.offset, a.debug, a.recon_mode, a.type, a.sharpness, a.ref_img);
        res             = scaling .* (res1 + 1i*res2);
        
        
    end
    
end


