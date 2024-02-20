function res = adjD(y)

% res = zeros(size(y,1),size(y,2));
% 
% %y1 = ones(imsize)*y(1)/sqrt(prod(imsize));
% %yx = (reshape(y(2:prod(imsize)+1), imsize(1), imsize(2)));
% %yy = (reshape(y(prod(imsize)+2:end), imsize(1), imsize(2)));
% 
% res = adjDx(y(:,:,1)) + adjDy(y(:,:,2));
% 
% return;
% 
% 
% function res = adjDy(x)
% res = x(:,[1,1:end-1]) - x;
% res(:,1) = -x(:,1);
% res(:,end) = x(:,end-1);
% 
% function res = adjDx(x)
% res = x([1,1:end-1],:) - x;
% res(1,:) = -x(1,:);
% res(end,:) = x(end-1,:);

% Cruz version
% 
% [ny,nx,nt] = size(y);

% quick fix to work with batch
% if ndims(y)==4 && size(y,2)==size(y,3)
if ndims(y)==4 && size(y,3)>50
    res = adjDx(y(:,:,:,1)) + adjDy(y(:,:,:,2)) + adjDz(y(:,:,:,3));
    
elseif ndims(y) == 3     %#ok<*ISMAT>
    res = adjDx(y(:,:,1)) + adjDy(y(:,:,2));
    
elseif ndims(y)==4 % y is a 2D image
    res = adjDx(y(:,:,:,1)) + adjDy(y(:,:,:,2));
    
elseif ndims(y)==5 % y is a 3D image
    res = adjDx(y(:,:,:,:,1)) + adjDy(y(:,:,:,:,2)) + adjDz(y(:,:,:,:,3));
end

return;

function res = adjDy(x)
if ndims(x)==2
    res = x(:,[1,1:end-1]) - x(:,:);
    res(:,1) = -x(:,1);
    res(:,end) = x(:,end-1);
elseif ndims(x)==3
    res = x(:,[1,1:end-1],:) - x(:,:,:);
    res(:,1,:) = -x(:,1,:);
    res(:,end,:) = x(:,end-1,:);
elseif ndims(x)==4
    res = x(:,[1,1:end-1],:,:) - x(:,:,:,:);
    res(:,1,:,:) = -x(:,1,:,:);
    res(:,end,:,:) = x(:,end-1,:,:);
end

function res = adjDx(x)
if ndims(x)==2
    res = x([1,1:end-1],:) - x(:,:);
    res(1,:) = -x(1,:);
    res(end,:) = x(end-1,:);
elseif ndims(x)==3
    res = x([1,1:end-1],:,:) - x(:,:,:);
    res(1,:,:) = -x(1,:,:);
    res(end,:,:) = x(end-1,:,:);
elseif ndims(x)==4
    res = x([1,1:end-1],:,:,:) - x(:,:,:,:);
    res(1,:,:,:) = -x(1,:,:,:);
    res(end,:,:,:) = x(end-1,:,:,:);
end

function res = adjDz(x)
if ndims(x)==3
    res = x(:,:,[1,1:end-1]) - x(:,:,:);
    res(:,:,1) = -x(:,:,1);
    res(:,:,end) = x(:,:,end-1);
elseif ndims(x)==4
    res = x(:,:,[1,1:end-1],:) - x(:,:,:,:);
    res(:,:,1,:) = -x(:,:,1,:);
    res(:,:,end,:) = x(:,:,end-1,:);
end
