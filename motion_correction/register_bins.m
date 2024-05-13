function displacement_fields = register_bins(bin_images, ref_bin_idx)
% REGISTER_BINS Register all bin images to one bin (e.g. expiration)

    n_bins = numel(bin_images);
    assert(ref_bin_idx <= n_bins);
    reference_image = bin_images{ref_bin_idx};



    % NiftiReg likes to run in its own folder
    assert(~isempty(getenv('NIFTY_PATH')), 'You must set NIFTY_PATH environment variable first')
    main_directory = cd(getenv('NIFTY_PATH'));
    go_back = onCleanup(@() cd(main_directory));

    % TODO: it would be nice to structure `displacement_fields` properly,
    % but as it gets passed directly to `Cruz_E_3D_CART_BATCH` I'm leaving
    % it for now
    displacement_fields = nan([size(bin_images{1}, 1:3), 3, numel(bin_images)]);
    for bin = 1:n_bins
        [~, displacement_field] = nifty_reg( ...
            rescale(abs(reference_image),0,1), ...
            rescale(abs(bin_images{bin}),0,1), ...
            ' --nmi -be 0.0005 -sx 14', ...
            fullfile(getenv("WORKSPACE"), ".nifty-tmp"));
        displacement_fields(:,:,:,:,bin) = displacement_field;

    end

    displacement_fields = Add_mesh_to_DF(displacement_fields);

end
