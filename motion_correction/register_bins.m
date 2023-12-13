function displacement_fields = register_bins(k_spaces, sampling_masks, csm)

    n_bins = numel(k_spaces);

    filter_dims = size(k_spaces{1}, 1:3);
    filter_std = 40;

    filter = fspecial3('gaussian', filter_dims, filter_std);

    bin_images = cell(size(k_spaces));
    for bin = 1:n_bins

        filtered_k_space = k_spaces{bin} .* filter;

        bin_image = it_SENSE(filtered_k_space, sampling_masks{bin}, csm);
        bin_images{bin} = Normalize(abs(bin_image), 0, 1);

    end

    reference_image = bin_images{4};



    % NiftiReg likes to run in its own folder
    assert(~isempty(getenv('NIFTY_PATH')), 'You must set NIFTY_PATH environment variable first')
    main_directory = cd(getenv('NIFTY_PATH'));
    go_back = onCleanup(@() cd(main_directory));

    % TODO: it would be nice to structure `displacement_fields` properly,
    % but as it gets passed directly to `Cruz_E_3D_CART_BATCH` I'm leaving
    % it for now
    displacement_fields = nan([size(bin_images{1}, 1:3), 3, numel(bin_images)]);
    for bin = 1:n_bins

        % TODO: this is what the original code does, but `nifty_reg`
        % clearly says it wants the arguments the other way around
        %Normalize(abs(nav_rfm(:,:,:,mmm)),0,1)
        [~, displacement_field] = nifty_reg(Normalize(abs(bin_images{bin}),0,1), Normalize(abs(reference_image),0,1), ' --nmi -be 0.0005 -sx 14', strcat(getenv('WORKSPACE'), '/.nifty-tmp/'));
        displacement_fields(:,:,:,:,bin) = displacement_field;

    end

    displacement_fields = Add_mesh_to_DF(displacement_fields);

end
