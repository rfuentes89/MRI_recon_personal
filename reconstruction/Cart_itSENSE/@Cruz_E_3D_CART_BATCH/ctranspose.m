function a = ctranspose(a)
    a.adjoint = xor(a.adjoint,1);
end

