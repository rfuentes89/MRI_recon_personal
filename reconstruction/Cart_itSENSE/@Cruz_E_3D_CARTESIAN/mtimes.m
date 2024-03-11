function [res] = mtimes(a,b)

% a = encoding operator, 

if a.adjoint % EH operation
% b = full_k_data : (Ny,Nx,Nz,Nc) -> (Ny,Nx,Nz) when applying EH

    res_coils = zeros(a.siz(1),a.siz(2),a.siz(3),size(a.coils, 4)); % init
    At = a.At;
    coils = a.coils;

    for coil = 1:size(a.coils, 4) % number of coils
        % Sampling
        b_sample = b(:,:,:,coil).*At;
        % 3D FFT
%         b_sample = fftshift(ifft(ifftshift(b_sample,1),[],1),1)*sqrt(size(b_sample,1));
%         b_sample = fftshift(ifft(ifftshift(b_sample,2),[],2),2)*sqrt(size(b_sample,2));
%         b_sample = fftshift(ifft(ifftshift(b_sample,3),[],3),3)*sqrt(size(b_sample,3));

%         b_sample = ifft(b_sample,[],1);
%         b_sample = ifft(b_sample,[],2);
%         b_sample = ifft(b_sample,[],3);

%         b_sample = ifftn(b_sample); 
%         
%           b_sample = fftshift(ifft(ifftshift(b_sample,1),[],1));
%           b_sample = fftshift(ifft(ifftshift(b_sample,2),[],2));
%           b_sample = fftshift(ifft(ifftshift(b_sample,3),[],3));

        b_sample = sqrt(size(b_sample,1)).* fftshift( ifft(ifftshift(b_sample ,1),[],1), 1);
        b_sample = sqrt(size(b_sample,2)).* fftshift( ifft(ifftshift(b_sample ,2),[],2), 2);
        b_sample = sqrt(size(b_sample,3)).* fftshift( ifft(ifftshift(b_sample ,3),[],3), 3);

            
        % Coil weights
        res_coils(:,:,:,coil) = b_sample.*conj(coils(:,:,:,coil)); 
    end

    res = sum(res_coils,4);
    res(isnan(res)) = 0;
    
else % E operation
% b = full_image_data : (Ny,Nx,Nz) -> (Ny,Nx,Nz,Nc) when applying E
    
    res = zeros(a.Ksiz(1),a.Ksiz(2),a.Ksiz(3),size(a.coils, 4));
    At = a.At;
    coils = a.coils;
    
    b(isnan(b)) = 0;
    
    for coil = 1:size(a.coils, 4) % number of coils
        % Coil weights
        b_sample = b.*coils(:,:,:,coil);
        % 3D FFT
%         b_sample = fftshift(fft(ifftshift(b_sample,1),[],1),1)/sqrt(size(b_sample,1));
%         b_sample = fftshift(fft(ifftshift(b_sample,2),[],2),2)/sqrt(size(b_sample,2));
%         b_sample = fftshift(fft(ifftshift(b_sample,3),[],3),3)/sqrt(size(b_sample,3));

%           b_sample = fftshift(fft(ifftshift(b_sample,1),[],1));
%           b_sample = fftshift(fft(ifftshift(b_sample,2),[],2));
%           b_sample = fftshift(fft(ifftshift(b_sample,3),[],3));

        b_sample = 1/sqrt(size(b_sample,1))*fftshift(fft(ifftshift( b_sample, 1 ),[],1),1);
        b_sample = 1/sqrt(size(b_sample,2))*fftshift(fft(ifftshift( b_sample, 2 ),[],2),2);
        b_sample = 1/sqrt(size(b_sample,3))*fftshift(fft(ifftshift( b_sample, 3 ),[],3),3);

        % Sampling
        res(:,:,:,coil) = b_sample.*At;
    end


end
