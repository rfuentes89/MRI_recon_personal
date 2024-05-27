function image = it_SENSE(k_space, sampling_mask, csm)

    n_iter = 3;
    verbose = false;

    % TODO: rewrite these rather than thinly wrapping them
    operator = Cruz_E_3D_CARTESIAN( ...
        sampling_mask, ...
        csm.coil_sensitivity_maps, ...
        size(k_space, 1:3), ... % TODO: should be `data.specified_image_dimensions, ...` ?
        size(k_space, 1:3) ...
    );
    
    result = Cart_itSENSE(k_space, operator, n_iter, verbose);
    image = flip(flip(flip(result, 1), 2), 3);
end

