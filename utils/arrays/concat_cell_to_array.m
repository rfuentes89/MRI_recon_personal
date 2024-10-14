function array = concat_cell_to_array(cell_of_arrays)
% Concatenates a cell of arrays, adding a new dimension at the end.
    next_dim = ndims(cell_of_arrays{1}) + 1;
    array = cat(next_dim, cell_of_arrays{:});
end