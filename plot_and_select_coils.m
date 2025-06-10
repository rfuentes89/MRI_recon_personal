%%% Plot coil images and select/reject each of them 
addpath(genpath("./"));

%% Set parameters
CONFIG.acq_folder = getenv("WORKSPACE") + "/acquisitions/2024-07-19_HV04_BOOST";
CONFIG.twix_fname = "*BOOST_fixed2.dat";

%% Read Twix and unpack data
path_to_twix = find_twix_file(fullfile(CONFIG.acq_folder, "raw", CONFIG.twix_fname));
twix = read_twix(path_to_twix);
data = read_raw_data(twix{end});
data = remove_readout_oversampling(data);

%% Select one contrast
if numel(data.k_spaces) > 1
    selected_contrast = select_for_coil_rating(data);
else
    selected_contrast.echo = 1;
    selected_contrast.set = 1;
    selected_contrast.repetition = 1;
end
selected_contrast

%% Plot coil images
[yes_indices, maybe_indices, no_indices] = rate_coils(data, selected_contrast);

fprintf('Yes:   [%s]\n', strjoin(string(yes_indices), ', '));
fprintf('Maybe: [%s]\n', strjoin(string(maybe_indices), ', '));
fprintf('No:    [%s]\n', strjoin(string(no_indices), ', '));

% Set the coil_params.use_only in your CONFIG file to the chosen coils