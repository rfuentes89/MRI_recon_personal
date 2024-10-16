function [res] = mtimes(operator,input)

n_coils = size(operator.coils, 4);

if operator.adjoint % EH operation
% input: k_space: array (nx,ny,nz,n_coils)
% returns: image: array(nx, ny, nz)
    k_space = input;

    % Sampling
    b_sample = k_space.*operator.At;

    % 3D FFT
    b_sample = sqrt(size(b_sample,1)).* fftshift( ifft(ifftshift(b_sample ,1),[],1), 1);
    b_sample = sqrt(size(b_sample,2)).* fftshift( ifft(ifftshift(b_sample ,2),[],2), 2);
    b_sample = sqrt(size(b_sample,3)).* fftshift( ifft(ifftshift(b_sample ,3),[],3), 3);

    % Coil weights
    res_coils = b_sample .* conj(operator.coils);

    % Sum over coils
    res = sum(res_coils, 4);

    % Remove nans
    res(isnan(res)) = 0;

else % E operation
% input: image: (nx,ny,nz)
% returns: k_space: array(nx,ny,nz,n_coils)
    image = input;
    image(isnan(image)) = 0;

    % Coil weights
    b_sample = image .* operator.coils;

    % 3D FFT
    b_sample = 1/sqrt(size(b_sample,1))*fftshift(fft(ifftshift( b_sample, 1 ),[],1),1);
    b_sample = 1/sqrt(size(b_sample,2))*fftshift(fft(ifftshift( b_sample, 2 ),[],2),2);
    b_sample = 1/sqrt(size(b_sample,3))*fftshift(fft(ifftshift( b_sample, 3 ),[],3),3);

    % Sampling
    res = b_sample.*operator.At;
end
