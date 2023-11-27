function csm = coil_sensitivity_SOS(k_space)  
    coil_images = ktoi(k_space, 1:3);
    ssqcoil = sqrt(sum(abs(coil_images) .^ 2, 4));
    csm = coil_images ./ ssqcoil;
end