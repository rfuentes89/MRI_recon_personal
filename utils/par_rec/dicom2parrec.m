function dicom2parrec(dicom_fname, output_basename, params)
%DICOM2PARREC Load a DCM and write PAR/REC files
% Args:
%     dicom_fname: name of DCM input
%     output_basename: name will be used to save .par and .rec files. For
%         example, using "some_folder/example" will produce files
%         "some_folder/example.par" and "some_folder/example.rec"
%     params.input_par: which .PAR file to use as base configuration
%     params.verbose

    % Default params
    if nargin < 3, params = struct(); end
    params = fill_struct_values(params, struct( ...
        input_par=which("iT2prep_ZOOMED.PAR"), ...
        verbose=true));

    % Read PAR
    dummy_par = readpar(params.input_par);

    % Read DCM
    image = double(squeeze(dicomread(dicom_fname)));

    % Pad and resize to PAR size
    % Note: data needs to be rescaled to the size from the PAR metadata,
    % and is previously padded to avoid changing the image aspect ratio
    pad_each_side = find_padsize(dummy_par.dim, size(image));
    data_padded = padarray(image, pad_each_side);
    data_resized = imresize3(data_padded, dummy_par.dim);
    data_rescaled = rescale(data_resized, 0, 2048);

    if params.verbose >= 2
        fprintf("DICOM size: %s\n", num2str(size(image)));
        fprintf("Padded size: %s\n", num2str(size(data_padded)));
        fprintf("PAR size: %s\n", num2str(dummy_par.dim));
    end

    % Write REC
    output_rec = output_basename + ".rec";
    writerec(output_rec, data_rescaled);
    if params.verbose, fprintf("REC written to %s\n", output_rec); end

    % Write PAR
    output_par = output_basename + ".par";
    copyfile(params.input_par, output_par);
    if params.verbose, fprintf("PAR written to %s\n", output_par); end
end

function pad_each_side = find_padsize(target_size, image_size)
% Find how much needs to be padded on each dimension to keep at least 1
% dimension without padding (and only add padding to the other dimensions).
    % How much resizing would each dimension need
    enlarge_ratio = target_size ./ image_size;

    % Choose dimension that would need less enlargement
    [~, min_index] = min(enlarge_ratio);

    % Calculate padded size (one of the dimensions will remain the same)
    padded_size = floor(target_size / enlarge_ratio(min_index));

    % How much pad is needed
    pad_each_dim = padded_size - image_size;
    pad_each_side = floor(pad_each_dim / 2);
end
