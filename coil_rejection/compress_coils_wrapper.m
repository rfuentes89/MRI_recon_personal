function k_spaces_compressed = compress_coils_wrapper(k_spaces, n_compressed_coils)
    % COMPRESS_COILS_WRAPPER Applies coil compression to k-space data.
    %
    %   Calls compress_coils for each element of the 'k_spaces' cell
    %   Example:
    %       k_spaces = {kSpace1, kSpace2};
    %       n_compressed_coils = 4;
    %       k_spaces_compressed = compress_coils_wrapper(k_spaces, n_compressed_coils);
    %
    %   This example compresses the coil data in each element of the
    %   'k_spaces' cell array to 4 coils using the `compress_coils`
    %   function.
    %
    %   See also COMPRESS_COILS.

    % Apply the coil compression function to each element in the k_spaces field
    k_spaces_compressed = cellfun(@(k_space) compress_coils(k_space, n_compressed_coils), k_spaces, 'UniformOutput', false);

end
