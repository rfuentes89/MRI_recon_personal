function dfs = interpolate_dfs(dfs, new_n_bins, params)
%INTERPOLATE_DFS Interpolate 3D displacement fields to more bins
% Args:
%     dfs: cell of size (n_floating_bins, n_ref_bins), where
%          n_floating_bins = n_ref_bins. Each element is an array with a
%          displacement field of shape (image_size, 3), for example
%          (size_x, size_y, size_z, 3)
%
% Returns: dfs_interpolated
%          cell of size (new_n_bins, new_n_bins), each element with a
%          displacement field of shape (image_size, 3), i.e. same as input.
    % Check input sizes
    if numel(dfs) == 0, return; end
    [n_floating, n_ref] = size(dfs);
    assert(n_floating == n_ref);
    df_size = size(dfs{1});

    % Default params
    if ~exist("params", "var"), params = struct(); end
    params = fill_struct_values(params, struct(method='linear'));

    % Flatten DFs
    lastdim = numel(df_size) + 1;
    dfs_flatten = cat(lastdim, dfs{:}); % size: nx, ny, nz, 3, n_target*n_ref
    dfs_flatten = reshape(dfs_flatten, [df_size, n_floating, n_ref]); % size: nx, ny, nz, 3, n_target, n_ref

    % Permute dimensions (interpolated dims must be first)
    dfs_permuted = permute(dfs_flatten, [lastdim, lastdim + 1, 1:numel(df_size)]); % size: n_target, n_ref, nx, ny, nz, 3

    % Build interpolator
    interp_grid_x = 1:n_floating;
    interp_grid_y = 1:n_ref;
    interp_fn = griddedInterpolant({interp_grid_x, interp_grid_y}, dfs_permuted, params.method);

    % Interpolate
    new_range = calculate_interpolation_range(n_ref, new_n_bins);
    dfs_interp_arr = interp_fn({new_range, new_range}); % size: new_n_bins, new_n_bins, nx, ny, nz, 3

    % Return to original shape as cell
    cell_dim_float = repelem(1, new_n_bins);
    cell_dim_ref = repelem(1, new_n_bins);
    array_dim_spread = num2cell(df_size);
    dfs_interpolated = mat2cell(dfs_interp_arr, cell_dim_float, cell_dim_ref, array_dim_spread{:});
    % size: cell with n_target_new, n_ref_new
    % each with array size: (1, 1, nx, ny, nz, 3)

    % Remove extra 1's dimensions
    dfs_interpolated = cellfun(@(arr) squeeze(arr), dfs_interpolated, 'UniformOutput', false);
    % size: cell with n_target_new, n_ref_new
    % each with array size: (nx, ny, nz, 3)

    dfs = zero_diagonal_dfs(dfs_interpolated);
end

function new_grid = calculate_interpolation_range(n_original, n_target)
% CALCULATE_INTERPOLATION_RANGE Calculates the grid points to interpolate
% from n_original to n_target
%
% See this example to understand the details:
%     Say n_original = 3 and n_target = 6.
%     - For the original 3 bins, the center position of each bin are at
%       [1, 2, 3], so bin 1 goes from 0.5 to 1.5, bin 2 goes from 1.5 to
%       2.5, and bin 3 goes from 2.5 to 3.5.
%     - Then, the full space goes from 0.5 to 3.5
%     - Then, the new 6 bins have size 0.5 each: from 0.5 to 1, from 1 to
%       1.5 and so on.
%     - Then, the new 6 bins are centered at positions
%       [0.75, 1.25, 1.75, 2.25, 2.75, 3.25]

    % Calculate bin borders for new number of bins
    space_min = 0.5;
    space_max = n_original + 0.5;
    n_borders = n_target + 1;
    bin_borders = linspace(space_min, space_max, n_borders);

    % Drop the last border, keep only the start of bins
    bin_starts = bin_borders(1:end-1);

    % Shift positions to return bin centers
    new_bin_size = 0.5 * n_original / n_target;
    new_grid = bin_starts + new_bin_size;
end

function dfs = zero_diagonal_dfs(dfs)
% Zero dfs when i_floating = i_reference
    [n_bins, ~] = size(dfs);
    df_size = size(dfs{1});
    for i_bin = 1:n_bins
        dfs{i_bin, i_bin} = zeros(df_size);
    end
end

