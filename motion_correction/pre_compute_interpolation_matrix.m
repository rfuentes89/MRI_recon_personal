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
                    % About the signs and directions:
                    % - DF from niftyreg represents the deformation
                    % required to transform the reference image to the
                    % floating image; NOT the registration required to
                    % transform the floating image to the reference image
                    % (which might be counter-intuitive). Consider this 2d
                    % example: if DF[3, 4] = (1, 2), it means that the
                    % pixel at (3, 4) in the reference image needs to move
                    % (1, 2) to reach the deformation observed in the
                    % floating image.
                    % - To register the floating image: multiply the
                    % interpolation matrix by the floating image flattened
                    % - To deform the reference image: transpose the
                    % interpolation matrix, normalize making sure each row
                    % adds up to 1, and then multiply by the reference
                    % image flattened
                end
                interpolation_matrices{echo,set,repetition} = matrices;
            end
        end
    end
end