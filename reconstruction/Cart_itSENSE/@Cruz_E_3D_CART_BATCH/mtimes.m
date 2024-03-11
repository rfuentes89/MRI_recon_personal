function [res] = mtimes(a,b)

% a = encoding operator,

if a.adjoint % EH operation
% b = full_k_data : (Ny,Nx,Nz,Nc) -> (Ny,Nx,Nz) when applying EH
% b can also be (Ny,Nx,Nz,Nc,Nb) -> (Ny,Nx,Nz)

    res = zeros(a.siz(1),a.siz(2),a.siz(3));
    At = a.At;
    coils = a.coils;
    nbins = size(At,4);
    for bin = 1:nbins
        res_coils = zeros(a.siz(1),a.siz(2),a.siz(3),size(a.coils, 4)); % init
        Bin_At = double(At(:,:,:,bin));
        curr_mf = a.MF;
        % Generate a sparse matrix either way
        if iscell(curr_mf)
            curr_mf = curr_mf{bin};
        else
            curr_mf = resampleMatrix(zeros(a.siz),curr_mf(:,:,:,:,bin));
        end

        if ndims(b) == 5
            b_aux = b(:,:,:,:,bin);
        elseif ndims(b) == 4
            b_aux = b;
        end

        parfor coil = 1:size(a.coils, 4) % number of coils
            % Sampling
            b_sample = b_aux(:,:,:,coil).*Bin_At;

            % FFT
            b_sample = sqrt(size(b_sample,1)).* fftshift( ifft(ifftshift(b_sample ,1),[],1), 1);
            b_sample = sqrt(size(b_sample,2)).* fftshift( ifft(ifftshift(b_sample ,2),[],2), 2);
            b_sample = sqrt(size(b_sample,3)).* fftshift( ifft(ifftshift(b_sample ,3),[],3), 3);
            % Coil weights
            res_coils(:,:,:,coil) = b_sample.*conj(coils(:,:,:,coil));
	     %res_coils(:,:,:,coil) = complex(matrix_interpolation(real(res_coils(:,:,:,coil)),curr_mf'),matrix_interpolation(imag(res_coils(:,:,:,coil)),curr_mf'));
        end

        res_bin = sum(res_coils,4);
        res_bin = complex(matrix_interpolation(real(res_bin),curr_mf'),matrix_interpolation(imag(res_bin),curr_mf'));

        % normalisation of motion fields
        motion_norm = matrix_interpolation(ones(size(res_bin)),curr_mf);
        res_bin = res_bin./motion_norm;
        res_bin(isnan(res_bin)) = 0; res_bin(isinf(res_bin)) = 0;

        res = res + res_bin;


    end

    res(isnan(res))  = 0;

else % E operation
% b = full_image_data : (Ny,Nx,Nz) -> (Ny,Nx,Nz,Nc) when applying E

    At = a.At;
    coils = a.coils;
    nbins = size(At,4);
    Ksiz = a.Ksiz;
    if numel(a.Ksiz) == 4
        res = zeros(a.Ksiz(1),a.Ksiz(2),a.Ksiz(3),a.Ksiz(4));
    elseif numel(a.Ksiz) == 5
        res = zeros(a.Ksiz(1),a.Ksiz(2),a.Ksiz(3),a.Ksiz(4),a.Ksiz(5));
    end

    % Sampling for normalization
    At_norm = sum(At,4);

    b(isnan(b)) = 0;

    for bin = 1:nbins
        curr_mf = a.MF;
        % Generate a sparse matrix either way
        if iscell(curr_mf)
            curr_mf = curr_mf{bin};
        else
            curr_mf = resampleMatrix(zeros(a.siz),curr_mf(:,:,:,:,bin));
        end

	    warp_b = complex(matrix_interpolation(real(b),curr_mf),matrix_interpolation(imag(b),curr_mf));

        Bin_At = double(At(:,:,:,bin));


        temp = zeros(a.Ksiz(1),a.Ksiz(2),a.Ksiz(3),size(a.coils, 4));
        parfor coil = 1:size(a.coils, 4) % number of coils
            % Coil weights
            b_sample = warp_b.*coils(:,:,:,coil);
            % FFT
            b_sample = 1/sqrt(size(b_sample,1))*fftshift(fft(ifftshift( b_sample, 1 ),[],1),1);
            b_sample = 1/sqrt(size(b_sample,2))*fftshift(fft(ifftshift( b_sample, 2 ),[],2),2);
            b_sample = 1/sqrt(size(b_sample,3))*fftshift(fft(ifftshift( b_sample, 3 ),[],3),3);
            % Sampling
            if numel(Ksiz) == 5
                temp(:,:,:,coil) = (b_sample.*Bin_At) + (temp(:,:,:,coil).*~Bin_At);
            elseif numel(Ksiz) == 4
                res(:,:,:,coil) = (b_sample.*Bin_At) + (res(:,:,:,coil).*~Bin_At);
            end
        end

        if numel(a.Ksiz) == 5
            res(:,:,:,:,bin) = temp;
        end

    end

%     % If the sampling matrices are not mutually exclusive (they should),
%     % this will normalize each kpoint accordingly.
%     res = res ./ repmat(At_norm,[1 1 1 size(a.coils, 4)]);
%     res(isnan(res)) = 0;


%    res(:,:,coil) = Image2K(warped_b.*coils(:,:,coil)).*Bin_At + res(:,:,coil).*~Bin_At;
end
