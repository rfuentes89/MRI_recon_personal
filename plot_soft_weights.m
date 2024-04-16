%%% Plot soft gating weights
% This script is intended to run with the main recon script in the MATLAB
% editor in debugging mode
%
% Steps:
% 1. Run the main recon script until right before the correct_motion step
% 2. Run the correct_motion in this script (modify params if necessary)
% 3. Plot the weights

%% Run motion correction again
% Change parameters as needed
CONFIG.motion_correction_params.soft_decay = 1; % Test different decay values

% Run motion correction
motion_corrected_data = correct_motion(data, motion_curves, csm, CONFIG.motion_correction_params);


%% Plot soft weights
% Params
i_contrast = 1;
plot_resp_positions = true;

% Plot
bins_info = motion_corrected_data.bins_info{i_contrast};
n_bins = length(bins_info.soft_weights);

[resp_positions, ~] = sort(motion_curves{i_contrast}.fh);

if plot_resp_positions
    x_range = resp_positions;
else
    x_range = 1:length(resp_positions);
end

figure; hold on

for i_bin = 1:n_bins
    [sorted_fh_motion, sorted_idx] = sort(bins_info.fh_motion);
    ws = bins_info.soft_weights{i_bin}(sorted_idx);

    plot(x_range, ws, 'DisplayName', "bin " + string(i_bin))

    lower_limit_idx = find(sorted_fh_motion > bins_info.limits{i_bin}.lower, 1);
    if isempty(lower_limit_idx), lower_limit_idx = 1; end
    xline(x_range(lower_limit_idx), '--black','HandleVisibility','off');

    upper_limit_idx = find(sorted_fh_motion > bins_info.limits{i_bin}.upper, 1);
    if isempty(upper_limit_idx), upper_limit_idx = length(sorted_fh_motion); end
    xline(x_range(upper_limit_idx), '--black','HandleVisibility','off')
end
legend();
ylabel("soft gating weight");
title("Soft gating weights (" + string(n_bins) + " bins, decay=" + string(CONFIG.motion_correction_params.soft_decay) + ")")

if plot_resp_positions
    xlabel("data sorted by respiratory position");
else
    xlabel("data sorted by bin");
end

hold off

