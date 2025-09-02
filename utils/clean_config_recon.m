function config = clean_config_recon(config)
%CLEAN_RECON_PARAMS Pre-process recon config
    config = add_backward_compat_params(config);

    % Add _BINSONLY for runs with bins_only set
    if config.bins_only
        config.run_name = string(config.run_name) + "_BINSONLY";
    end

    % Add _DEBUG for runs with debug_ksize set
    if config.debug_ksize > 0
        config.run_name = string(config.run_name) + "_DEBUG";
        config.override_if_exists = true;
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

    % Complete coils .raw filepath with acq_folder/raw
    if strlength(config.coil_params.csm_params.filename) > 0
        config.coil_params.csm_params.filename = fullfile(config.acq_folder, "raw", config.coil_params.csm_params.filename);
    end

    % Add use_only to csm_params for coil selection to scanner csm.
    config.coil_params.csm_params.use_only = config.coil_params.use_only;
end


function config = add_backward_compat_params(config)
% Add backward compatibility parameters
%
% When new params are added to the base config (i.e. to
% configs/example_recon.json), other users might have old JSON files which
% are missing the new parameters. To avoid breaking those JSON files, a
% default value is initialized here for the new parameters.
    if ~isfield(config, 'save_images'), config.save_images = false; end
    if ~isfield(config, 'save_stdout'), config.save_stdout = false; end
    if ~isfield(config, 'debug_ksize'), config.debug_ksize = 0; end
    if ~isfield(config, 'bins_only'), config.bins_only = false; end
    if ~isfield(config, 'it_sense_params'), config.it_sense_params = struct(); end
    if ~isfield(config.motion_curve, 'zero_rl'), config.motion_curve.zero_rl = true; end
    if ~isfield(config.motion_curve, 'zero_fh'), config.motion_curve.zero_fh = false; end
    if ~isfield(config.motion_curve, 'scanner_params'), config.motion_curve.scanner_params.length_factor = 1; end
    if ~isfield(config.motion_correction_params, 'load_disp_fields'), config.motion_correction_params.load_disp_fields = ""; end
    if ~isfield(config.motion_correction_params, 'divide_dfs_by_resolution'), config.motion_correction_params.divide_dfs_by_resolution = false; end
    if ~isfield(config.motion_correction_params, 'load_bin_images'), config.motion_correction_params.load_bin_images = ""; end
    if ~isfield(config.motion_correction_params, 'registration_params'), config.motion_correction_params.registration_params = struct(); end
    if ~isfield(config.motion_correction_params.registration_params, 'orientation')
        if config.motion_correction_params.registration_params.ascending
            config.motion_correction_params.registration_params.orientation = "ascending";
        else
            config.motion_correction_params.registration_params.orientation = "descending";
        end
    end
    if ~isfield(config.motion_correction_params, 'it_sense_params'), config.motion_correction_params.it_sense_params = struct(); end
    if ~isfield(config.motion_correction_params, 'filter_bin_kspace_gaussian'), config.motion_correction_params.filter_bin_kspace_gaussian = -1; end
    if ~isfield(config.coil_params, 'csm_params'), config.coil_params.csm_params = struct(bart_params="-r 20 -k 5 -c 0 -S", filename=""); end
    if ~isfield(config.coil_params.csm_params, 'filename'), config.coil_params.csm_params.filename = ""; end
    if ~isfield(config.seq_params, 'dixon'), config.seq_params.dixon = false; end
end
