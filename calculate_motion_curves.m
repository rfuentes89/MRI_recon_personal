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

%% Manually select a ROI
sum_of_navigators = sum_navigators(navigators);
navigator_roi = plot_and_select_roi(sum_of_navigators, base_fname);

%% Crop ROI from navigators
roi_navigators = crop_roi(navigators, navigator_roi, CONFIG.roi_padding);

%% Calculate motion curves
motion_curves = register_navigators(roi_navigators);

%% Plot curves and save
plot_motion_curves(motion_curves)
saveas(gcf, base_fname + "_curve.png");

%% Save motion curves
save(motion_curves_file, 'motion_curves');
fprintf("Saved motion curves to file %s\n", motion_curves_file);
