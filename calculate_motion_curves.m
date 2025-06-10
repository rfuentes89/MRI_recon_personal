%% Generate motion curves, to be used in the recon later
% This script needs to be run with the MATLAB editor (i.e. with GUI enabled)

addpath(genpath("./"));

%% Read parameters from file
% Choose your config file here
config_fname = "configs/base_motion_curves.json";
CONFIG = load_config(config_fname);

%% Prepare filename
motion_curves_folder = fullfile(CONFIG.acq_folder, "motion_curves");
if ~exist(motion_curves_folder, 'dir'), mkdir(motion_curves_folder), end

base_fname = fullfile(motion_curves_folder, CONFIG.name);
motion_curves_file = base_fname + ".mat";

if isfile(motion_curves_file) && ~CONFIG.override
    error("Wont override previous curve named %s", CONFIG.name);
end

%% Read Twix
path_to_twix = find_twix_file(fullfile(CONFIG.acq_folder, "raw", CONFIG.twix_fname));
twix = read_twix(path_to_twix);

%% Read navigators from twix
navigators = read_navigators(twix{end}, CONFIG.selected_contrasts);
sum_of_navigators = sum_navigators(navigators);

%% Choose ROI
if startsWith(CONFIG.name, "scanner")
    fig1 = figure(1);
    roi = get_inav_roi_from_scanner(twix{end}, size(navigators{1}), CONFIG.scanner_params);
    plot_inav_and_roi(sum_of_navigators, roi);
    saveas(fig1, base_fname + "_selection.png");
else
    % Manually select a ROI
    roi = plot_and_select_roi(sum_of_navigators, base_fname);
end

%% Crop ROI from navigators
cropped_navigators = crop_roi(navigators, roi, CONFIG.roi_padding);

%% Calculate motion curves
motion_curves = register_navigators(cropped_navigators);

%% Plot curves and save
fig2 = figure(2);
plot_motion_curves(motion_curves);
saveas(fig2, base_fname + "_curve.png");

%% Save motion curves
save(motion_curves_file, 'motion_curves');
fprintf("Saved motion curves to file %s\n", motion_curves_file);

%% Functions
function plot_inav_and_roi(image, roi)
    imshow(rescale(image, 0, 1));
    hold on;

    rl_length = roi.rl_max - roi.rl_min;
    fh_length = roi.fh_max - roi.fh_min;
    rectangle('Position', [roi.rl_min, roi.fh_min, rl_length, fh_length], 'EdgeColor', 'r', 'LineWidth', 2);
    hold off;
end
