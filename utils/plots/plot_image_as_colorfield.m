function plot_image_as_colorfield(image, ax)
%PLOT_IMAGE_AS_COLORFIELD Plot an image as a colorfield, with the colorbar
%next to it.
    assert(ismatrix(image));

    imagesc(ax, image, 'AlphaData', 0.8);
    colormap(ax, 'jet');

    % Set colobar limits
    min_value = min(image(:));
    max_value = max(max(image(:)), min_value + eps);
    clim(ax, [min_value, max_value]);

    % Fix aspect ratio
    pbaspect(ax, [size(image, 2), size(image, 1), 1]);
    colorbar();
    axis off;
end
