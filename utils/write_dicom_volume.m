function write_dicom_volume(image, filename, info, options)
    % Based on  
    %     - DICOM Toolbox: https://uk.mathworks.com/matlabcentral/fileexchange/27941-dicom-toolbox
    %     - https://uk.mathworks.com/matlabcentral/fileexchange/23237-read-and-write-single-file-dicom-volumes
    % Check inputs
    if ~exist('filename','var'), filename=""; end
    if ~exist('info','var'), info=[]; end
    if ~exist('options', 'var'), options = struct(); end
    if ~isfield(options, 'min_perc'), options.min_perc = 10; end
    if ~isfield(options, 'max_perc'), options.max_perc = 100; end
    %if(exist('volscale','var')==0), volscale=[1 1 1]; end

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

    % Compute min and max percentiles
    if isfield(info, 'LargestImagePixelValue') max_value = info.LargestImagePixelValue; else max_value = (2^16 - 1); end
    if ~isnumeric(options.min_perc)
        % Remove zeros
        options.min_perc = (sum(image(:)==0) / numel(image) * 100);
    end
    min_im = prctile(image(:), options.min_perc);
    max_im = prctile(image(:), options.max_perc);

    % Normalize
    image_norm = uint16( double(max_value) * (image - min_im) / (max_im - min_im) );
    sz = size(image);
    image_gray = reshape(image_norm,sz(1),sz(2),1,sz(3));

    % Write volume
    filename = string(filename);
    if ~endsWith(filename, ".dcm"), filename = filename + ".dcm"; end

    n_tries = 10;
    for i_try = 1:n_tries
        try
            dicomwrite(image_gray, filename, info, 'CreateMode', 'copy')
            disp("Dicom written to " + filename);
            break;
        catch exception
            ith_out_of_nth = string(i_try) + "/" + string(n_tries);
            warning("Tried saving dicom " + ith_out_of_nth + ...
                ", got exception: " + string(exception.identifier))
            % NOTE(pdpino): this catches weird non-deterministic exception:
            %
            % Matrix index is out of range for deletion.
            % Error in dicom_generate_uid>guid_to_uid (line 125)
            % guid(13) = '';
        end
    end
end
