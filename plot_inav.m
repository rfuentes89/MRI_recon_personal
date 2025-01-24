%%% Plot iNAV
% Save iNAVs animated across time as GIF and plot sum of navigators

%% Imports
addpath(genpath("./"))
config_fname = "configs/base_motion_curves.json";

CONFIG = load_config(config_fname);

%% Read twix
path_to_twix = find_twix_file(fullfile(CONFIG.acq_folder, "raw", CONFIG.twix_fname));
twix = read_twix(path_to_twix);

disp("Twix loaded");

%% Load navigators
raw_navigators = read_navigators(twix{end}, CONFIG.selected_contrasts);
disp("Navigators loaded");

%% Pass to array
[n_echoes, n_sets, n_repetitions, n_navigators]  = size(raw_navigators);

navs = cell(n_echoes, n_sets, n_repetitions);
for repetition = 1:n_repetitions
    for set = 1:n_sets
        for echo = 1:n_echoes
            navs{echo,set,repetition} = concat_cell_to_array(raw_navigators(echo,set,repetition,:));
            % size: nx, ny, n_navigators
        end
    end
end

%% Save GIFs
folder_output = fullfile(CONFIG.acq_folder, "navigators");
if ~exist(folder_output, "dir"), mkdir(folder_output); end
for i_contrast = 1:length(navs)
    cname = string(CONFIG.contrast_names{i_contrast});
    fpath = fullfile(folder_output, CONFIG.name + "_" + cname + ".gif");
    save_gif(navs{i_contrast}, fpath);
end

%% Plot sum of navigators
sum_of_navigators = sum_navigators(raw_navigators);
imshow(sum_of_navigators, []);
saveas(gcf, fullfile(folder_output, CONFIG.name + "_sum.png"));
