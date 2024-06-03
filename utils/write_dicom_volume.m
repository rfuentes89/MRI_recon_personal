function write_dicom_volume(image, filename, info, options)
    % Based on  
    %     - DICOM Toolbox: https://uk.mathworks.com/matlabcentral/fileexchange/27941-dicom-toolbox
    %     - https://uk.mathworks.com/matlabcentral/fileexchange/23237-read-and-write-single-file-dicom-volumes
    % Check inputs
    if ~exist('options', 'var'), options = struct(); end
    if ~isfield(options, 'min_perc'), options.min_perc = 10; end
    if ~isfield(options, 'max_perc'), options.max_perc = 100; end

    info = clean_dicom_info(image, info);

    % Compute min and max percentiles
    if isfield(info, 'LargestImagePixelValue')
        max_value = info.LargestImagePixelValue;
        if max_value < 100
            warning("max_value is low: %d, might get an empty image", max_value);
        end
    else
        max_value = (2^16 - 1);
    end
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

function info = clean_dicom_info(image, info)
% CLEAN_DICOM_INFO Removes unnecessary fields from dicominfo
    [image_height, image_width, image_depth] = size(image, 1:3);

    info_width = get_field(info, 'Width');
    info_height = get_field(info, 'Height');
    info_depth = get_field(info, 'NumberOfFrames');

    if info_width ~= image_width || info_height ~= image_height || info_depth ~= image_depth
        % These fields contain info per frame
        % If the generated image has a different size, these fields might
        % produce an error
        if isfield(info, 'PerFrameFunctionalGroupsSequence')
            info = rmfield(info, 'PerFrameFunctionalGroupsSequence');
        end
        if isfield(info, 'SharedFunctionalGroupsSequence')
            info = rmfield(info, 'SharedFunctionalGroupsSequence');
        end
    end
end
