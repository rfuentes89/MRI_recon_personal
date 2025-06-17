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

    % Pad and resize data
    % FIXME(pdpino): check dimensions for any input
    % (300 is hardcoded for the typical dimensions)
    [n_fh, n_rl, n_ap] = size(image);
    pad_fh = (300 - n_fh) / 2;
    pad_rl = (300 - n_rl) / 2;
    data_padded = padarray(image, [pad_fh, pad_rl, 0]);
    data_resized = imresize3(data_padded, dummy_par.dim);
    data_rescaled = rescale(data_resized, 0, 2048);

    % Write REC
    output_rec = output_basename + ".rec";
    writerec(output_rec, data_rescaled);
    if params.verbose, fprintf("REC written to %s\n", output_rec); end

    % Write PAR
    output_par = output_basename + ".par";
    copyfile(params.input_par, output_par);
    if params.verbose, fprintf("PAR written to %s\n", output_par); end
end

