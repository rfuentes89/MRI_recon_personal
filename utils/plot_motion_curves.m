function plot_motion_curves(motion_curves)
% PLOT_MOTION_CURVES Plot motion_curves
% Args:
%     motion_curves: cell with n_contrasts
%        motion_curves{i}.fh: (plottable) array with foot-head motion
    n_contrasts = numel(motion_curves);

    hold on;
    for i_contrast = 1:n_contrasts
        plot(motion_curves{i_contrast}.fh, "DisplayName", sprintf("contrast %d", i_contrast));
    end
    legend();
    ylabel("pixels")
    xlabel("time");
    title("foot-head motion")
end