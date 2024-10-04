function  res = TC_XMR_MTVi(motion_curve, bin_limits, ref_bin)

% MTV measures temporal total variation on a set of motion corrected 3D
% volumes

res.adjoint = 0;
res.ref_bin = ref_bin;

% Compute mean positions
n_bins = numel(bin_limits);
res.target_pos = cell(n_bins, 1);
for i_bin = 1:n_bins
    curr_shots = motion_curve.fh >= bin_limits{i_bin}.lower & motion_curve.fh < bin_limits{i_bin}.upper;

    res.target_pos{i_bin}.X = mean(motion_curve.fh(curr_shots));
    res.target_pos{i_bin}.Y = mean(motion_curve.rl(curr_shots));
end

res = class(res,'TC_XMR_MTVi');
end
