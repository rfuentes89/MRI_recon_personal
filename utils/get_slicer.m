function [get_slice, axis_dim] = get_slicer(axis)
%GET_SLICER Creates a function to slice a volume across an axis
%   Args:
%       axis: one of "x", "y" or "z"
%   Returns:
%       function with signature get_slice(volume, idx)
%           - volume: 3D or 4D array
%           - idx: number of slice
%           returns volume idx'th slice across axis
%       axis_num: axis converted to number
    switch axis
        case {"x", "tra", "transverse"}
            axis_dim = 1;
            get_slice = @(volume, idx) squeeze(volume(idx,:,:,:));
        case {"y", "sag", "sagittal"}
            axis_dim = 2;
            get_slice = @(volume, idx) squeeze(volume(:,idx,:,:));
        case {"z", "cor", "coronal"}
            axis_dim = 3;
            get_slice = @(volume, idx) squeeze(volume(:,:,idx,:));
        otherwise
            error("Axis not recognized: %s", axis);
    end
end
