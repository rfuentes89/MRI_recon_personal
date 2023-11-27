%% Dicom transformer
addpath(genpath("./"))
%%
file_dir_out = "ABSTRACT_DATA/TC/dicom/";
filename_1 = file_dir_out + "AORTA_DIAS_MLEV8_60ms_HB1.dcm";
disp(filename_1)
image_scanner_1 = squeeze(dicomread(filename_1));
info_1 = dicominfo(filename_1);
filename_2 = file_dir_out + "AORTA_DIAS_MLEV8_60ms_HB2.dcm";
image_scanner_2 = squeeze(dicomread(filename_2));
info_2 = dicominfo(filename_2);
filename_3 = file_dir_out + "AORTA_DIAS_MLEV8_60ms_BB.dcm";
info_3 = dicominfo(filename_3);


%sigma_list = {0.02,0.05,0.08,0.2,0.5,0.8,1};
%lambda_list = {0.2,0.6,0.8,1};
%iterations_list = {3,4,5};
iterations_list = {5};
sigma_list = {0.02,0.025,0.3};
lambda_list = {0.1};


for i_ite = 1:length(iterations_list)
    iterations = iterations_list{i_ite};
    for i_sig = 1:length(sigma_list)
        sigma = sigma_list{i_sig};
        for i_lam = 1:length(lambda_list) 
            lambda = lambda_list{i_lam};
            parameters_used = "iter" + num2str(iterations) + "_sig" +num2str(sigma) + "_lamb" + num2str(lambda);
            newSeriesDescription_HB1 = "recon_hdprost_ADMM_" + char(parameters_used) + "_HB1";
            newSeriesDescription_HB2 = "recon_hdprost_ADMM_" + char(parameters_used) + "_HB2";
            newSeriesDescription_BB = "recon_hdprost_ADMM_" + parameters_used + "_BB";
            load('HDP_NONRIGID_TEST/TC/Recon_HDNR_GITHUB/recon_hdprost_ADMM_'+parameters_used+'.mat', 'recon_mc_hdprost');
            black_blood_nrp_batch = abs(recon_mc_hdprost{2}) - abs(recon_mc_hdprost{1});
            info_1.SeriesDescription = char(newSeriesDescription_HB1);
            info.StudyDescription = char(newSeriesDescription_HB1);
            write_dicom_volume(abs(recon_mc_hdprost{1}),'dicom_ref.dcm',info_1,[]);
            copyfile('dicom_ref.dcm','HDP_NONRIGID_TEST/TC/Recon_dicom/recon_hdprost_ADMM_'+parameters_used+'_HB1.dcm','f')
            info_2.SeriesDescription = char(newSeriesDescription_HB2);
            info.StudyDescription = char(newSeriesDescription_HB2);
            write_dicom_volume(abs(recon_mc_hdprost{2}),'dicom_ref.dcm',info_2,[]);
            copyfile('dicom_ref.dcm','HDP_NONRIGID_TEST/TC/Recon_dicom/recon_hdprost_ADMM_'+parameters_used+'_HB2.dcm','f')
            info_3.SeriesDescription = char(newSeriesDescription_BB);
            info.StudyDescription = char(newSeriesDescription_BB);
            write_dicom_volume(black_blood_nrp_batch,'dicom_ref.dcm',info_3,[]);
            copyfile('dicom_ref.dcm','HDP_NONRIGID_TEST/TC/Recon_dicom/recon_hdprost_ADMM_'+parameters_used+'_BB.dcm','f')
        end
    end
end
disp("Done")