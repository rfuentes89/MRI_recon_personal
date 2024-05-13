%%% Plot iNAV
% Save iNAVs animated across time as GIF and plot sum of navigators

%% Imports
addpath(genpath("./"))
config_fname = "configs/example.json";

CONFIG = load_config(config_fname);

%% Read twix
path_to_twix = find_twix_file(fullfile(CONFIG.acq_folder, "raw", CONFIG.twix_fname));
twix = read_twix(path_to_twix);

disp("Twix loaded");

%% Load navigators
raw_navigators = read_navigators(twix, CONFIG.selected_contrasts);
disp("Navigators loaded");

%% Pass to array
[n_x, n_y] = size(raw_navigators{1});
[n_echoes, n_sets, n_navigators, n_repetitions]  = size(raw_navigators);

% Hard-coded for 2 sets (boost)
navs1 = zeros(n_x, n_y, n_navigators);
navs2 = zeros(n_x, n_y, n_navigators);
for i_navigator = 1:n_navigators
    navs1(:,:,i_navigator) = rescale(raw_navigators{1,1,i_navigator,1}, 0, 255);
    navs2(:,:,i_navigator) = rescale(raw_navigators{1,2,i_navigator,1}, 0, 255);
end


%% Save GIFs
folder_output = fullfile(CONFIG.acq_folder, "navigators");
if ~exist(folder_output, "dir"), mkdir(folder_output); end
save_gif(navs1, fullfile(folder_output, "HB1.gif"))
save_gif(navs2, fullfile(folder_output, "HB2.gif"))


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
