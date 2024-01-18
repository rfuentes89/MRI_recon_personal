function [kdata_OUT,At_bins] = Focus_binsV2(raw_data,At,motion_info,bins)
% Focus_and_recon takes a list of "bins" locations and corresponding "nav"
% and focuses the "raw_data" onto the average position of each of these.
% Then it reconstructs the cartesian dataset.
% Inputs:       raw_data  - [Nx,Ny,Nz,Ncoils] complex matrix
%               At        - [Nx,Ny,Nz,Nshots] logical sampling matrix
%               nav       - motion_info is a struct with:
%                             -> Tx and Ty (1D real) and RecVoxel (scalar)
%               bins      - [Nbins,2] real vector with [min,max] of each bin

% % Reshape shot information
% AtFE = At;
% if ndims(AtFE )<=3
%     AtFE = repmat(AtFE,[1 1 1 size(raw_data,1)]); 
% end
% AtFE = permute( AtFE,[4 1 2 3]);
% AtFE = sum(AtFE,4);

% Init some vars
nav = motion_info.Tx;

kdata_OUT = zeros(size(raw_data,1),size(raw_data,2),size(raw_data,3),size(raw_data,4),size(bins,1));
At_bins   = zeros(size(At,1),size(At,2),size(At,3),size(bins,1));

% Focus ALL data onto each bin
for bbb = 1:size(bins,1)  
    curr_shots  = nav>=bins{bbb}.lower & nav<bins{bbb}.upper;

    %bin_mean_Tx = (bins{bbb}.lower + bins{bbb}.upper) / 2;
    bin_mean_Tx = mean(motion_info.Tx(curr_shots)); 
    bin_mean_Ty = mean(motion_info.Ty(curr_shots));
    
    bin_motion  = motion_info;
    bin_motion.Tx = -motion_info.Tx+bin_mean_Tx;
    bin_motion.Ty = motion_info.Ty-bin_mean_Ty;
    
    bin_At = At(:,:,:,curr_shots);

    % Andy's fast phase shift
    % TODO(pdpino): check if we should use bin_At instead of At
    % Is showing poor results so far!
    kdata_corr =  translationCorrectionAndy_V3(raw_data, At, bin_motion);
    
    % Push data on bin level
    kdata_OUT(:,:,:,:,bbb) = kdata_corr; % sample_dataV2(kdata_corr, bin_At);
    At_bins(:,:,:,bbb) = sum(bin_At,4);
end
