function navigators = read_navigators(twix, selected)

twix = twix{end};
unsorted_data = twix.RTfeedback.unsorted();

n_readouts   = twix.RTfeedback.NAcq; % Number of readouts acquired
n_navigators = twix.RTfeedback.NIdc; % Number of acquired iNavs

n_k_x         = twix.RTfeedback.NCol; % Number of samples in each readout
n_k_y         = twix.RTfeedback.NLin; % Number of phase encoding lines
n_echoes      = twix.RTfeedback.NEco; % Number of echoes
n_sets        = twix.RTfeedback.NSet; % Number of interleaved contrasts
n_repetitions = twix.RTfeedback.NRep; % Number of sequential contrasts (cardiac phases)

n_coils  = twix.RTfeedback.NCha; % Number of coils

% Location of the centre of K-space
central_k_x = twix.RTfeedback.centerCol(1);
central_k_y = twix.RTfeedback.centerLin(1);

k_space_centre = [central_k_x, central_k_y];

% Information from full image to pad k space
central_k_y_im = twix.image.centerLin(1);
n_k_y_im = twix.image.NLin;  % Number of phase encoding lines image

k_space_dimensions_im = [n_k_x, n_k_y_im];
k_space_centre_im = [central_k_x, central_k_y_im];

% Coordinates of each readout in the phase encoding plane
k_y_at_readout  = double(twix.RTfeedback.Lin); % ky coordinate of each readout
navigator_at_readout  = double(twix.RTfeedback.Idc); % inav of read out

set_at_readout = double(twix.RTfeedback.Set);
echo_at_readout = double(twix.RTfeedback.Eco);
repetition_at_readout = double(twix.RTfeedback.Rep);

if nargin < 2, selected = struct(); end
if ~isfield(selected, 'sets') || isempty(selected.sets)
    selected.sets = 1:n_sets;
end
if ~isfield(selected, 'echoes') || isempty(selected.echoes)
    selected.echoes = 1:n_echoes;
end
if ~isfield(selected, 'repetitions') ||isempty(selected.repetitions)
    selected.repetitions = 1:n_repetitions;
end

n_selected_echoes = length(selected.echoes);
n_selected_sets = length(selected.sets);
n_selected_repetitions = length(selected.repetitions);

% TODO: only use the selected (and not subsequently rejected) coils

%% Unpack

% the navigator index increments after each cycle of sets, so this indexing
% should place the navigators in acquisition order
k_spaces = cell(n_echoes, n_sets, n_navigators, n_repetitions);

for readout = 1:n_readouts
        k_spaces{ ...
            echo_at_readout(readout), ...            
            set_at_readout(readout), ...
            navigator_at_readout(readout), ...
            repetition_at_readout(readout) ...
        }(:,k_y_at_readout(readout),:) = unsorted_data(:,:,readout);
end

% If the centre of k-space is not located in the centre of the matrix, we 
% need to pad the kSpace matrix, so that centre of k-space is 
% located in (Nx / 2 + 1, Ny / 2 + 1, Nz / 2 + 1)

padded_k_space_dimensions = 2 * max(k_space_dimensions_im - k_space_centre_im + 1, k_space_centre_im - 1);
offset = padded_k_space_dimensions / 2 - k_space_centre + 1;

padded_k_spaces = cell(n_selected_echoes, n_selected_sets, n_navigators, n_selected_repetitions);

navigators = cell(n_selected_echoes, n_selected_sets, n_navigators, n_selected_repetitions);
for repetition = 1:n_selected_repetitions
    for navigator = 1:n_navigators
        for set = 1:n_selected_sets        
            for echo = 1:n_selected_echoes
                padded_k_spaces{echo,set,navigator,repetition} = zeros([padded_k_space_dimensions, n_coils]);
                if mod(echo, 2) % is odd
                    padded_k_spaces{echo,set,navigator,repetition}(offset(1) + (1:n_k_x),offset(2) + (1:n_k_y),:) ...
                        = k_spaces{selected.echoes(echo),selected.sets(set),navigator,selected.repetitions(repetition)};
                else
                    padded_k_spaces{echo,set,navigator,repetition}(1:n_k_x,1:n_k_y,:) ...
                       = k_spaces{selected.echoes(echo),selected.sets(set),navigator,selected.repetitions(repetition)};
                end
                coil_images = flip(flip(ktoi(padded_k_spaces{echo,set,navigator,repetition}, [1 2]), 1), 2);
                navigators{echo,set,navigator,repetition} = double(sqrt(sum(abs(coil_images) .^ 2, 3)));
            end
        end
    end
end