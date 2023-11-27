function [DFs,reg_navs] = NIFTI_reg_bins_XMR(nav_rfm,args)
% nav_rfm is a 4D image: nav_rfm(:,:,:,1) = ref, nav_rfm(:,:,:,2) = mov.
% args is a string with the niftireg params

if nargin<2
    %args = ' --lncc 3.0 -be 0.0005 -ln 5 -sx 14';
    args = ' --nmi -be 0.0005 -sx 14';
end

location = pwd;
nifti_path = [location, '/NIFTI_REG'];
% Correct nifti path
if ~(ismcc || isdeployed)
    addpath(genpath(nifti_path));
end
% % addpath(genpath('/data/gc13/gc13_core_code/Phd/Playground/Utilities/'));
% 
% data_folder = dir(output_folder);
% fprintf('Available data files:\n');
% for ind = size(data_folder,1):-1:1
%     if isempty(strfind(data_folder(ind).name, file_name)) ||... 
%                 isempty(strfind(data_folder(ind).name, '.mat'))
%         data_folder(ind) = [];
%     end
% end
% for ind = 1:size(data_folder,1)
%     fprintf('%2d %s\n', ind, data_folder(ind).name)
% end
% fprintf('\n');
% 
% iNoT2_Tcorr = load([output_folder data_folder(1).name]); iNoT2_Tcorr = iNoT2_Tcorr.dft_corr;
% DUALT2_Tcorr = load([output_folder data_folder(2).name]); DUALT2_Tcorr = DUALT2_Tcorr.dft_corr;

% nav_rfm(:,:,:,1) = iNoT2_Tcorr;
% nav_rfm(:,:,:,2) = DUALT2_Tcorr;

% Output DF
DFs = zeros(size(nav_rfm,1),size(nav_rfm,2),size(nav_rfm,3),3,size(nav_rfm,4));
reg_navs = zeros(size(nav_rfm,1),size(nav_rfm,2),size(nav_rfm,3));

% Use end-expiration bin as reference 
Ref = Normalize(abs(nav_rfm(:,:,:,1)),0,1);

curr_dir = pwd;
cd(nifti_path)

tic;
for mmm = 1:size(nav_rfm,4)
    Mov = Normalize(abs(nav_rfm(:,:,:,mmm)),0,1);
    [reg_navs(:,:,:,mmm), displacement_field] = nifty_reg_CM(Mov,Ref,args);
%     DFs(:,:,:,:,1,1) = Add_mesh_to_DF(squeeze(displacement_field));
    DFs(:,:,:,:,mmm) = squeeze(displacement_field);
end
toc;

cd(curr_dir);

DFs = Add_mesh_to_DF(DFs);

% save([output_folder data_folder(1).name(1:end-4) '_reg'], 'dft_corr_registered', '-v7.3');

% DFs_3D = expand_DF(DFs,target_size);

% save([output_folder 'DFs_2D'], 'DFs', '-v7.3');
% save([output_folder 'DFs_3D'], 'DFs_3D', '-v7.3');



