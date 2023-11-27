function [rl_min,fh_min,rl_max,fh_max] = rectangle_template(sum_of_navigators)

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
        delete(gcf)
    end
    
    rl_min = floor(p(1));
    fh_min = floor(p(2));
    rl_max = rl_min + ceil(p(3));
    fh_max = fh_min + ceil(p(4));
end

