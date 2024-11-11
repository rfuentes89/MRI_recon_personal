function bin_images = load_bin_images(acq_folder, run_name, contrast_name)
%LOAD_BIN_IMAGES Loads bin images from a previous run
    run_folder = fullfile(acq_folder, "recons", run_name);
    prefix = fullfile(run_folder, "dcm", contrast_name + "-bin");
    fpaths = dir([convertStringsToChars(prefix), '*', '.dcm']);

    assert(numel(fpaths) > 0, "Found zero bin images with prefix: %s", prefix);

    bin_images = cell(length(fpaths), 1);
    for i_fpath = 1:length(fpaths)
        fpath = fpaths(i_fpath);
        fpath = fullfile(fpath.folder, fpath.name);
        bin_images{i_fpath} = rescale(double(squeeze(dicomread(fpath))), 0, 1);
    end
end

