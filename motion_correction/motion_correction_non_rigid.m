function data = motion_correction_non_rigid(data, motion_curves, csm, params)

    % TODO: maybe these should be parameters, although Karl intends to
    % force this behaviour for the inline reconstruction

    [n_echoes, n_sets, n_repetitions] = size(data.k_spaces);
    assert(params.ref_bin <= params.n_bins);

    n_contrasts = size(data.sampling_masks);

    data.displacement_fields = cell(n_contrasts);
    data.k_spaces_corrected = cell(n_contrasts);
    data.binned_sampling_masks = cell(n_contrasts);

    % One contrast can be chosen to compute disp fields
    df_contrast = params.selected_contrast_for_disp_fields;
    if df_contrast.echo < 1 || df_contrast.set < 1 || df_contrast.repetition < 1
        df_contrast.echo = -1;
        df_contrast.set = -1;
        df_contrast.repetition = -1;
    end

    for repetition = 1:n_repetitions
        for set = 1:n_sets
            for echo = 1:n_echoes
                fh_motion = motion_curves{echo,set,repetition}.fh;
                included = abs(fh_motion - mean(fh_motion)) <= 2 * std(fh_motion);
                bin_limits = hard_bin_limits(fh_motion(included), params.n_bins);

                % This have to be I unique function I guess?.
                motion.Tx = motion_curves{echo,set,repetition}.fh * 1;
                motion.Ty = -motion_curves{echo,set,repetition}.rl * 1;

                [data.k_spaces_corrected{echo,set,repetition}, data.binned_sampling_masks{echo,set,repetition}] = Focus_binsV2( ...
                    data.k_spaces{echo,set,repetition}, ...
                    data.segment_masks{echo,set,repetition}, ...
                    motion, ...
                    bin_limits);

                % Only compute needed bin images
                if df_contrast.echo ~= -1
                    if df_contrast.echo ~= echo || df_contrast.set ~= set || df_contrast.repetition ~= repetition
                        continue;
                    end
                end

                [weighted_k_spaces, weighted_sampling_masks] = soft_binning( ...
                                data.k_spaces_corrected{echo,set,repetition}, ...
                                data.segment_masks{echo,set,repetition}, ...
                                fh_motion, ...
                                bin_limits, ...
                                params.soft_decay);
                data.bin_images{echo,set,repetition} = reconstruct_bin_images( ...
                    weighted_k_spaces, ...
                    weighted_sampling_masks, ...
                    csm, ...
                    bin_limits, ...
                    motion, ...
                    params);
                data.displacement_fields{echo,set,repetition} = register_bins( ...
                    data.bin_images{echo,set,repetition}, ...
                    params.ref_bin);
            end
        end
    end

    % Point displacement fields to chosen DF
    if df_contrast.echo ~= -1
        for repetition = 1:n_repetitions
            for set = 1:n_sets
                for echo = 1:n_echoes
                    if df_contrast.echo ~= echo || df_contrast.set ~= set || df_contrast.repetition ~= repetition
                        data.displacement_fields{echo,set,repetition} = data.displacement_fields{...
                            df_contrast.echo,...
                            df_contrast.set,...
                            df_contrast.repetition};
                    end
                end
            end
        end
    end

    nbins = size(data.k_spaces_corrected{echo,set,repetition},5);
    interpolationMatrices = cell(1,nbins);
    Image_size            = zeros(size(data.displacement_fields{echo,set,repetition},1), size(data.displacement_fields{echo,set,repetition},2), size(data.displacement_fields{echo,set,repetition},3)); %sizezeros(siz);
    data.interpolation_matrix = cell(size(data.sampling_masks));
    for repetition = 1:n_repetitions
        for set = 1:n_sets
            for echo = 1:n_echoes
                for b = 1:nbins%size(bins_all,1)
                    interpolationMatrices{b} = resampleMatrix(Image_size, data.displacement_fields{echo,set,repetition}(:,:,:,:,b));  %linear interp
                end
                data.interpolation_matrix{echo,set,repetition} = interpolationMatrices;
            end
        end
    end
end