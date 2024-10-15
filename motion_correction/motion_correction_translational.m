function data = motion_correction_translational(data, motion_curves)
    [n_echoes, n_sets, n_repetitions] = size(data.k_spaces);

    for repetition = 1:n_repetitions
        for set = 1:n_sets
            for echo = 1:n_echoes

                % TODO(pdpino): check signs are consistent with non-rigid
                % TODO(pdpino): do we need to subtract the mean here?
                motion.fh = motion_curves{echo,set,repetition}.fh * -1;
                motion.rl = motion_curves{echo,set,repetition}.rl * -1;

                corrected = translationCorrectionAndy_V3( ...
                    data.k_spaces{echo,set,repetition}, ...
                    data.segment_masks{echo,set,repetition}, ...
                    motion);

                data.k_spaces{echo,set,repetition} = corrected .* data.sampling_masks{echo,set,repetition};

            end
        end
    end

end

