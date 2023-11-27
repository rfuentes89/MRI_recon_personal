function write_dicom_volume(image, filename, info, volscale)
    % Based on  
    %     - DICOM Toolbox: https://uk.mathworks.com/matlabcentral/fileexchange/27941-dicom-toolbox
    %     - https://uk.mathworks.com/matlabcentral/fileexchange/23237-read-and-write-single-file-dicom-volumes
    % Check inputs
    if(exist('filename','var')==0), filename=[]; end
    if(exist('info','var')==0), info=[]; end
    if(exist('volscale','var')==0), volscale=[1 1 1]; end
    % Add dicom tags to info structure
    if(~isstruct(info))
        info=struct;
        % Make random series number
        SN=round(rand(1)*1000);
        % Get date of today
        today=[datestr(now,'yyyy') datestr(now,'mm') datestr(now,'dd')];
        info.SeriesNumber=SN;
        info.AcquisitionNumber=SN;
        info.StudyDate=today;
        info.StudyID=num2str(SN);
        info.PatientID=num2str(SN);
        info.AccessionNumber=num2str(SN);
        info.StudyDescription=['StudyMAT' num2str(SN)];
        info.SeriesDescription=['StudyMAT' num2str(SN)];
        info.Manufacturer='Matlab Convert';
        % create a dicom header with the relevant information
        info.SOPClassUID='1.2.840.10008.5.1.4.1.1.4'; %MRI UID
        %Geometry
        info.PatientPosition='HFS';
        info.ImagePositionPatient=[0;0;0];
        info.ImageOrientationPatient=[1;0;0;0;1;0];
        %info.PixelSpacing=[volscale(1); volscale(2)];
        %info.SliceThickness=volscale(3);
        %info.SpacingBetweenSlices=volscale(3);
        info.Width=size(image,1);
        info.Height=size(image,2);
    end
    disp(filename)
    if isfield(info, 'LargestImagePixelValue') max_value = info.LargestImagePixelValue; else max_value = (2^16 - 1); end
    
    % Remove filename extention
    pl=find(filename=='.'); if(~isempty(pl)), filename=filename(1:pl-1); end
    % Write volume
    min_im = prctile(image(:), 10);
    max_im = prctile(image(:), 100);
    disp(max_im)
    image_norm = uint16( double(max_value) * (image - min_im) / (max_im - min_im) ); 
    sz = size(image);
    image_gray = reshape(image_norm,sz(1),sz(2),1,sz(3));
    dicomwrite(image_gray, [filename '.dcm'], info, 'CreateMode', 'copy')
    %dicomwrite(image_gray, [filename '.dcm'], info)
end