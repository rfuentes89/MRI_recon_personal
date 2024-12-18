function [res] = mtimes(operator,input)

n_bins = numel(operator.At);
[n_x, n_y, n_z, ~] = size(operator.coils);

if operator.adjoint % EH operation
% input: k_spaces: cell{n_bins}: array(nx, ny, nz, ncoils)
% result: image: array(nx, ny, nz)
    k_spaces = input;
    res = zeros(n_x, n_y, n_z);

    for bin = 1:n_bins
        % Sampling
        % TODO(pdpino): can we skip this step at all? only apply this mask
        % once at the beginning
        b_sample = k_spaces{bin}.*operator.At{bin};
        % size: nx, ny, nz, n_coils

        % FFT
        b_sample = sqrt(size(b_sample,1))*fftshift( ifft(ifftshift(b_sample ,1),[],1), 1);
        b_sample = sqrt(size(b_sample,2))*fftshift( ifft(ifftshift(b_sample ,2),[],2), 2);
        b_sample = sqrt(size(b_sample,3))*fftshift( ifft(ifftshift(b_sample ,3),[],3), 3);

        % Coil weights
        res_coils = b_sample.*conj(operator.coils);

        % Sum over coils
        res_bin = sum(res_coils, 4);
        % size: nx, ny, nz

        % Apply DF
        curr_mf = operator.interpolation_matrices{bin};
        curr_mf_t = curr_mf';
        res_bin = complex(matrix_interpolation(real(res_bin),curr_mf_t),matrix_interpolation(imag(res_bin),curr_mf_t));

        % normalisation of motion fields
        motion_norm = matrix_interpolation(ones(size(res_bin)),curr_mf_t);
        res_bin = res_bin./motion_norm;
        res_bin(isnan(res_bin)) = 0; res_bin(isinf(res_bin)) = 0;

        res = res + res_bin;
    end

    res(isnan(res)) = 0;

else % E operation
% input: image: array(nx, ny, nz)
% result: cell{n_bins}: array(nx, ny, nz, ncoils)
    image = input;
    assert(ndims(image) == 3);
    image(isnan(image)) = 0;

    res = cell(n_bins, 1);

    for bin = 1:n_bins
        curr_mf = operator.interpolation_matrices{bin};

        warp_b = complex(matrix_interpolation(real(image),curr_mf),matrix_interpolation(imag(image),curr_mf));

        % Coil weights
        b_sample = warp_b.*operator.coils;
        % size: nx, ny, nz, ncoils

        % FFT
        b_sample = 1/sqrt(size(b_sample,1))*fftshift(fft(ifftshift( b_sample, 1 ),[],1),1);
        b_sample = 1/sqrt(size(b_sample,2))*fftshift(fft(ifftshift( b_sample, 2 ),[],2),2);
        b_sample = 1/sqrt(size(b_sample,3))*fftshift(fft(ifftshift( b_sample, 3 ),[],3),3);

        % Sampling
        res{bin} = b_sample.*operator.At{bin};
    end
end
