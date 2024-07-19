function data = pre_compute_interpolation_matrix(data, df_contrast)
%PRE COMPUTE the interpolation matrix from displacement fields

    % Choose selected to compute interpolation matrix
    if df_contrast.echo ~= -1 % Only one contrast is chosen for all DFs
        is_chosen_contrast = @(echo, set, rep) echo == df_contrast.echo && set == df_contrast.set && rep == df_contrast.repetition;
        n_bins = size(data.displacement_fields{df_contrast.echo,df_contrast.set,df_contrast.repetition},5);
    else
        is_chosen_contrast = @(echo, set, rep) true;
        n_bins = size(data.displacement_fields{1},5);
    end
    assert(n_bins > 0, "found zero bin images in selected contrast");
    [n_echoes, n_sets, n_repetitions] = size(data.k_spaces);
    data.interpolation_matrix = cell(n_echoes, n_sets, n_repetitions);
    for repetition = 1:n_repetitions
        for set = 1:n_sets
            for echo = 1:n_echoes
                if ~is_chosen_contrast(echo, set, repetition), continue; end
                % Pre-compute interpolation matrices
                dfs = data.displacement_fields{echo,set,repetition};
                img_size = zeros(size(dfs,1), size(dfs,2), size(dfs,3));
                matrices = cell(1,n_bins);
                for i_bin = 1:n_bins
                    matrices{i_bin} = resampleMatrix(img_size, dfs(:,:,:,:,i_bin));
                end
                data.interpolation_matrix{echo,set,repetition} = matrices;
            end
        end
    end
    % Point interpolation matrix to chosen DF
    if df_contrast.echo ~= -1
        for repetition = 1:n_repetitions
            for set = 1:n_sets
                for echo = 1:n_echoes
                    data.interpolation_matrix{echo,set,repetition} = data.interpolation_matrix{...
                        df_contrast.echo,...
                        df_contrast.set,...
                        df_contrast.repetition};
                end
            end
        end
    end
end