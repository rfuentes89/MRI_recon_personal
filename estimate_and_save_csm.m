%%% Estimate CSM and save to .raw file
%% Choose acquisition
CONFIG.acq = "2025-03-13_HV01_CMRA";
CONFIG.twix_fname = "*CMRA.dat";
CONFIG.csm_algorithm = "espirit";
CONFIG.csm_params.bart_params = "-r 20 -k 5 -c 0 -S";

CONFIG.acq_folder = fullfile(getenv("WORKSPACE"), "acquisitions", CONFIG.acq);

%% Load data
path_to_twix = find_twix_file(fullfile(CONFIG.acq_folder, "raw", CONFIG.twix_fname));
twix = read_twix(path_to_twix);
data = read_raw_data(twix{end});
data = remove_readout_oversampling(data);

%% Compute CSM
contrast.echo = 1;
contrast.set = 1;
contrast.repetition = 1;
csm = get_csm(data.k_spaces, CONFIG.csm_algorithm, contrast, CONFIG.csm_params);

%% Get CSM shape
csm_raw = csm.coil_sensitivity_maps_raw;
csm_shape = strjoin(string(size(csm_raw)), 'x');

%% Shift and flip, to simulate scanner
n_image_dims = ndims(csm_raw) - 1; % Assume last dimension is coils
for i_dim = 1:n_image_dims
    csm_raw = ifftshift(flip(csm_raw, i_dim), i_dim);
end

%% Build interleaved array
csm_raw = single(csm_raw(:));
csm_interleaved = zeros(2 * numel(csm_raw), 1, 'single');
csm_interleaved(1:2:end) = real(csm_raw);
csm_interleaved(2:2:end) = imag(csm_raw);

%% Save to .raw file
fname = sprintf("matlab_%s_%s.raw", CONFIG.csm_algorithm, csm_shape);
fpath = fullfile(CONFIG.acq_folder, "raw", fname);
fid = fopen(fpath, "w");
fwrite(fid, csm_interleaved, "single");
fclose(fid);
fprintf("Saved to %s\n", fpath);

%% Test correctness
csm_target = single(csm.coil_sensitivity_maps_raw);
csm_loaded = coil_sensitivity_scanner(fpath);
assert(all(csm_target(:) == csm_loaded(:)));
