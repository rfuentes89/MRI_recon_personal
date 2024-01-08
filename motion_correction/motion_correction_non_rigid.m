function data = motion_correction_non_rigid(data, motion_curves, csm, ref_bin_idx)

    % TODO: maybe these should be parameters, although Karl intends to
    % force this behaviour for the inline reconstruction

    [n_echoes, n_sets, n_repetitions] = size(data.k_spaces);
    n_bins = 4;
    assert(ref_bin_idx <= n_bins);

    data.displacement_fields = cell(size(data.sampling_masks));
    data.k_spaces_corrected = cell(size(data.sampling_masks));
    weighted_k_spaces_cell = cell(size(data.sampling_masks));
    weighted_sampling_masks_cell = cell(size(data.sampling_masks));
    
    fh_motion_cell = cell(size(data.sampling_masks));
    bin_limits_cell = cell(size(data.sampling_masks));
    At_bins = cell(size(data.sampling_masks));

    % It wasn't considerated the binning process for each set.
    % Now it should work also for each repetition and echo.
    for repetition = 1:n_repetitions
        for set = 1:n_sets
            for echo = 1:n_echoes
                fh_motion_cell{echo,set,repetition} = motion_curves{echo,set,repetition}.fh;
                included = abs(fh_motion_cell{echo,set,repetition} - mean(fh_motion_cell{echo,set,repetition})) <= 2 * std(fh_motion_cell{echo,set,repetition});
                bin_limits_cell{echo,set,repetition} = hard_bin_limits( ...
                    fh_motion_cell{echo,set,repetition}(included), ...
                    n_bins);
    
                % This have to be I unique function I guess?.
                motion.Tx = motion_curves{echo,set,repetition}.fh * 1;
                motion.Ty = -motion_curves{echo,set,repetition}.rl * 1;

                [data.k_spaces_corrected{echo,set,repetition}, At_bins{echo,set,repetition}] = Focus_binsV2( ...
                    data.k_spaces{echo,set,repetition}, ...
                    data.segment_masks{echo,set,repetition}, ...
                    motion, ...
                    bin_limits_cell{echo,set,repetition});

                [weighted_k_spaces_cell{echo,set,repetition}, weighted_sampling_masks_cell{echo,set,repetition}] = soft_binning( ...
                                data.k_spaces_corrected{echo,set,repetition}, ...
                                data.segment_masks{echo,set,repetition}, ...
                                fh_motion_cell{echo,set,repetition}, ...
                                bin_limits_cell{echo,set,repetition} ...
                                );
                data.displacement_fields{echo,set,repetition} = register_bins( ...
                    weighted_k_spaces_cell{echo,set,repetition}, ...
                    weighted_sampling_masks_cell{echo,set,repetition}, ...
                    csm, ...
                    ref_bin_idx);
            end
        end
    end
    
    selected_echo = 1;

    data.binned_sampling_masks = At_bins;
 
    
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