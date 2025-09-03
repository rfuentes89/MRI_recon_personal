
%% 
clear; clc; close all;

% Ruta al archivo de datos .dat.
raw_data_path = '/mnt/workspace/rfuentes/recon/2025-08-01/raw/meas_MID00020_FID13444_BOOST_MLEV4_Cor_60slices_30seg(120°_60°).dat';


%% 

twix_obj = mapVBVD(raw_data_path);
data = read_raw_data(twix_obj{end});

data = remove_readout_oversampling(data);

for i = 1:numel(data.k_spaces)
    kspace_coils = data.k_spaces{i};
    [Nx, Ny, Nz, Ncoils] = size(kspace_coils);
    new_dims = [2*Nx, 2*Ny, 2*Nz];

    kspace_padded_multicoil = zeros([new_dims, Ncoils], 'like', kspace_coils);

    for c = 1:Ncoils
        kspace_1coil = kspace_coils(:,:,:,c);

        kspace_padded = zeros(new_dims, 'like', kspace_1coil);
        id_x = floor(new_dims(1)/2) - floor(Nx/2) + (1:Nx);
        id_y = floor(new_dims(2)/2) - floor(Ny/2) + (1:Ny);
        id_z = floor(new_dims(3)/2) - floor(Nz/2) + (1:Nz);
        kspace_padded(id_x, id_y, id_z) = kspace_1coil;

        kspace_padded_multicoil(:,:,:,c) = kspace_padded;
    end
    data.k_spaces{i} = kspace_padded_multicoil;
end
%%
csm_algorithm = 'espirit';

selected_contrasts_for_rating.echo = 1;
selected_contrasts_for_rating.set = 1;
selected_contrasts_for_rating.repetition = 1;
csm_params.bart_params = '-r 20 -k 5 -c 0 -S';

csm = get_csm(data.k_spaces, csm_algorithm, selected_contrasts_for_rating, csm_params);
%%
%images_complex = reconstruct_images(data, csm, ...);
img1 = ktoi(data.k_spaces{1}, csm);
img2 = ktoi(data.k_spaces{2}, csm);
%%
params.recon_mode = 7;
params.sig = 0.65;
params.patch_size = 7;
%%
denoised_1HB = denoising_HD_PROST(img1, params);
denoised_2HB = denoising_HD_PROST(img2, params);
%%
first_HB = abs(img1);
second_HB = abs(img2);
%BB = rot90(abs(img1 - img2));
%my_BB = rot90(abs(denoised_1HB - denoised_2HB),-1);
%my_BB2 = rot90(abs(denoised_2HB - denoised_1HB), -1);
my_BB3 = rot90(abs(denoised_2HB)- abs(denoised_1HB), -1);
%my_BB3(my_BB3<0) = 0;



%slice_to_show = 42;


%%
