function [kdata_W,At_W,R] = soft_gating(kdata,At,nav_info,bin,range_tol,decay,soft_mode)
% Applies soft gating both to the foot-head dimension of k-space. 
% Inputs:   kdata             = [Nx,Ny,Nz,Ncoils] raw k-space
%           At                = [Nx,Ny,Nz,Nshots] logical sampling matrix
%           nav_info.Tx       = [Nshots] navigator vector
%           nav_info.RecVoxel = double motion scale factor      
%           bin               = [bin_min,bin_max] int bin limits
%           range_tol         = double extended range for spectral gate
%           soft_mode         = int used to compare with dif gates
%                             = 0 - no gating
%                             = 1 - soft gate
%              
% Outputs:
%               kdata_W = [Nx,Ny,Nz,Ncoils] weighted kspace
%               At_W    = [Nx,Ny,Nz,Ncoils] weighted sampling matrix
%               R       = double undersapling factors

if nargin <= 5
    soft_mode = 0;
end
% display('-------Re-sampling data-------');
tic;

% Scale nav and bin
scale = (nav_info.RecVoxel/size(kdata,1));
nav = nav_info.Tx/scale;
bin = bin/scale;
%bin_1 = bin.lower/scale;
%bin_2 = bin.upper/scale;

range_tol = range_tol/scale;

% Center bin and normalize nav
%mean_bin = (bin_1+bin_2)/2;
mean_bin = (bin(1)+bin(2))/2;
nav_nrm  = abs(nav-mean_bin);

siz   = size(kdata);
gridX = ones([siz(1) siz(2) siz(3)]);
invGrid = abs(max(gridX(:)) - gridX);

At_W = single(zeros(size(At)));

%% Apply weights to sampling operator and data
for sss = 1:size(At,4)
    if (soft_mode ==1)  % soft gate
%         currWeight = ((abs(bin(2)-bin(1))/2)  + range_tol - nav_nrm(sss))/range_tol;
        currWeight = exp(-decay*(nav_nrm(sss) - range_tol)/range_tol);
        % currWeight = currWeight - min(currWeight)*2;
        currWeight = min(max(0,currWeight),1);
        currGrid = currWeight*gridX;
        At_W(:,:,:,sss) = At(:,:,:,sss).*currGrid;
    end
    if (soft_mode == 0 || soft_mode == 1) % normal gate
        if (nav(sss)>= bin(1) && nav(sss)<= bin(2))
            At_W(:,:,:,sss) = At(:,:,:,sss);
        end
    end
end

clear At

R = determine_R(At_W);

At_W = sum(At_W,4);
kdata_W = kdata.*repmat(At_W,[1 1 1 size(kdata,4)]);

end