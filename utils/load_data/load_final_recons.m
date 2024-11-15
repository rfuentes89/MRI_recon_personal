function images = load_final_recons(acq_folder, run_name, contrast_name)
% Loads final recons for a given run
    dcm_folder = fullfile(acq_folder, "recons", run_name, "dcm");
    prefix = fullfile(dcm_folder, contrast_name + "_refpos*.dcm");
    fpaths = dir(prefix);
    fpaths = arrayfun(@(info) fullfile(info.folder, info.name), fpaths, "UniformOutput", false);
    fpaths = sort(fpaths);

    assert(numel(fpaths) > 0, "Found zero final recons with prefix: %s", prefix);

    images = cell(numel(fpaths), 1);
    for i_fpath = 1:numel(fpaths)
        fpath = fpaths{i_fpath};
        images{i_fpath} = double(squeeze(dicomread(fpath)));
    end
end

