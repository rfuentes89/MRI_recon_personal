function dfs = niftyreg_chain(bin_images, voxel_size, params)
%NIFTYREG_CHAIN Register images using the "chain" method.
%
% Args:
%     bin_images: cell with n_bins, with arrays of size (nx, ny, nz)
%     params.nifty_params: options passed to reg_f3d script
%     params.tmp_dir: directory to store temporal files
%     params.ascending: whether to compute DFs ascending (1-2, 2-3, etc) or
%         descending (4-3, 3-2, etc)
%
% Explanation: computes displacement fields (DFs) between all pair
% combination of bin images, using the "chain" method explained here:
%     1. Computes dfs with distance=1: 1-2, 2-3, and so on
%     2. Computes dfs with distances>1: bins by adding other two, e.g.:
%         - computes 1-3 by adding 1-2 and 1-3
%         - computes 1-4 by adding 1-3 and 3-4
%         - and so on
%     3. Computes the rest as inverse DFs, e.g.:
%         - computes 2-1 as the inverse of 1-2
%         - computes 3-2 as the inverse of 2-3
%         - and so on
    n_bins = numel(bin_images);
    dfs = cell(n_bins, n_bins);

    % Prepare tmp_dir
    if ~exist(params.tmp_dir, 'dir'), mkdir(params.tmp_dir), end
    build_fpath = @(varargin) convertStringsToChars(fullfile(params.tmp_dir, sprintf(varargin{:})));

    % Save bin images to NII
    for i_bin = 1:numel(bin_images)
        img = rescale(abs(bin_images{i_bin}), 0, 1);
        save_nii(make_nii(img, voxel_size), build_fpath("bin_%d.nii", i_bin));
    end

    % Register 1-2, 2-3, and so on
    for i_bin = 1:n_bins-1
        if params.ascending
            i_float = i_bin;
            i_ref = i_bin + 1;
        else
            i_float = i_bin + 1;
            i_ref = i_bin;
        end
        cmd = sprintf("reg_f3d -ref %s -flo %s -res %s -cpp %s %s", ...
            build_fpath("bin_%d.nii", i_ref), ...
            build_fpath("bin_%d.nii", i_float), ...
            build_fpath("reg_%d_%d.nii", i_float, i_ref), ...
            build_fpath("cpp_%d_%d.nii", i_float, i_ref), ...
            params.nifty_params);
        [~, ~] = system(cmd);

        cmd = sprintf("reg_transform -ref %s -disp %s %s", ...
            build_fpath("bin_%d.nii", i_ref), ...
            build_fpath("cpp_%d_%d.nii", i_float, i_ref), ...
            build_fpath("df_%d_%d.nii", i_float, i_ref));
        [~, ~] = system(cmd);
    end

    % Compose for cases 1-3, 1-4, etc
    for i_bin_distance = 2:n_bins-1
        for i_bin = 1:n_bins - i_bin_distance
            if params.ascending
                i_float = i_bin;
                i_ref = i_bin + i_bin_distance;
            else
                i_float = i_bin + i_bin_distance;
                i_ref = i_bin;
            end

            % Intermediate step will be used to add these two DFs:
            %   i_float -> i_step
            %   i_step -> i_ref
            i_step = i_bin + 1;

            % Compute deformation field
            cmd = sprintf("reg_transform -ref %s -ref2 %s -comp %s %s %s", ...
                build_fpath("bin_%d.nii", i_step), ...
                build_fpath("bin_%d.nii", i_ref), ...
                build_fpath("df_%d_%d.nii", i_float, i_step), ...
                build_fpath("df_%d_%d.nii", i_step, i_ref), ...
                build_fpath("tmp_deform_%d_%d.nii", i_float, i_ref));
            [~, ~] = system(cmd);

            % Transform to displacement field
            cmd = sprintf("reg_transform -ref %s -disp %s %s", ...
                build_fpath("bin_%d.nii", i_ref), ...
                build_fpath("tmp_deform_%d_%d.nii", i_float, i_ref), ...
                build_fpath("df_%d_%d.nii", i_float, i_ref));
            [~, ~] = system(cmd);
        end
    end

    % Invert DFs
    for i_bin = 1:n_bins
        for j_bin = i_bin+1:n_bins
            if params.ascending
                i_float = i_bin;
                i_ref = j_bin;
            else
                i_float = j_bin;
                i_ref = i_bin;
            end

            % Compute inverse displacement field
            cmd = sprintf("reg_transform -invNrr %s %s %s", ...
                build_fpath("df_%d_%d.nii", i_float, i_ref), ...
                build_fpath("bin_%d.nii", i_ref), ...
                build_fpath("df_%d_%d.nii", i_ref, i_float));
            [~, ~] = system(cmd);
        end
    end

    % Load DFs from files
    for i_bin = 1:n_bins
        for j_bin = 1:n_bins
            if i_bin == j_bin, continue; end
            nii = load_nii(build_fpath("df_%d_%d.nii", i_bin, j_bin));
            dfs{i_bin,j_bin} = squeeze(nii.img);
        end
    end

    % Zero diagonal
    image_size = size(dfs{2});
    for i_bin = 1:n_bins
        dfs{i_bin,i_bin} = zeros(image_size);
    end
end

