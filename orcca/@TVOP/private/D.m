function res = D(image)

%
% res = D(image)
%
% image = a 2D image
%
% This function computes the finite difference transform of the image
%
% Related functions:
%       adjD , invD 
%
%
% (c) Michael Lustig 2005
% 
% [sx,sy] = size(image);
% 
% Dx = image([2:end,end],:) - image;
% Dy = image(:,[2:end,end]) - image;
% 
% %res = [sum(image(:))/sqrt(sx*sy); Dx(:);  Dy(:)]; 
% res = cat(3,Dx,Dy);

% % Cruz version
% % image is a (ny,nx,nt) matrix in image space or (ny,nx,nt,nc) in k-space
% % res is a [ny,nx,nt,2] in image or [ny,nx,nt,nc,2]
% [ny,nx,nt] = size(image);

% quick fix to work with batch % "image" is 3D (NY,NX,NZ)
% if ndims(image)==3 && size(image,2)==size(image,3)
if ndims(image)==3 && size(image,3)>50
    Dx = image([2:end,end],:,:) - image(:,:,:);
    Dy = image(:,[2:end,end],:) - image(:,:,:);
    Dz = image(:,:,[2:end,end]) - image(:,:,:);
    res = cat(4,Dx,Dy,Dz);

elseif ndims(image)==2 %#ok<*ISMAT> % 
    Dx = image([2:end,end],:) - image(:,:);
    Dy = image(:,[2:end,end]) - image(:,:);
    res = cat(3,Dx,Dy);
    
elseif ndims(image)==3 % "image" is 2D (NY,NX,Nbins)
    Dx = image([2:end,end],:,:) - image(:,:,:);
    Dy = image(:,[2:end,end],:) - image(:,:,:);
    res = cat(4,Dx,Dy);
    
elseif ndims(image)==4 % "image" is 3D (NY,NX,NZ,Nbins)
    Dx = image([2:end,end],:,:,:) - image(:,:,:,:);
    Dy = image(:,[2:end,end],:,:) - image(:,:,:,:);
    Dz = image(:,:,[2:end,end],:) - image(:,:,:,:);
    res = cat(5,Dx,Dy,Dz);
end


