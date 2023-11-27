function data = compress_coils(data, n_compressed_coils)

    ncc = n_compressed_coils;

    [n_echoes, n_sets, n_repetitions] = size(data.k_spaces);

    for repetition = 1:n_repetitions
        for set = 1:n_sets
            for echo = 1:n_echoes

                kData = data.k_spaces{echo,set,repetition};
            
                dim = 1;
                ncalib = 24;
                [sx, sy, sz, Nc] = size(kData);
                % crop calibration data
                calib = crop(kData, [sx, min(sy, ncalib), min(sz, ncalib), Nc]);
                eccmtx = calcECCMtx(calib, dim, ncc);
                % crop and align matrices
                eccmtx_aligned = alignCCMtx(eccmtx(:,1:ncc,:));
                ECCDATA_aligned = CC(kData, eccmtx_aligned, dim);
                kData = ECCDATA_aligned;
            
                data.k_spaces{echo,set,repetition} = kData;

            end
        end
    end

end

