function interpolation_matrices = pre_compute_interpolation_matrix(displacement_fields, ref_bin)
%Precompute interpolation matrices from displacement fields
% Args:
%     - displacement_fields: cell of n_contrasts,
%       each with a cell of (n_floating_bins, n_ref_bins),
%       each with an array of size (nx, ny, nz, 3)
    [n_echoes, n_sets, n_repetitions] = size(displacement_fields);
    interpolation_matrices = cell(n_echoes, n_sets, n_repetitions);

    for repetition = 1:n_repetitions
        for set = 1:n_sets
            for echo = 1:n_echoes
                dfs = displacement_fields{echo,set,repetition};

                % Skip if DFs was not calculated for this contrast
                if numel(dfs) == 0, continue; end

                [n_bins, n_ref_bins] = size(dfs);
                assert(n_bins == n_ref_bins);

                matrices = cell(n_bins, 1);
                for i_bin = 1:n_bins
                    df = dfs{i_bin, ref_bin};
                    if numel(df) == 0, continue; end

                    [kx_size, ky_size, kz_size, ~] = size(df);
                    img_size = zeros(kx_size, ky_size, kz_size);

                    deformation_field = displacement_to_deformation(df);
                    matrices{i_bin} = resampleMatrix(img_size, deformation_field);
                end
                interpolation_matrices{echo,set,repetition} = matrices;
            end
        end
    end
end