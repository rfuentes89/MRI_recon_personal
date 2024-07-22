function interpolation_matrices = pre_compute_interpolation_matrix(displacement_fields)
%Precompute interpolation matrices from displacement fields
% Args:
%       - displacement_fields: cell of n_contrasts, each with a DF of size (kx, ky, kz, 3, n_bins)
    [n_echoes, n_sets, n_repetitions] = size(displacement_fields);
    interpolation_matrices = cell(n_echoes, n_sets, n_repetitions);

    for repetition = 1:n_repetitions
        for set = 1:n_sets
            for echo = 1:n_echoes
                dfs = displacement_fields{echo,set,repetition};

                % Skip if DFs was not calculated for this contrast
                if numel(dfs) == 0, continue; end

                [kx_size, ky_size, kz_size, dims3, n_bins] = size(dfs);
                img_size = zeros(kx_size, ky_size, kz_size);
                matrices = cell(1,n_bins);
                for i_bin = 1:n_bins
                    matrices{i_bin} = resampleMatrix(img_size, dfs(:,:,:,:,i_bin));
                end
                interpolation_matrices{echo,set,repetition} = matrices;
            end
        end
    end
end