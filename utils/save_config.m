function save_config(folder, config)
    if ~exist(folder, "dir"), mkdir(folder); end

    txt = jsonencode(config);

    filename = fullfile(folder, "config.json");
    fid = fopen(filename, "w");
    fprintf(fid, txt);
    fclose(fid);
    disp("Saved config to " + filename);
end
