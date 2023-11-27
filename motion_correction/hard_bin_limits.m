function limits = hard_bin_limits(displacements, n_bins)

    small_bin_size = floor(numel(displacements) / n_bins);
    large_bin_size = small_bin_size + 1;

    n_large_bins = mod(numel(displacements), n_bins);
    changeover = large_bin_size * n_large_bins + 1;

    sorted_displacements = sort(displacements);

    boundaries = sorted_displacements([1:large_bin_size:changeover, changeover + small_bin_size:small_bin_size:end, end]);

    % bins are given by all displacements for which lower <= displacement < upper

    limits = arrayfun( ...
        @(l, u) struct("lower", l, "upper", u), ...
        boundaries(1:end - 1), boundaries(2:end), ...
        "UniformOutput", false ...
    );
    
    limits{end}.upper = limits{end}.upper + eps(limits{end}.upper); % otherwise comparison will exclude greatest displacement

end
