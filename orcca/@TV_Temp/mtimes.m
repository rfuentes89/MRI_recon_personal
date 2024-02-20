function res = mtimes(a,b)

if a.adjoint
    res = adjDz(b);
else
    if ndims(b)==3 % b is 2D image
        res = b(:,:,[2:end,end]) - b(:,:,:);
    elseif ndims(b)==4 % b is 3D image
        res = b(:,:,:,[2:end,end]) - b(:,:,:,:);
    end
end

function y = adjDz(x)
if ndims(x)==3 % b is 2D image
    y= x(:,:,[1,1:end-1]) - x;
    y(:,:,1) = -x(:,:,1);
    y(:,:,end) = x(:,:,end-1);
elseif ndims(x)==4 % b is 3D image
    y= x(:,:,:,[1,1:end-1]) - x(:,:,:,:);
    y(:,:,:,1) = -x(:,:,:,1);
    y(:,:,:,end) = x(:,:,:,end-1);
end