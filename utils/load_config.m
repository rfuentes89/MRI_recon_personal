function config = load_config(filename)
    config = readstruct(filename);

    % Add timestamp for future reference
    config.timestamp = string(datetime("now"), "yyyy-MM-dd_HH:mm:ss");

    % Replace env variables
    config.acq_folder = strrep(config.acq_folder, "$WORKSPACE", getenv("WORKSPACE"));
    config.acq_folder = strrep(config.acq_folder, "$ACQ", getenv("ACQ"));
    if isfield(config, "run_name")
        config.run_name = strrep(config.run_name, "$RECON", getenv("RECON"));
    end
end
