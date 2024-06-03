function info = build_empty_dicominfo()
%BUILD_EMPTY_DICOMINFO Creates a dummy dicominfo
%
%   - Uses a random number as SeriesNumber

    %if(exist('volscale','var')==0), volscale=[1 1 1]; end

    info=struct;
    % Make random series number
    SN=round(rand(1)*1000);
    info.SeriesNumber=SN;
    info.AcquisitionNumber=SN;
    info.StudyDate=convertStringsToChars(string(datetime("now"), "yyyy-MM-dd"));
    info.StudyID=num2str(SN);
    info.PatientID=num2str(SN);
    info.AccessionNumber=num2str(SN);
    info.StudyDescription=['StudyMAT' num2str(SN)];
    info.SeriesDescription=['StudyMAT' num2str(SN)];
    info.Manufacturer='Matlab Convert';

    info.SOPClassUID='1.2.840.10008.5.1.4.1.1.4'; %MRI UID
    warning('off', 'images:dicomwrite:inconsistentIODAndCreateModeOptions');

    %Geometry
    info.PatientPosition='HFS';
    info.ImagePositionPatient=[0;0;0];
    info.ImageOrientationPatient=[1;0;0;0;1;0];
    %info.PixelSpacing=[volscale(1); volscale(2)];
    %info.SliceThickness=volscale(3);
    %info.SpacingBetweenSlices=volscale(3);
    info.LargestImagePixelValue = 2^16 - 1;
end

