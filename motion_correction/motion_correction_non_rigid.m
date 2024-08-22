function data = motion_correction_non_rigid(data, motion_curves, csm, params)

    % TODO: maybe these should be parameters, although Karl intends to
    % force this behaviour for the inline reconstruction

    [n_echoes, n_sets, n_repetitions] = size(data.k_spaces);

    n_contrasts = size(data.sampling_masks);
    data.bin_images = cell(n_contrasts);
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

                % Bin images are not needed when loading previous disp fields
                if strlength(params.load_disp_fields) > 0
                    continue;
                end

                [weighted_k_spaces, weighted_sampling_masks, ~] = soft_binning( ...
                                data.k_spaces_corrected{echo,set,repetition}, ...
                                data.segment_masks{echo,set,repetition}, ...
                                fh_motion, ...
                                bin_limits, ...
                                params);

                [reduced_k_spaces, reduced_sampling_masks, reduced_csm] = reduce_resolution( ...
                    weighted_k_spaces, ...
                    weighted_sampling_masks, ...
                    csm, ...
                    params.bin_resolution_factor);

                data.bin_images{echo,set,repetition} = reconstruct_bin_images( ...
                    reduced_k_spaces, ...
                    reduced_sampling_masks, ...
                    reduced_csm, ...
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

function [reduced_k_spaces, reduced_sampling_masks, reduced_csm] = reduce_resolution( ...
    k_spaces, sampling_masks, csm, reduce_factor)
    assert(reduce_factor > 0 && reduce_factor <= 1, ...
        "bin_resolution_factor must be between 0 and 1, got %f", ...
        reduce_factor);
    if reduce_factor == 1
        reduced_k_spaces = k_spaces;
        reduced_sampling_masks = sampling_masks;
        reduced_csm = csm;
        return;
    end

    n_bins = numel(k_spaces);
    [x_size, y_size, z_size, n_coils] = size(k_spaces{1});
    [x_new_size, x_start, x_end] = calculate_new_size(x_size, reduce_factor);
    [y_new_size, y_start, y_end] = calculate_new_size(y_size, reduce_factor);
    [z_new_size, z_start, z_end] = calculate_new_size(z_size, reduce_factor);

    reduced_k_spaces = cell(n_bins, 1);
    reduced_sampling_masks = cell(n_bins, 1);

    n_bins = numel(k_spaces);
    for i_bin = 1:n_bins
        reduced_k_spaces{i_bin} = k_spaces{i_bin}( ...
            x_start:x_end, ...
            y_start:y_end, ...
            z_start:z_end, ...
            :);
        reduced_sampling_masks{i_bin} = sampling_masks{i_bin}( ...
            x_start:x_end, ...
            y_start:y_end, ...
            z_start:z_end);
    end

    reduced_csm = struct();
    reduced_csm.coil_sensitivity_maps = nan(x_new_size, y_new_size, z_new_size, n_coils);
    for i_coil = 1:n_coils
        reduced_csm.coil_sensitivity_maps(:,:,:,i_coil) = imresize3( ...
            csm.coil_sensitivity_maps(:,:,:,i_coil), [x_new_size, y_new_size, z_new_size]);
    end
end

function [new_size, dim_start, dim_end] = calculate_new_size(dim_size, reduce_res_factor)
    new_size = floor(dim_size * reduce_res_factor);
    padding = floor((dim_size - new_size) / 2);
    dim_start = padding;
    dim_end = dim_start + new_size - 1;
end
