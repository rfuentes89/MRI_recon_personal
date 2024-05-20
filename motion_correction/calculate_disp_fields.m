function data = calculate_disp_fields(data, df_contrast, ref_bin)
%CALCULATE_DISP_FIELDS Calculate non-rigid displacement fields from
%bin_images
    assert(isfield(data, "bin_images"), ...
        "bin_images not present, check selected_contrast_for_disp_fields is correct")

    n_bins = numel(data.bin_images{df_contrast.echo,df_contrast.set,df_contrast.repetition});
    assert(n_bins > 0, "found zero bin images in selected contrast");
    assert(ref_bin <= n_bins, "refbin=%d cannot be higher than n_bins=%d", ref_bin, n_bins);

    [n_echoes, n_sets, n_repetitions] = size(data.k_spaces);

    % Choose selected to compute disp fields
    if df_contrast.echo ~= -1
        is_chosen_contrast = @(echo, set, rep) echo == df_contrast.echo && set == df_contrast.set && rep == df_contrast.repetition;
    else
        is_chosen_contrast = @(echo, set, rep) true;
    end

    % Calculate displacement fields
    data.displacement_fields = cell(n_echoes, n_sets, n_repetitions);
    for repetition = 1:n_repetitions
        for set = 1:n_sets
            for echo = 1:n_echoes
                if is_chosen_contrast(echo, set, repetition)
                    data.displacement_fields{echo,set,repetition} = register_bins( ...
                        data.bin_images{echo,set,repetition}, ...
                        ref_bin);
                end
            end
        end
    end

    % Point displacement fields to chosen DF
    if df_contrast.echo ~= -1
        for repetition = 1:n_repetitions
            for set = 1:n_sets
                for echo = 1:n_echoes
                    data.displacement_fields{echo,set,repetition} = data.displacement_fields{...
                        df_contrast.echo,...
                        df_contrast.set,...
                        df_contrast.repetition};
                end
            end
        end
    end

    % Pre-calculate interpolation matrices
    df = data.displacement_fields{1};
    img_size = zeros(size(df,1), size(df,2), size(df,3));

    data.interpolation_matrix = cell(size(data.sampling_masks));
    for repetition = 1:n_repetitions
        for set = 1:n_sets
            for echo = 1:n_echoes
                matrices = cell(1,n_bins);
                for i_bin = 1:n_bins
                    matrices{i_bin} = resampleMatrix( ...
                        img_size, data.displacement_fields{echo,set,repetition}(:,:,:,:,i_bin));
                end
                data.interpolation_matrix{echo,set,repetition} = matrices;
            end
        end
    end
end
