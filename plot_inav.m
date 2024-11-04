%%% Plot iNAV
% Save iNAVs animated across time as GIF and plot sum of navigators

%% Imports
addpath(genpath("./"))
config_fname = "configs/example_recon.json";

CONFIG = load_config(config_fname);

%% Read twix
path_to_twix = find_twix_file(fullfile(CONFIG.acq_folder, "raw", CONFIG.twix_fname));
twix = read_twix(path_to_twix);

disp("Twix loaded");

%% Load navigators
raw_navigators = read_navigators(twix{end}, CONFIG.selected_contrasts);
disp("Navigators loaded");

%% Pass to array
[n_echoes, n_sets, n_navigators, n_repetitions]  = size(raw_navigators);

navs = cell(n_echoes, n_sets, n_repetitions);
for repetition = 1:n_repetitions
    for set = 1:n_sets
        for echo = 1:n_echoes
            [n_x, n_y] = size(raw_navigators{echo,set,1,repetition});
            nav = zeros(n_x, n_y, n_navigators);
            for i_navigator = 1:n_navigators
                nav(:,:,i_navigator) = rescale(raw_navigators{echo,set,i_navigator,repetition}, 0, 255);
            end
            navs{echo, set, repetition} = nav;
        end
    end
end

%% Save GIFs
folder_output = fullfile(CONFIG.acq_folder, "navigators");
if ~exist(folder_output, "dir"), mkdir(folder_output); end
for i_contrast = 1:length(navs)
    cname = string(CONFIG.seq_params.contrast_names{i_contrast});
    fpath = fullfile(folder_output, cname + ".gif");
    save_gif(navs{i_contrast}, fpath);
end

%% Sum navigators
% Same code as register_navigators
[n_echoes, n_sets, n_navigators, n_repetitions]  = size(raw_navigators);

sum_of_navigators = zeros(size(raw_navigators{1}));
for repetition = 1:n_repetitions
    for navigator = 1:n_navigators
        for set = 1:n_sets
            for echo = 1:n_echoes
                sum_of_navigators = sum_of_navigators + mat2gray(abs(raw_navigators{echo,set,navigator,repetition}));
            end
        end
    end
end

%% Plot sum
imshow(sum_of_navigators, []);
saveas(gcf, fullfile(folder_output, "sum.png"));
