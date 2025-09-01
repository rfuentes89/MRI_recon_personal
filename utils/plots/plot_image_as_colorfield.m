function plot_image_as_colorfield(image, ax, params)
%PLOT_IMAGE_AS_COLORFIELD Plot an image as a colorfield, with the colorbar
%next to it.
    % Default params
    if ~exist("params", "var"), params = struct(); end
    params = fill_struct_values(params, struct( ...
        cbar=true, ...
        alpha=0.8, ...
        cmap='jet'));

    assert(ismatrix(image));

    imagesc(ax, image, 'AlphaData', params.alpha);
    colormap(ax, params.cmap);
    axis off;

    % Set colobar limits
    min_value = min(image(:));
    max_value = max(max(image(:)), min_value + eps);
    clim(ax, [min_value, max_value]);

    % Fix aspect ratio
    pbaspect(ax, [size(image, 2), size(image, 1), 1]);

    if params.cbar
        colorbar();
    end
end
