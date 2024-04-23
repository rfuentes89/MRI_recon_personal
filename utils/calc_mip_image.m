function mip_image = calc_mip_image(image, params)
%CALC_MIP_IMAGE Calculate Maximum Intensity Projection (MIP) image

    % Check parameters
    assert(ndims(image) == 3, "Image must have 3 dimensions");
    if nargin < 2
        params.thickness = 10;
        params.axis = "z";
    end

    % Choose axis
    switch params.axis
        case "x"
            mip_dim = 1;
            get_slab = @(min_idx, max_idx) image(min_idx:max_idx,:,:);
        case "y"
            mip_dim = 2;
            get_slab = @(min_idx, max_idx) image(:,min_idx:max_idx,:);
        case "z"
            mip_dim = 3;
            get_slab = @(min_idx, max_idx) image(:,:,min_idx:max_idx);
        otherwise
            error("MIP axis not recognized: "+ string(params.axis));
    end

    % Initialize empty image
    image = double(image);
    mip_image = zeros(size(image));
    n_slices = size(image, mip_dim);

    for i_slice = 1:n_slices
        min_i_slice = max(1, i_slice - params.thickness);
        max_i_slice = min(n_slices, i_slice + params.thickness);
        slab = get_slab(min_i_slice, max_i_slice);
        miped_slice = max(slab, [], mip_dim);

        switch params.axis
            case "x"
                mip_image(i_slice,:,:) = miped_slice;
            case "y"
                mip_image(:,i_slice,:) = miped_slice;
            case "z"
                mip_image(:,:,i_slice) = miped_slice;
            otherwise
                error("MIP axis not recognized: "+ string(params.axis));
        end
    end
end
