function [registered_image, displacement_field,inv_displacement_field] = niftyreg_wrapper(reference, moving, options, tmp_path, clean_temp)
% Calls nifty reg for non-rigid registration and calculates displacement
% field.
%
% Input:
% reference, moving: images to be registered
% options: string containing any options for reg_3fd (default empty)
% tmp_path: path where temporary nifti files will be written (defaults to
% $HOME/.nifty-tmp/)
% clean_temp: flag, 1 to delete temp files afterwards, 0 to keep them


if nargin < 3
    options = [];
end

if nargin < 4
    tmp_path = '~/.nifty-tmp/';
end

if nargin < 5
    clean_temp = true;
end

% NOTE: you'll need to normalize the inputs before calling this function
% reference = rescale(abs(reference),0,1);
% moving    = rescale(abs(moving),0,1);

if ~exist(tmp_path, 'dir'), mkdir(tmp_path), end

% NOTE(pdpino): old nifty code works with chars instead of
% strings, for now use chars to avoid errors
tmp_path = convertStringsToChars(tmp_path);
if ~endsWith(tmp_path, "/"), tmp_path = [tmp_path '/']; end

% Save inputs as nifti
nii1 = make_nii(reference);
save_nii(nii1, [tmp_path, 'im1']);

nii2 = make_nii(moving);
save_nii(nii2, [tmp_path, 'im2']);

% Do registration
[flag, cmd_output] = system(['reg_f3d' ' -ref ' tmp_path, 'im1 '...
    ' -flo ' tmp_path, 'im2 ' ...
    ' -res ' tmp_path, 'registered'...
    ' -cpp ' tmp_path, 'cpp',...
    ' ' convertStringsToChars(options)]  );

if flag
    error('nifty reg failed %s', cmd_output)
end

registered = load_nii([tmp_path, 'registered']);

registered_image = registered.img;

% Calculate displacement field

[flag, ~] = system(['reg_transform', ' -ref ' tmp_path, 'im1 '...
    ' -disp ' [tmp_path, 'cpp.nii '],...
    [tmp_path, 'disp.nii ']
    ]);

disp = load_nii([tmp_path, 'disp.nii']);
displacement_field = disp.img;


if nargout >= 3
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% Trying to invert mf %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% need to half the transformation first??
[flag, ~] = system(['reg_transform', ' -ref ' tmp_path, 'im1 '...
    ' -half ' [tmp_path, 'cpp.nii '],...
     [tmp_path, 'cpp_half.nii']
    ]);


% invert mf
[flag, ~] = system(['reg_transform', ' -ref ' tmp_path, 'im1 '...
    ' -invNrr ' [tmp_path, 'cpp_half.nii '],...
    [tmp_path, 'im2.nii '],...
    [tmp_path, 'disp_inv.nii']
    ]);

disp_inv = load_nii([tmp_path, 'disp_inv.nii']);
inv_displacement_field = disp_inv.img;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end


% Cleanup temp files

if clean_temp

    [flag, ~] = system(['rm ' tmp_path, 'im1.hdr']);
    [flag, ~] = system(['rm ' tmp_path, 'im1.img']);
    [flag, ~] = system(['rm ' tmp_path, 'im1.mat']);

    [flag, ~] = system(['rm ' tmp_path, 'im2.hdr']);
    [flag, ~] = system(['rm ' tmp_path, 'im2.img']);
    [flag, ~] = system(['rm ' tmp_path, 'im2.mat']);

    [flag, ~] = system(['rm ' tmp_path, 'registered.hdr']);
    [flag, ~] = system(['rm ' tmp_path, 'registered.img']);

    [flag, ~] = system(['rm ' tmp_path, 'cpp.nii']);

    [flag, ~] = system(['rm ' tmp_path, 'disp.nii']);

end

