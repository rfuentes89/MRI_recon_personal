function arrays = fix_nan_and_inf(arrays)
%FIX_NAN_AND_INF Replaces NaNs and inf values by zero
%   Arguments:
%       arrays: cell with arrays of any size
    for i_array = 1:numel(arrays)
        array = arrays{i_array};
        count_nan = sum(isnan(array(:)));
        count_inf = sum(isinf(array(:)));
        if count_nan > 0 || count_inf > 0
            total = numel(array);
            warning("nan/inf in array %d:\n\tNaN: %d (%.2f%%), INF: %d (%.2f%%), total: %d", ...
                i_array, ...
                count_nan, count_nan / total * 100, ...
                count_inf, count_inf / total * 100, ...
                total);
            arrays{i_array}(isnan(array)) = 0;
            arrays{i_array}(isinf(array)) = 0;
        end
    end
end

