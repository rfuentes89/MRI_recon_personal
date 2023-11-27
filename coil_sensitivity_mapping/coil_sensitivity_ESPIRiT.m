function csm = coil_sensitivity_ESPIRiT(k_space)

    % BART toolbox doesn't support Windows

    %bart_libraries = what("bart-0.3.01");
    %setenv('TOOLBOX_PATH', bart_libraries(1).path);

    [calib, ~]  = bart('ecalib -r 20 -k 5 -c 0 -S', k_space);
    csm  = bart('slice 4 0', calib);

end