function data = calculate_disp_fields(data, df_contrast, ref_bin)
%CALCULATE_DISP_FIELDS Calculate non-rigid displacement fields from
%bin_images
    assert(isfield(data, "bin_images"), ...
        "bin_images not present, check selected_contrast_for_disp_fields is correct")

    n_bins = numel(data.bin_images{df_contrast.echo,df_contrast.set,df_contrast.repetition});
    assert(n_bins > 0, "found zero bin images in selected contrast");
    assert(ref_bin <= n_bins, "refbin=%d cannot be higher than n_bins=%d", ref_bin, n_bins);

    [n_echoes, n_sets, n_repetitions] = size(data.k_spaces);

    % Choose selected to compute disp fields
    if df_contrast.echo ~= -1
        is_chosen_contrast = @(echo, set, rep) echo == df_contrast.echo && set == df_contrast.set && rep == df_contrast.repetition;
    else
        is_chosen_contrast = @(echo, set, rep) true;
    end

    % Calculate displacement fields (and interpolation matrices)
    data.displacement_fields = cell(n_echoes, n_sets, n_repetitions);
    data.interpolation_matrix = cell(n_echoes, n_sets, n_repetitions);
    for repetition = 1:n_repetitions
        for set = 1:n_sets
            for echo = 1:n_echoes
                if ~is_chosen_contrast(echo, set, repetition), continue; end

                % Calculate displacement fields
                dfs = register_bins(data.bin_images{echo,set,repetition}, ref_bin);
                dfs = post_process_dfs( ...
                    dfs, ...
                    size(data.k_spaces_corrected{echo, set, repetition}, 1:3));
                data.displacement_fields{echo,set,repetition} = dfs;

                % Pre-compute interpolation matrices
                img_size = zeros(size(dfs,1), size(dfs,2), size(dfs,3));
                matrices = cell(1,n_bins);
                for i_bin = 1:n_bins
                    matrices{i_bin} = resampleMatrix(img_size, dfs(:,:,:,:,i_bin));
                end
                data.interpolation_matrix{echo,set,repetition} = matrices;
            end
        end
    end

    % Point displacement fields to chosen DF
    if df_contrast.echo ~= -1
        for repetition = 1:n_repetitions
            for set = 1:n_sets
                for echo = 1:n_echoes
                    data.displacement_fields{echo,set,repetition} = data.displacement_fields{...
                        df_contrast.echo,...
                        df_contrast.set,...
                        df_contrast.repetition};

                    data.interpolation_matrix{echo,set,repetition} = data.interpolation_matrix{...
                        df_contrast.echo,...
                        df_contrast.set,...
                        df_contrast.repetition};
                end
            end
        end
    end
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
    dfs = Add_mesh_to_DF(dfs);
end
