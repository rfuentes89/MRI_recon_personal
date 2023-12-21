%% Denoising Step
addpath(genpath("./"))
%%
file_dir_out = "Paper_Data/GCR/dicom/";
denoising_type = "HD_PROST";
%%
filename_1 = file_dir_out + "GCR_SYS_ADIA50ms_TI90ms_HB1.dcm";
disp(filename_1)
image_scanner_1 = squeeze(dicomread(filename_1));
info_1 = dicominfo(filename_1);
filename_2 = file_dir_out + "GCR_SYS_ADIA50ms_TI90ms_HB2.dcm";
image_scanner_2 = squeeze(dicomread(filename_2));
info_2 = dicominfo(filename_2);
filename_3 = file_dir_out + "GCR_SYS_ADIA50ms_TI90ms_BB.dcm";
info_3 = dicominfo(filename_3);
image_scanner_3 = squeeze(dicomread(filename_3));
image_cell = cell(1,2,1);
image_cell{1,1,1} = image_scanner_1;
image_cell{1,2,1} = image_scanner_2;
%%
if denoising_type ~= "none"
    disp("step 9: denoising")
    denoised_images = denosing_HD_PROST_MULTICONTRAST(image_cell);
end
black_blood = abs(denoised_images{2}) - abs(denoised_images{1});
disp("Denosing Done")

%%
write_dicom_volume(denoised_images{1},'HB1',info_1,[]);
write_dicom_volume(denoised_images{2},'HB2',info_2,[]);
write_dicom_volume(black_blood,'BB',info_3,[]);
disp("Dicom over-writed")
%%
filename_3 = "BB.dcm";
BB_calculado = squeeze(dicomread(filename_3));