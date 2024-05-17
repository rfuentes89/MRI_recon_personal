function config = clean_config_recon(config)
%CLEAN_RECON_PARAMS Pre-process recon config

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

    % Set contrast to -1 if any of the number is -1
    df_contrast = config.motion_correction_params.selected_contrast_for_disp_fields;
    if df_contrast.echo < 1 || df_contrast.set < 1 || df_contrast.repetition < 1
        config.motion_correction_params.selected_contrast_for_disp_fields.echo = -1;
        config.motion_correction_params.selected_contrast_for_disp_fields.set = -1;
        config.motion_correction_params.selected_contrast_for_disp_fields.repetition = -1;
    end
end

