function displacement_fields = calculate_disp_fields(data, ref_bin, registration_params)
%CALCULATE_DISP_FIELDS Calculate non-rigid displacement fields from
%bin_images
    assert(isfield(data, "bin_images"), ...
        "bin_images not present in data, " + ...
        "check motion_correction_params.type is non_rigid");

    [n_echoes, n_sets, n_repetitions] = size(data.bin_images);
    displacement_fields = cell(n_echoes, n_sets, n_repetitions);
    for repetition = 1:n_repetitions
        for set = 1:n_sets
            for echo = 1:n_echoes
                % Skip computation if bin images are not present
                n_bins = numel(data.bin_images{echo,set,repetition});
                if n_bins == 0, continue; end
                assert(ref_bin <= n_bins, "refbin=%d cannot be higher than n_bins=%d", ref_bin, n_bins);

                % Calculate displacement fields
                dfs = register_bins(data.bin_images{echo,set,repetition}, ref_bin, registration_params);
                dfs = post_process_dfs(dfs, data.padded_dimensions);

                assert(all(size(dfs) == [data.padded_dimensions 3 n_bins]));
                displacement_fields{echo,set,repetition} = dfs;
            end
        end
    end

    assert(exist("dfs", "var"), "no bin images found, check selected_contrast_for_disp_fields is correct");
end

function dfs = post_process_dfs(dfs, original_size)
% POST_PROCESS_DFS Apply several post-processing to raw DFs
    % DFs need to be flipped for recon to work. Details:
    % - kspace from scanner comes flipped, i.e. in the "wrong-orientation"
    % - bin images are reconstructed from the wrong-orientation kspace
    %   and then flipped to be in the correct-orientation
    %   (see it_SENSE() and orcca() functions)
    % - thus, DFs are calculated in the correct-orientation
    % - then in the NR recon, DFs need to be in the wrong-orientation
    %   to be multiplied with the original wrong-oriented kspace
    % TODO(pdpino): fix this? idea: flipping once at the beginning?
    dfs = flip(flip(flip(dfs, 1), 2), 3);


    % Interpolate to correct resolution.
    % bin_images can optionally be reduced in dimension (see
    % motion_correct_non_rigid() function). Here DFs need to be resized to
    % the original resolution.
    df_size = size(dfs, 1:3);
    if any(original_size ~= df_size)
        % AFAIK imresize3() cannot be called with extra dimensions,
        % so we need to loop over extra dimensions
        n_dims = 3;
        n_bins = size(dfs, 5);
        resized_df = zeros([original_size, n_dims, n_bins]);
        for i_dim = 1:n_dims
            pixel_factor = original_size(i_dim) / df_size(i_dim);
            for i_bin = 1:n_bins
                scaled_df = dfs(:,:,:,i_dim,i_bin) * pixel_factor;
                resized_df(:,:,:,i_dim,i_bin) = imresize3(scaled_df, original_size);
            end
        end
        dfs = resized_df;
    end


    % Operation needed for interp-matrices to work
    dfs = displacement_to_deformation(dfs);
end
