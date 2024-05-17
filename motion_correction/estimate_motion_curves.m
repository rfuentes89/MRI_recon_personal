function motion_curves = estimate_motion_curves(twix, selected, base_fname)

    navigators = read_navigators(twix, selected);

    [fh_displacements, rl_displacements] = register_navigators(navigators, base_fname);
    
    % plot motion of all navigators in acquisition order
    hold on
    plot(fh_displacements(:))
    plot(rl_displacements(:))
    legend("fh", "rl")
    ylabel("pixels")
    
    % for rest of reconstruction it's more convenient to directly retrieve
    % the set of displacements corresponding to a particular contrast
    [n_echoes, n_sets, ~, n_repetitions]  = size(navigators);    
    motion_curves = cell(n_echoes, n_sets, n_repetitions);

    xlabel("motion in time (" + string(numel(motion_curves)) + " contrasts concatenated)");

    if exist("base_fname", "var")
        saveas(gcf, base_fname + "_curve.png");
    end

    for repetition = 1:n_repetitions
        for set = 1:n_sets            
            for echo = 1:n_echoes
                
                motion_curves{echo,set,repetition}.fh = squeeze(fh_displacements(echo,set,:,repetition));
                motion_curves{echo,set,repetition}.rl = squeeze(rl_displacements(echo,set,:,repetition));
                
            end
        end
    end
    
    

end