function csm = coil_sensitivity_WALSH(k_space)

    smoothing = 51;

    image = ktoi(k_space, 1:3);
    csm = ismrm_estimate_csm_walsh_3D(image, smoothing, size(image, 3));

end