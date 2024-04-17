%%% Plot soft gating weights
% This script is intended to run with the main recon script in the MATLAB
% editor in debugging mode
%
% Steps:
% 1. Run the main recon script until right before the correct_motion step
% 2. Run this full script to correct the motion and plot the weights
% 3. If needed, run the soft_binning() in this script changing the
%    parameters and plot the weights again

%% Run motion correction with it-sense (faster than orcca)
CONFIG.motion_correction_params.bin_recon_type = "it_sense";
motion_corrected_data = correct_motion(data, motion_curves, csm, CONFIG.motion_correction_params);

%% Choose contrast (only once)
i_contrast = 1;
bins_info = motion_corrected_data.bins_info{i_contrast};

%% Run soft gating again (to try different params)
% re-run this as needed

% Change parameters as needed
CONFIG.motion_correction_params.soft_decay = 1;
CONFIG.motion_correction_params.soft_fn = "bin_range";

% Run soft_binning
[~, ~, bins_info.soft_weights] = soft_binning( ...
    motion_corrected_data.k_spaces_corrected{i_contrast}, ...
    motion_corrected_data.segment_masks{i_contrast}, ...
    motion_curves{i_contrast}.fh, ...
    bins_info.limits, ...
    CONFIG.motion_correction_params);

disp("Finished soft_binning");

%% Plot soft weights
figure('position', [300, 300, 1600, 500]);
fh_motion = motion_curves{i_contrast}.fh;

subplot(1,2,1);
plot_weights(fh_motion, bins_info, CONFIG.motion_correction_params, false);

subplot(1,2,2);
plot_weights(fh_motion, bins_info, CONFIG.motion_correction_params, true);


%% Util function
function plot_weights(fh_motion, bins_info, used_params, plot_resp_positions)
    n_bins = length(bins_info.soft_weights);

    [sorted_fh_motion, sorted_fh_idx] = sort(fh_motion);
    if plot_resp_positions
        x_range = sorted_fh_motion;
    else
        x_range = 1:length(bins_info.soft_weights{1});
    end

    hold on

    for i_bin = 1:n_bins
        ws = bins_info.soft_weights{i_bin}(sorted_fh_idx);
        plot(x_range, ws, 'DisplayName', "bin " + string(i_bin))

        plot_vline(x_range, sorted_fh_motion, bins_info.limits{i_bin}.lower);
        plot_vline(x_range, sorted_fh_motion, bins_info.limits{i_bin}.upper);
    end
    legend();
    ylabel("soft gating weight");
    ylim([0 1.05])

    decay = string(used_params.soft_decay);
    method = string(used_params.soft_fn);
    title( ...
        "Soft gating weights (" + string(n_bins) + " bins, decay=" + decay + ", " + method + ")",...
        "Interpreter", "none")

    if plot_resp_positions
        xlabel("data sorted by respiratory position");
    else
        xlabel("data sorted by bin");
    end

    hold off
end

function plot_vline(x_range, target_array, value)
    value_idx = find(target_array > value, 1);
    if isempty(value_idx), value_idx = length(target_array); end
    xline(x_range(value_idx), '--black','HandleVisibility','off');
end
