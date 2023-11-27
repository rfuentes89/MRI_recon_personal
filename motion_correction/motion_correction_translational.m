function data = motion_correction_translational(data, motion_curves)

    % TODO: handle the case that the user chooses to reconstruct more than
    % one echo of the navigator, and would not like to use the first one
    % for the correction
    selected_echo = 1;

    [n_echoes, n_sets, n_repetitions] = size(data.k_spaces);

    for repetition = 1:n_repetitions
        for set = 1:n_sets
            for echo = 1:n_echoes
                
                % seems wrong but who am I to judge
                motion.Tx = motion_curves{selected_echo,set,repetition}.fh * -1;
                motion.Ty = motion_curves{selected_echo,set,repetition}.rl * -1; % TODO: check this is correct
        
                corrected = translationCorrectionAndy_V3( ...
                    data.k_spaces{echo,set,repetition}, ...
                    data.segment_masks{echo,set,repetition}, ... % 4th dimension is (should be) segments (I think)
                    motion ... % expects a struct containing two arrays of displacement at each segment, named Tx and Ty
                );

                data.k_spaces{echo,set,repetition} = corrected .* data.sampling_masks{echo,set,repetition};

            end
        end
    end

end

