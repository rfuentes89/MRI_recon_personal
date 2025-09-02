function displacement_fields = calculate_disp_fields(bin_images, kspace_size, ref_bin, voxel_size, registration_params, divide_by_res)
%CALCULATE_DISP_FIELDS Calculate non-rigid displacement fields from
%bin_images
    [n_echoes, n_sets, n_repetitions] = size(bin_images);
    displacement_fields = cell(n_echoes, n_sets, n_repetitions);
    for repetition = 1:n_repetitions
        for set = 1:n_sets
            for echo = 1:n_echoes
                % Skip computation if bin images are not present
                n_bins = numel(bin_images{echo,set,repetition});
                if n_bins == 0, continue; end

                % Calculate displacement fields
                dfs = register_bins(bin_images{echo,set,repetition}, ref_bin, voxel_size, registration_params);
                % size: n_bins, n_refs

                % Apparently, niftyreg returns the DFs in mm space, but the
                % whole reconstruction process works in pixel space.
                % Note: This is theoretically correct, but in practice it makes
                % the recon worse in most cases, so we use a parameter for now
                if divide_by_res
                    divide_by_voxel_size = reshape(voxel_size, [1, 1, 1, 3]);
                    dfs = cellfun(@(df) df ./ divide_by_voxel_size, dfs, 'UniformOutput', false);
                end

                % Interpolate to back to original size
                dfs = cellfun(@(df) interpolate_df_back(df, kspace_size), dfs, 'UniformOutput', false);
                displacement_fields{echo,set,repetition} = dfs;
            end
        end
    end

    assert(exist("dfs", "var"), "no bin images found, check selected_contrast_for_disp_fields is correct");
end

function df = interpolate_df_back(df, original_size)
% Interpolate DFs back to its original size
    if numel(df) == 0, return; end

    % Interpolate to correct resolution.
    % bin_images can optionally be reduced in dimension (see
    % motion_correct_non_rigid() function). Here DFs need to be resized to
    % the original resolution.
    df_size = size(df, 1:3);
    if any(original_size ~= df_size)
        % AFAIK imresize3() cannot be called with extra dimensions,
        % so we need to loop over extra dimensions
        n_dims = 3;
        resized_df = zeros([original_size, n_dims]);
        for i_dim = 1:n_dims
            pixel_factor = original_size(i_dim) / df_size(i_dim);
            scaled_df = df(:,:,:,i_dim) * pixel_factor;
            resized_df(:,:,:,i_dim) = imresize3(scaled_df, original_size);
        end
        df = resized_df;
    end
end
