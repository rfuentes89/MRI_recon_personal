function include_CREAM_PDFF(path)

    % one of the libraries in CREAM_PDFF defines a function called
    % `assert`, so including all paths in CREAM_PDFF without removing the
    % path to this function fires off a warning

    all_paths = genpath(path);
    guilty_path = fullfile(path, "hernando", "matlab_bgl", "test");
    addpath(erase(all_paths, guilty_path))

end

