%% Generate motion curves, to be used in the recon later
% This script needs to be run with the MATLAB editor (i.e. with GUI enabled)

addpath(genpath("./"));

%% Read parameters from file
% Choose your config file here
config_fname = "configs/example_recon.json";

CONFIG = load_config(config_fname);

%% Prepare filename
motion_curves_folder = fullfile(CONFIG.acq_folder, "motion_curves");
if ~exist(motion_curves_folder, 'dir'), mkdir(motion_curves_folder), end

base_fname = fullfile(motion_curves_folder, CONFIG.motion_curve.name);
motion_curves_file = base_fname + ".mat";

if isfile(motion_curves_file) && ~CONFIG.motion_curve.recompute
    warning("Overriding previous curve named %s", CONFIG.motion_curve.name);
end

%% Read Twix
path_to_twix = find_twix_file(fullfile(CONFIG.acq_folder, "raw", CONFIG.twix_fname));
twix = read_twix(path_to_twix);

%% Calculate motion curve
motion_curves = estimate_motion_curves(twix{end}, CONFIG.selected_contrasts, base_fname);

save(motion_curves_file, 'motion_curves');
fprintf("Saved motion curves to file %s\n", motion_curves_file);
