function data = interpolate_data(data, motion_curves, new_n_bins, intrabin_TL_corr)
%INTERPOLATE_DATA Prepares data to be used with more bins
%
% Splits data into more bins
% Interpolates displacement fields to more bins

    [n_echoes, n_sets, n_repetitions] = size(data.k_spaces);

    data.k_spaces_corrected = cell(n_echoes, n_sets, n_repetitions);
    data.binned_sampling_masks = cell(n_echoes, n_sets, n_repetitions);

    for repetition = 1:n_repetitions
        for set = 1:n_sets
            for echo = 1:n_echoes
                motion = motion_curves{echo,set,repetition};
                bin_limits = hard_bin_limits(motion.fh, new_n_bins);

                % TODO(pdpino): try merging sampling_masks,
                % binned_sampling_masks and segment_masks into only one
                % variable (after this step, binned_sampling_masks has a
                % different n_bins than the other variables)
                [data.k_spaces_corrected{echo,set,repetition}, data.binned_sampling_masks{echo,set,repetition}] = Focus_binsV2( ...
                    data.k_spaces{echo,set,repetition}, ...
                    data.segment_masks{echo,set,repetition}, ...
                    motion, ...
                    bin_limits, ...
                    intrabin_TL_corr);

                timer_interp = tic();
                data.displacement_fields{echo,set,repetition} = interpolate_dfs(data.displacement_fields{echo, set, repetition}, new_n_bins);
                fprintf("\t\t\t interpolate_dfs() "); toc(timer_interp);
            end
        end
    end
end

