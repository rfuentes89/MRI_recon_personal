function dfs = niftyreg_chain(bin_images, voxel_size, params)
%NIFTYREG_CHAIN Register images using the "chain" method.
%
% Args:
%     bin_images: cell with n_bins, with arrays of size (nx, ny, nz)
%     params.nifty_params: options passed to reg_f3d script
%     params.tmp_dir: directory to store temporal files
%     params.orientation: one of "ascending", "descending" or "both", see
%         explanation below.
%
% Explanation: computes displacement fields (DFs) between all pair
% combination of bin images, using the "chain" method explained here:
%     1. Computes dfs with distance=1: eg. 1-2, 2-3, and so on.
%         - if orientation=ascending, computes 1-2, 2-3, etc.
%         - if orientation=descending, computes 4-3, 3-2, etc.
%         - if orientation=both, computes both
%     2. Computes dfs with distances>1 by composing other two, eg.
%         DF(1, 3) = DF(1, 2) + DF(2, 3)
%         DF(1, 4) = DF(1, 3) + DF(3, 4)
%         and so on.
%         - if orientation=ascending, computes 1-3, 1-4, etc.
%         - if orientation=descending, computes 4-2, 4-1, etc.
%         - if orientation=both, computes all of them
%     3. Computes the rest as inverse DFs, eg.
%         DF(2, 1) = inverse of DF(1, 2)
%         DF(3, 1) = inverse of DF(1, 3)
%         and so on.
%         - if orientation=ascending, computes 2-1, 3-1, etc.
%         - if orientation=descending, computes 1-2, 1-3, etc.
%         - if orientation=both, skips this step
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

    % Helper function
    function compute_df(i_float, i_ref)
        cmd = sprintf("reg_f3d -ref %s -flo %s -res %s -cpp %s %s -omp %d", ...
            build_fpath("bin_%d.nii", i_ref), ...
            build_fpath("bin_%d.nii", i_float), ...
            build_fpath("reg_%d_%d.nii", i_float, i_ref), ...
            build_fpath("cpp_%d_%d.nii", i_float, i_ref), ...
            params.nifty_params, params.n_cores);
        [~, ~] = system(cmd);

        cmd = sprintf("reg_transform -ref %s -disp %s %s -omp %d", ...
            build_fpath("bin_%d.nii", i_ref), ...
            build_fpath("cpp_%d_%d.nii", i_float, i_ref), ...
            build_fpath("df_%d_%d.nii", i_float, i_ref), ...
            params.n_cores);
        [~, ~] = system(cmd);
    end

    % Register 1-2, 2-3, and so on
    for i_bin = 1:n_bins-1
        i_neighbor = i_bin + 1;
        switch params.orientation
            case {"ascending", "asc"}
                compute_df(i_bin, i_neighbor);
            case {"descending", "desc"}
                compute_df(i_neighbor, i_bin);
            otherwise
                compute_df(i_bin, i_neighbor);
                compute_df(i_neighbor, i_bin);
        end
    end

    % Helper function
    function compose_dfs(i_float, i_step, i_ref)
        % Compute deformation field
        cmd = sprintf("reg_transform -ref %s -ref2 %s -comp %s %s %s -omp %d", ...
            build_fpath("bin_%d.nii", i_step), ...
            build_fpath("bin_%d.nii", i_ref), ...
            build_fpath("df_%d_%d.nii", i_float, i_step), ...
            build_fpath("df_%d_%d.nii", i_step, i_ref), ...
            build_fpath("tmp_deform_%d_%d.nii", i_float, i_ref), ...
            params.n_cores);
        [~, ~] = system(cmd);

        % Transform to displacement field
        cmd = sprintf("reg_transform -ref %s -disp %s %s -omp %d", ...
            build_fpath("bin_%d.nii", i_ref), ...
            build_fpath("tmp_deform_%d_%d.nii", i_float, i_ref), ...
            build_fpath("df_%d_%d.nii", i_float, i_ref), ...
            params.n_cores);
        [~, ~] = system(cmd);
    end

    % Compose for cases 1-3, 1-4, etc
    for i_bin_distance = 2:n_bins-1
        for i_bin = 1:n_bins - i_bin_distance
            % Intermediate step will be used to add these two DFs:
            %   i_float -> i_step
            %   i_step -> i_ref
            i_step = i_bin + 1;

            i_other = i_bin + i_bin_distance;
            switch params.orientation
                case {"ascending", "asc"}
                    compose_dfs(i_bin, i_step, i_other);
                case {"descending", "desc"}
                    compose_dfs(i_other, i_step, i_bin);
                otherwise
                    compose_dfs(i_bin, i_step, i_other);
                    compose_dfs(i_other, i_step, i_bin);
            end
        end
    end

    % Helper function
    function invert_df(i_float, i_ref)
        % Compute inverse displacement field
        cmd = sprintf("reg_transform -invNrr %s %s %s -omp %d", ...
            build_fpath("df_%d_%d.nii", i_float, i_ref), ...
            build_fpath("bin_%d.nii", i_ref), ...
            build_fpath("df_%d_%d.nii", i_ref, i_float), ...
            params.n_cores);
        [~, ~] = system(cmd);
    end

    % Invert DFs
    for i_bin = 1:n_bins
        for j_bin = i_bin+1:n_bins
            switch params.orientation
                case {"ascending", "asc"}
                    invert_df(i_bin, j_bin);
                case {"descending", "desc"}
                    invert_df(j_bin, i_bin);
            end
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
    example_df = dfs{2};
    for i_bin = 1:n_bins
        dfs{i_bin,i_bin} = zeros(size(example_df), like=example_df);
    end
end
