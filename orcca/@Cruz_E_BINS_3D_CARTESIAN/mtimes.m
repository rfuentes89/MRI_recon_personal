function [res] = mtimes(a,b)

% function [res,res_with_coils] = mtimes(a,b)

% a = encoding operator, 
% b = full_k_data : (Ny,Nx,Nz,Nc,Nt) -> (Ny,Nx,Nz,Nt) when applying EH
% b = full_image_data : (Ny,Nx,Nz,Nt) -> (Ny,Nx,Nz,Nc,Nt) when applying E

if a.adjoint % EH operation
    res = zeros(a.siz(1),a.siz(2),a.siz(3),a.nbins); % result of the EH*b operation
    %res_with_coils = zeros(a.siz(1),a.siz(2),a.siz(3),a.nbins,a.ncoils);
    for bin = 1:a.nbins % iterating thru bins
        res_coils = b(:,:,:,:,bin); % init
        % Parfor complaints
%         Bin_At = complex(double(a.At(:,:,:,bin)));
        coils = a.csm;
%         for coil = 1:a.ncoils % number of coils
        parfor coil = 1:a.ncoils % number of coils
            % Sampling -> FFT -> Coil
%             res_coils(:,:,coil) = K2Image(b(:,:,coil,bin).*Bin_At).*conj(coils(:,:,coil)); 
%             res_coils(:,:,:,coil) = b(:,:,:,coil,bin).*Bin_At;
            res_coils(:,:,:,coil) = fftshift( ifft(ifftshift(res_coils(:,:,:,coil) ,1),[],1), 1);
            res_coils(:,:,:,coil) = fftshift( ifft(ifftshift(res_coils(:,:,:,coil) ,2),[],2), 2);
            res_coils(:,:,:,coil) = fftshift( ifft(ifftshift(res_coils(:,:,:,coil) ,3),[],3), 3);

%             res_coils(:,:,:,coil) = sqrt(size(res_coils(:,:,:,coil),1)).* fftshift( ifft(ifftshift(res_coils(:,:,:,coil) ,1),[],1), 1);
%             res_coils(:,:,:,coil) = sqrt(size(res_coils(:,:,:,coil),2)).* fftshift( ifft(ifftshift(res_coils(:,:,:,coil) ,2),[],2), 2);
%             res_coils(:,:,:,coil) = sqrt(size(res_coils(:,:,:,coil),3)).* fftshift( ifft(ifftshift(res_coils(:,:,:,coil) ,3),[],3), 3);
            res_coils(:,:,:,coil) = res_coils(:,:,:,coil).*conj(coils(:,:,:,coil));
        end
        %res_with_coils(:,:,bin,:) = res_coils;
        % Applying intensity correction
        res_bin = sum(res_coils,4);
        res_bin = res_bin ./ a.coil_rss;
        res_bin(a.coil_rss==0) = 0;
        res_bin(isnan(res_bin)) = 0;
        res(:,:,:,bin) = res_bin; % storing bins in a single matrix
    end  

else % E operation
    res = zeros(a.Ksiz(1),a.Ksiz(2),a.Ksiz(3),a.ncoils,a.nbins);
    for bin = 1:a.nbins % iterating thru bins
        % Applying intensity correction
        b_bin = b(:,:,:,bin) ./ a.coil_rss;
        b_bin(a.coil_rss==0) = 0;
        b_bin(isnan(b_bin)) = 0; 
        % Parfor complaints
        Bin_At = complex(double(a.At(:,:,:,bin)));
        coils = a.csm;
%         for coil = 1:a.ncoils % number of coils
        parfor coil = 1:a.ncoils % number of coils
            b_sample = b_bin.*coils(:,:,:,coil);
            b_sample = 1/(size(b_sample,1))*fftshift(fft(ifftshift( b_sample, 1 ),[],1),1);
            b_sample = 1/(size(b_sample,2))*fftshift(fft(ifftshift( b_sample, 2 ),[],2),2);
            b_sample = 1/(size(b_sample,3))*fftshift(fft(ifftshift( b_sample, 3 ),[],3),3);

        % Sampling
        res(:,:,:,coil,bin) = b_sample.*Bin_At;
%             b_bin_coil = b_bin.*coils(:,:,:,coil); % coil weight
%             
%             res(:,:,coil,bin) = Image2K(b_bin_coil).*Bin_At;
            
            % k-space analysis shenanigans
%             res(:,:,coil,bin) = Image2K(b_bin_coil);
        end
    end

end