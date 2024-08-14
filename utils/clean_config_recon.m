function config = clean_config_recon(config)
%CLEAN_RECON_PARAMS Pre-process recon config
    % Backward compatibility
    if ~isfield(config, 'save_images'), config.save_images = false; end
    if ~isfield(config, 'save_stdout'), config.save_stdout = false; end
    if ~isfield(config, 'debug_ksize'), config.debug_ksize = 0; end
    if ~isfield(config, 'bins_only'), config.bins_only = false; end
    if ~isfield(config.motion_curve, 'zero_rl'), config.motion_curve.zero_rl = true; end
    if ~isfield(config.motion_curve, 'zero_fh'), config.motion_curve.zero_fh = false; end
    if ~isfield(config.motion_correction_params, 'load_disp_fields'), config.motion_correction_params.load_disp_fields = ""; end
    if ~isfield(config.coil_params, 'csm_params'), config.coil_params.csm_params = struct(bart_params="-r 20 -k 5 -c 0 -S"); end

    % Add _BINSONLY for runs with bins_only set
    if config.debug_ksize > 0
        config.run_name = string(config.run_name) + "_BINSONLY";
    end

    % Add _DEBUG for runs with debug_ksize set
    if config.debug_ksize > 0
        config.run_name = string(config.run_name) + "_DEBUG";
    end

    % Add datestamp to run_name
    if isfield(config, "run_name_prepend_datestamp") && config.run_name_prepend_datestamp
        config.run_name = string(datetime("now"), "yyyy-MM-dd") + "_" + config.run_name;
    end

    % Set run_folder to use later
    config.run_folder = fullfile(config.acq_folder, "recons", config.run_name);

    % Handle null scanner_dcms
    if anymissing(config.seq_params.scanner_dcms) || (numel(config.seq_params.scanner_dcms) ~= numel(config.seq_params.contrast_names))
        config.seq_params.scanner_dcms = strings(numel(config.seq_params.contrast_names), 1);
    end

    % Null black-blood if any child is null
    bb = config.seq_params.bb;
    if isstruct(bb)
        if ismissing(bb.scanner_dcm) || ismissing(bb.contrast_name)
            config.seq_params.bb = false;
        end
    end

    % Set contrast to -1 if any of the number is -1
    df_contrast = config.motion_correction_params.selected_contrast_for_disp_fields;
    if df_contrast.echo < 1 || df_contrast.set < 1 || df_contrast.repetition < 1
        config.motion_correction_params.selected_contrast_for_disp_fields.echo = -1;
        config.motion_correction_params.selected_contrast_for_disp_fields.set = -1;
        config.motion_correction_params.selected_contrast_for_disp_fields.repetition = -1;
    end

    % Check valid ref_bin
    mc_params = config.motion_correction_params;
    assert( ...
        all(mc_params.ref_bin <= mc_params.n_bins), ...
        "ref_bin must be less than n_bins");

    % Parse ref_bin=0
    if any(mc_params.ref_bin < 1) && mc_params.type == "non_rigid"
        config.motion_correction_params.ref_bin = 1:mc_params.n_bins;
    end

    % Warn multiple ref-bins with ORCCA MTV
    mc_params = config.motion_correction_params;
    if numel(mc_params.ref_bin) > 1 && mc_params.bin_recon_type == "orcca" && mc_params.orcca_params.weight_MTV > 0
        warning( ...
            "Reconstructing to >1 ref-bin with ORCCA MTV -- MTV transform will use the first ref-bin %d", ...
            mc_params.ref_bin(1));
    end
end

