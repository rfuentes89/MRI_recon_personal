function cell_of_arrays = split_array_to_cell(array, dummy_dim_at_the_end)
% Splits arrays into a cell by their last dimension
%
% Args:
%     - array: size (dim_1, dim_2, ..., dim_n)
%     - dummy_dim_at_the_end: boolean, whether or not to include a singleton
%       dimension at the end. This is useful when the last dimension is 1,
%       as MATLAB ignores singleton dimensions. See example below
%
% Example:
%     - input: array of size (n_x, n_y, n_z, 8), e.g. 8 contrasts
%              dummy_dim_at_the_end = false
%       output: cell of size 8, each element with an array of size (n_x, n_y, n_z)
%
%     - input: array of size (n_x, n_y, n_z), e.g. 1 contrast
%              dummy_dim_at_the_end = true
%       output: cell of size 1, with an array of size (n_x, n_y, n_z)
%
% Note: using this is much more efficient than slicing,
% since slicing makes copies of the data:
%
%       for i_array = 1:size(array, 4)
%           output_cell{i_array} = array(:,:,:,i_array)
%       end

    if nargin < 2
        dummy_dim_at_the_end = false;
    end

    target_dim = ndims(array);
    if dummy_dim_at_the_end
        target_dim = target_dim + 1;
    end

    % Last dimension to convert to cell
    n_arrays_target = size(array, target_dim);

    % Array dimensions
    array_dim_spread = num2cell(size(array, 1:target_dim-1));

    % Convert to cell of size (1, ..., 1, n_arrays)
    cell_of_arrays = mat2cell(array, array_dim_spread{:}, repelem(1, n_arrays_target));

    % Remove extra singleton dimensions
    cell_of_arrays = squeeze(cell_of_arrays);
end