function config = load_config(filename)
    config = readstruct(filename);

    % Add timestamp for future reference
    config.timestamp = string(datetime("now"), "yyyy-MM-dd_HH:mm:ss");

    % Replace WORKSPACE env variable
    config.acq_folder = strrep(config.acq_folder, "$WORKSPACE", getenv("WORKSPACE"));
end
