%%% Plot soft gating weights

%% Imports
addpath(genpath("./"));

%% Config
CONFIG.acq_folder = fullfile(getenv("WORKSPACE"), "acquisitions/2024-07-04_FE_CMRA");
CONFIG.motion_curve_name = "inav-diaphragm";
CONFIG.n_bins = 4;
CONFIG.i_contrast = 1;

%% Load motion curve
curve_fname = fullfile(CONFIG.acq_folder, "motion_curves", CONFIG.motion_curve_name + ".mat");
assert(isfile(curve_fname), "motion curves not found: %s", curve_fname);
load(curve_fname, 'motion_curves');

%plot_motion_curves(motion_curves);
disp("Curves loaded");

%% Calculate bin limits
% NOTE: copied from motion_correction_non_rigid
fh_motion = motion_curves{CONFIG.i_contrast}.fh;
included = abs(fh_motion - mean(fh_motion)) <= 2 * std(fh_motion);
bin_limits = hard_bin_limits(fh_motion(included), CONFIG.n_bins);

%% Run soft gating
% Change parameters as needed
params.soft_decay = 0.5;
params.soft_fn = "bin_range_scaled";

[~, ~, soft_weights] = soft_binning( ...
    zeros(10, 10, 10, 10, CONFIG.n_bins), ... % dummy k space
    zeros(10, 10, 10, numel(fh_motion)), ... % dummy masks
    fh_motion, ...
    bin_limits, ...
    params);

disp("Finished soft_binning");

%% Plot soft weights
figure('position', [300, 300, 1600, 500]);
subplot(1,2,1);
plot_weights(fh_motion, soft_weights, bin_limits, params, false);

subplot(1,2,2);
plot_weights(fh_motion, soft_weights, bin_limits, params, true);


%% Util plot functions
function plot_weights(fh_motion, soft_weights, bin_limits, used_params, plot_resp_positions)
    n_bins = length(soft_weights);

    [sorted_fh_motion, sorted_fh_idx] = sort(fh_motion);
    if plot_resp_positions
        x_range = sorted_fh_motion;
    else
        x_range = 1:length(soft_weights{1});
    end

    hold on

    for i_bin = 1:n_bins
        ws = soft_weights{i_bin}(sorted_fh_idx);
        plot(x_range, ws, 'DisplayName', "bin " + string(i_bin))

        limits = bin_limits{i_bin};

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
