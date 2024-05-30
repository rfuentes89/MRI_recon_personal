function data = motion_correction_non_rigid(data, motion_curves, csm, params)

    % TODO: maybe these should be parameters, although Karl intends to
    % force this behaviour for the inline reconstruction

    [n_echoes, n_sets, n_repetitions] = size(data.k_spaces);

    n_contrasts = size(data.sampling_masks);
    data.displacement_fields = cell(n_contrasts);
    data.k_spaces_corrected = cell(n_contrasts);
    data.binned_sampling_masks = cell(n_contrasts);

    % Chosen contrast to compute displacement fields
    df_contrast = params.selected_contrast_for_disp_fields;

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
                    bin_limits, ...
                    params.intrabin_TL_corr);

                % Skip computing not-needed bin images
                if df_contrast.echo ~= -1
                    if df_contrast.echo ~= echo || df_contrast.set ~= set || df_contrast.repetition ~= repetition
                        continue;
                    end
                end

                [weighted_k_spaces, weighted_sampling_masks, bin_soft_weights] = soft_binning( ...
                                data.k_spaces_corrected{echo,set,repetition}, ...
                                data.segment_masks{echo,set,repetition}, ...
                                fh_motion, ...
                                bin_limits, ...
                                params);
                data.bins_info{echo,set,repetition}.soft_weights = bin_soft_weights;
                data.bins_info{echo,set,repetition}.limits = bin_limits;

                data.bin_images{echo,set,repetition} = reconstruct_bin_images( ...
                    weighted_k_spaces, ...
                    weighted_sampling_masks, ...
                    csm, ...
                    bin_limits, ...
                    motion, ...
                    params);

                if params.bin_denoise
                    data.bin_images{echo,set,repetition} = denoising_HD_PROST( ...
                        data.bin_images{echo,set,repetition}, ...
                        params.bin_prost_params);
                end
            end
        end
    end
end