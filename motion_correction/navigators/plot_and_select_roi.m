function navigator_roi = plot_and_select_roi(sum_of_navigators, base_fname)
%SELECT_ROI Manually select a ROI in the sum of the navigators
    figure("CloseRequestFcn", @save_and_close)

    uicontrol( ...
        "Style", "pushbutton", ...
        "String", "save", ...
        "Callback", @save_and_close ...
    );

    imshow(sum_of_navigators, [])
    ROI = drawrectangle;
    p = [];

    waitfor(gcf)

    function save_and_close(~, ~)
        if ~exist("ROI", "var")
            warndlg("please select a region")
            return
        end
        p = ROI.Position;
        if exist("base_fname", "var")
            saveas(gcf, base_fname + "_selection.png")
        end
        delete(gcf)
    end

    navigator_roi.rl_min = floor(p(1));
    navigator_roi.fh_min = floor(p(2));
    navigator_roi.rl_max = navigator_roi.rl_min + ceil(p(3));
    navigator_roi.fh_max = navigator_roi.fh_min + ceil(p(4));
end

