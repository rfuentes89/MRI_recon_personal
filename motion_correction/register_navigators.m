function [fh_displacements, rl_displacements] = register_navigators(navigators)

    [n_echoes, n_sets, n_navigators, n_repetitions]  = size(navigators);
    
    sum_of_navigators = zeros(size(navigators{1}));
    for repetition = 1:n_repetitions
        for navigator = 1:n_navigators
            for set = 1:n_sets            
                for echo = 1:n_echoes
    
                    sum_of_navigators = sum_of_navigators + mat2gray(abs(navigators{echo,set,navigator,repetition}));
    
                end
            end
        end
    end
    
    %% Select ROI
    
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
    
    %% Estimate Translational Motion
    padding_fh = 10;
    padding_rl = 2;
    
    normalised_navigators = cell(size(navigators));
    for repetition = 1:n_repetitions
        for navigator = 1:n_navigators
            for set = 1:n_sets
                for echo = 1:n_echoes
                    
                    current = navigators{echo,set,navigator,repetition};
                    cropped_navigator = current((fh_min - padding_fh):(fh_max + padding_fh),(rl_min - padding_rl):(rl_max + padding_rl));
                    normalised_navigator = mat2gray(abs(cropped_navigator));
                    
                    normalised_navigators{echo,set,navigator,repetition} = normalised_navigator;
                       
                end
            end
        end
    end

    
    [optimizer_mono, metric_mono] = imregconfig("monomodal");
    optimizer_mono.GradientMagnitudeTolerance   = 1E-14;
    optimizer_mono.MinimumStepLength            = 1E-14;
    optimizer_mono.MaximumStepLength            = 1E-2;
    optimizer_mono.MaximumIterations            = 2000;
    optimizer_mono.RelaxationFactor             = 5E-1;
    
    % TODO: we only need to register one echo of the navigators
    fh_displacements = nan(n_echoes, n_sets, n_navigators, n_repetitions);
    rl_displacements = nan(n_echoes, n_sets, n_navigators, n_repetitions);
    for repetition = 1:n_repetitions
        for set = 1:n_sets
            reference = normalised_navigators{1,set,1,1}; % Referencia para cada set es distinta 
            parfor navigator = 1:n_navigators
                for echo = 1:n_echoes
            
                    tform = imregtform( ...
                        normalised_navigators{echo,set,navigator,repetition}*256, ...
                        reference*256, ...
                        "translation", ...
                        optimizer_mono, ...
                        metric_mono ...
                    );
                    
                    % displacement of each navigator is the inverse of the
                    % transformation to align it with the reference,
                    % but matlab convention is positive downwards, so the
                    % two corrections cancel in the foot-head 
                    % fh_displacements(echo,set,navigator,repetition) = tform.T(3,2);
                    fh_displacements(echo,set,navigator,repetition) = tform.T(3,2);
                    rl_displacements(echo,set,navigator,repetition) = -tform.T(3,1);
                end
            end
        end
    end

    [optimizer_mono, metric_mono] = imregconfig("monomodal");
    optimizer_mono.GradientMagnitudeTolerance   = 1E-14;
    optimizer_mono.MinimumStepLength            = 1E-14;
    optimizer_mono.MaximumStepLength            = 1E-2;
    optimizer_mono.MaximumIterations            = 2000;
    optimizer_mono.RelaxationFactor             = 5E-1;

    for repetition = 1:n_repetitions
        for set = 1:n_sets
            for echo = 1:n_echoes
                % It wasn't considerated the binning process for each set.
                % Now it should work also for each repetition and echo.
                fh_motion = fh_displacements(echo,set,:,repetition);
                % Get the iNav that belongs to the first bin (end_expiration)
                [idx] = find_25_75_end_exp_descend(fh_motion);
                reference_end_expiration = normalised_navigators{echo,set,idx,repetition};
                parfor navigator = 1:n_navigators
                    tform = imregtform( ...
                        normalised_navigators{echo,set,navigator,repetition}*256, ...
                        reference_end_expiration*256, ...
                        "translation", ...
                        optimizer_mono, ...
                        metric_mono ...
                    );   
                    % displacement of each navigator is the inverse of the
                    % transformation to align it with the reference,
                    % but matlab convention is positive downwards, so the
                    % two corrections cancel in the foot-head 
                    % fh_displacements(echo,set,navigator,repetition) = tform.T(3,2);
                    fh_displacements(echo,set,navigator,repetition) = tform.T(3,2);
                    rl_displacements(echo,set,navigator,repetition) = -tform.T(3,1);
                end
            end
        end
    end

    
    % can adjust to a different reference position if desired?
    % e.g. "end expiration" to compare to diaphramatic navigators
    % using the mean minimises the distance of translational correction
    % either way no second registration is required    
    
%{
    %Im not sure if this is need it
    for repetition = 1:n_repetitions
            for set = 1:n_sets
                for echo = 1:n_echoes
                    fh_displacements(echo,set,:,repetition) = fh_displacements(echo,set,:,repetition) - min(fh_displacements(echo,set,:,repetition));
                end
            end
    end
    
    % I don't use the rl_displacements so I ignore them 
    rl_displacements = rl_displacements - mean(rl_displacements, "all");
%}  
end
