function motion_curves = register_navigators(navigators)
    % Pre-process once
    navigators = cellfun(@(nav) rescale(nav, 0, 255), navigators, "UniformOutput", false);

    % Create empty motion curves
    [n_echoes, n_sets, n_repetitions, n_navigators] = size(navigators);
    motion_curves = cell(n_echoes, n_sets, n_repetitions);

    % Register to first navigator
    [optimizer_mono, metric_mono] = imregconfig("monomodal");
    optimizer_mono.GradientMagnitudeTolerance   = 1E-14;
    optimizer_mono.MinimumStepLength            = 1E-14;
    optimizer_mono.MaximumStepLength            = 1E-2;
    optimizer_mono.MaximumIterations            = 2000;
    optimizer_mono.RelaxationFactor             = 5E-1;

    for repetition = 1:n_repetitions
        for set = 1:n_sets
            for echo = 1:n_echoes
                reference = navigators{echo,set,repetition,1};
                fh = zeros(n_navigators, 1);
                rl = zeros(n_navigators, 1);
                parfor navigator = 1:n_navigators
                    tform = imregtform( ...
                        navigators{echo,set,repetition,navigator}, ...
                        reference, ...
                        "translation", ...
                        optimizer_mono, ...
                        metric_mono ...
                    );
                    
                    % displacement of each navigator is the inverse of the
                    % transformation to align it with the reference,
                    % but matlab convention is positive downwards, so the
                    % two corrections cancel in the foot-head 
                    fh(navigator) = tform.T(3,2);
                    rl(navigator) = -tform.T(3,1);
                end
                motion_curves{echo,set,repetition}.fh = fh;
                motion_curves{echo,set,repetition}.rl = rl;
            end
        end
    end

    % Find end expiration and register to end expiration
    [optimizer_mono, metric_mono] = imregconfig("monomodal");
    optimizer_mono.GradientMagnitudeTolerance   = 1E-14;
    optimizer_mono.MinimumStepLength            = 1E-14;
    optimizer_mono.MaximumStepLength            = 1E-2;
    optimizer_mono.MaximumIterations            = 2000;
    optimizer_mono.RelaxationFactor             = 5E-1;

    for repetition = 1:n_repetitions
        for set = 1:n_sets
            for echo = 1:n_echoes
                fh = motion_curves{echo,set,repetition}.fh;
                rl = motion_curves{echo,set,repetition}.rl;

                % Get the iNav that belongs to the first bin (end_expiration)
                [idx] = find_25_75_end_exp_descend(fh);
                reference_end_expiration = navigators{echo,set,repetition,idx};
                parfor navigator = 1:n_navigators
                    tform = imregtform( ...
                        navigators{echo,set,repetition,navigator}, ...
                        reference_end_expiration, ...
                        "translation", ...
                        optimizer_mono, ...
                        metric_mono ...
                    );
                    fh(navigator) = tform.T(3,2);
                    rl(navigator) = -tform.T(3,1);
                end
                motion_curves{echo,set,repetition}.fh = fh;
                motion_curves{echo,set,repetition}.rl = rl;
            end
        end
    end
end
