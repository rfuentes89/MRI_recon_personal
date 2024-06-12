function save_gif(images, filename, options)
% SAVE_GIF Save an image volume to a GIF file
%
% save_gif(images, filename, options)
%
% Inputs
%    images: 3D volume (must be parsable to double)
%    filename: string or char array
%    options.axis: which axis to use as time, one of "x", "y" or "z",
%          defaults to z
%    options.delay_time: seconds between frames in GIF, defaults to 0.02
%    options.norm: whether or not to normalize to 0-255 range,
%          defaults to true. Note: if false, values outside this range
%          might be lost when casting to uint8.

    if ~exist('options', 'var'), options = struct(); end
    if ~isfield(options, 'delay_time'), options.delay_time = 0.2; end
    if ~isfield(options, 'axis'), options.axis = "z"; end
    if ~isfield(options, 'norm'), options.norm = true; end
    if ~isfield(options, 'verbose'), options.verbose = false; end

    % Check filename input
    filename = string(filename);
    if ~endsWith(filename, ".gif"), filename = filename + ".gif"; end
    [folder, ~, ~] = fileparts(filename);
    if strlength(folder) > 0 && ~exist(folder, "dir"), mkdir(folder); end

    % Check images input
    assert(numel(size(images)) == 3, "images must have 3 dimensions");
    [nx, ny, nz] = size(images);
    if options.norm, images = rescale(images, 0, 255); end
    images = uint8(images);

    % Check axis input
    switch options.axis
       case "x"
          n_slices = nx;
          get_slice = @(volume, idx) squeeze(volume(idx,:,:));
       case "y"
          n_slices = ny;
          get_slice = @(volume, idx) squeeze(volume(:,idx,:));
        case "z"
          n_slices = nz;
          get_slice = @(volume, idx) squeeze(volume(:,:,idx));
       otherwise
          error("axis not recognized: %s", options.axis);
    end

    % Write GIF
    for idx = 1:n_slices
        im_slice = get_slice(images, idx);
        if idx == 1
            imwrite(im_slice,filename,"gif","LoopCount",Inf,"DelayTime",options.delay_time);
        else
            imwrite(im_slice,filename,"gif","WriteMode","append","DelayTime",options.delay_time);
        end
    end

    if options.verbose, disp("GIF saved to " + filename); end
end

