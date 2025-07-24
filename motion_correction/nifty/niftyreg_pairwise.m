function displacement_fields = niftyreg_pairwise(bin_images, ref_bin, voxel_size, params)
%NIFTYREG_PAIRWISE Register images using the "pairwise" method.
%
% Args:
%     bin_images: cell with n_bins, with arrays of size (nx, ny, nz)
%     ref_bin: one or more bins to use as reference
%     params.nifty_params: options passed to reg_f3d script
%     params.tmp_dir: directory to store temporal files
%
% Explanation: computes displacement fields (DFs) between bin_images,
% using one or more position as reference (as given in ref_bin).
    n_bins = numel(bin_images);
    displacement_fields = cell(n_bins, n_bins);

    % Prepare tmp_dir
    if ~exist(params.tmp_dir, 'dir'), mkdir(params.tmp_dir), end
    build_fpath = @(varargin) convertStringsToChars(fullfile(params.tmp_dir, sprintf(varargin{:})));

    % Save bin images to .nii files
    for i_bin = 1:n_bins
        img = rescale(abs(bin_images{i_bin}), 0, 1);
        save_nii(make_nii(img, voxel_size), build_fpath("bin_%d.nii", i_bin));
    end

    % Register pairs of images
    for i_ref_idx = 1:numel(ref_bin)
        i_ref = ref_bin(i_ref_idx);

        for i_float = 1:n_bins
            if i_float == i_ref
                continue
            end
            % Do registration
            cmd = sprintf("reg_f3d -ref %s -flo %s -res %s -cpp %s %s", ...
                build_fpath("bin_%d.nii", i_ref), ...
                build_fpath("bin_%d.nii", i_float), ...
                build_fpath("reg_%d_%d.nii", i_float, i_ref), ...
                build_fpath("cpp_%d_%d.nii", i_float, i_ref), ...
                params.nifty_params);
            [~, ~] = system(cmd);

            % Get DF from registration
            cmd = sprintf("reg_transform -ref %s -disp %s %s", ...
                build_fpath("bin_%d.nii", i_ref), ...
                build_fpath("cpp_%d_%d.nii", i_float, i_ref), ...
                build_fpath("df_%d_%d.nii", i_float, i_ref));
            [~, ~] = system(cmd);

            % Load DF from file
            nii = load_nii(build_fpath("df_%d_%d.nii", i_float, i_ref));
            df = squeeze(nii.img);
            % size: (image_size, 3)

            displacement_fields{i_float, i_ref} = df;
        end

        % Zero diagonal
        displacement_fields{i_ref, i_ref} = zeros(size(df), like=df);
    end
end
