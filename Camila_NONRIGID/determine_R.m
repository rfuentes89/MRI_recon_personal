function [R] = determine_R(At)
% determines the effective undersampling factor for a given sampling mask

% Inputs:   At: [Nx,Ny,Nz,Nshots] matrix

At = sum(At,4);
R = sum(At(:))./numel(At);


end
