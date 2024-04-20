%%% Plot soft gating weights
% This script is intended to run with the main recon script in the MATLAB
% editor in debugging mode
%
% Steps:
% 1. Run the main recon script until right before the correct_motion step
% 2. Run the correct_motion function in this script once
% 3. Plot the weights
% 4. If needed, change the soft_binning() params in this script and plot
%    the weights again

%% Run motion correction
% Change parameters as needed
%CONFIG.motion_correction_params.n_bins = 8;
CONFIG.motion_correction_params.bin_recon_type = "it_sense"; % faster than orcca
CONFIG.motion_correction_params.intrabin_TL_corr = false; % faster
motion_corrected_data = correct_motion(data, motion_curves, csm, CONFIG.motion_correction_params);

% Choose contrast
i_contrast = 1;
bins_info = motion_corrected_data.bins_info{i_contrast};

disp("Finished correct_motion");

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


%% Util plot functions
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

        limits = bins_info.limits{i_bin};

        plot_vline(x_range, sorted_fh_motion, limits.lower);
        plot_vline(x_range, sorted_fh_motion, limits.upper);

        bin_center = (limits.upper + limits.lower)/2;
        x_text = x_range(find_idx(sorted_fh_motion, bin_center));
        text(x_text, 1.05, string(i_bin), 'HorizontalAlignment', 'center');
    end
    legend();
    ylabel("soft gating weight");
    ylim([0 1.1])

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
    xline(x_range(find_idx(target_array, value)), '--black','HandleVisibility','off');
end

function value_idx = find_idx(target_array, value)
    value_idx = find(target_array > value, 1);
    if isempty(value_idx), value_idx = length(target_array); end
end
