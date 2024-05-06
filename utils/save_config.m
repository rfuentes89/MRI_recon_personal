function save_config(folder, config, verbose)
    if nargin < 3
        verbose = false;
    end
    if ~exist(folder, "dir"), mkdir(folder); end

    txt = jsonencode(config, PrettyPrint=true);

    filename = fullfile(folder, "config.json");
    fid = fopen(filename, "w");
    fprintf(fid, txt);
    fclose(fid);

    if verbose, disp("Saved config to " + filename); end
end
