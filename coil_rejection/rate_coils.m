function [yes_indices, maybe_indices, no_indices] = rate_coils(data, selected)
    
    % reconstruct low-resolution images
    % open figure
    % show three slices (1/4, 1/2, 3/4)
    % buttons to rate yes/maybe/reject
    % buttons previous/next (coil)
    % make sure each coil is only given one rating
    % check all coils have been rated before saving
    % if so, close figure and return ratings

    % TODO position the buttons

    k_spaces = data.k_spaces{selected.echo,selected.set,selected.repetition};

    n_coils = size(k_spaces, 4);
    images = cell(n_coils, 1);

    for coil = 1:n_coils
        images{coil} = flip(flip(flip(ktoi(k_spaces(:,:,:,coil)), 1), 2), 3);
    end

    peak_intensity = max(cellfun(@(image) max(abs(image), [], "all"), images));

    n_slices = size(images{1}, 3);
    current_slice = floor(n_slices / 2);

    f = figure("WindowScrollWheelFcn", @change_slice, "CloseRequestFcn", @check_all_rated);

    rated_yes = false(n_coils, 1);
    rated_maybe = false(n_coils, 1);
    rated_no = false(n_coils, 1);

    show_phase = false;

    coil_list = uicontrol( ...
        "Position", [20 20 140 500], ...
        "Style", "listbox", ...
        "Max", n_coils, ...
        "Min", 1, ...
        "String", arrayfun(@(n) append("coil ", num2str(n), " (", data.coil_IDs(n) ,"): unrated"), (1:n_coils).'), ...
        "Callback", @draw ...
    );

    uicontrol( ...
        "Position", [180 20 60 20], ...
        "Style", "pushbutton", ...
        "String", "mag/phase", ...
        "Callback", @switch_images ...
    )

    uicontrol( ...
        "Position", [260 20 60 20], ...
        "Style", "pushbutton", ...
        "String", "yes", ...
        "Callback", @rate_yes ...
    )

    uicontrol( ...
        "Position", [340 20 60 20], ...
        "Style", "pushbutton", ...
        "String", "maybe", ...
        "Callback", @rate_maybe ...
    )

    uicontrol( ...
        "Position", [420 20 60 20], ...
        "Style", "pushbutton", ...
        "String", "no", ...
        "Callback", @rate_no ...
    )

    uicontrol( ...
        "Position", [500 20 60 20], ...
        "Style", "pushbutton", ...
        "String", "save", ...
        "Callback", @check_all_rated ...
    )

    draw()

    waitfor(gcf)

    function draw(~, ~)
        tiledlayout("flow");
        for ii = 1:numel(coil_list.Value)
            nexttile(ii);
            if show_phase
                current_image = imshow(angle(images{coil_list.Value(ii)}(:,:,current_slice)), [-pi, pi]);
            else
                current_image = imshow(abs(images{coil_list.Value(ii)}(:,:,current_slice)), [0, 0.8 * peak_intensity]);
            end            
            current_image.ButtonDownFcn = {@select_image, ii};
        end
    end

    function switch_images(~, ~)
        show_phase = ~show_phase;
        draw()
    end

    function next_coil(~, ~)
        coil_list.Value = min(max(coil_list.Value) + 1, n_coils);
        draw();    
    end

    function select_image(~, ~, index)
        coil_list.Value = coil_list.Value(index);
        draw();
    end

    function change_slice(~, scroll_wheel_data)
        scroll_amount = scroll_wheel_data.VerticalScrollCount;
        % TODO: which scroll direction should move which way through the
        % slices?
        % scroll_amount > 0 => downward scroll
        current_slice = min(max(current_slice + scroll_amount, 1), n_slices);
        draw();
    end

    function rate_yes(~, ~)
        rated_yes(coil_list.Value) = true;
        rated_maybe(coil_list.Value) = false;
        rated_no(coil_list.Value) = false;
        for n = coil_list.Value
            coil_list.String{n} = append("coil ", num2str(n), " (", data.coil_IDs(n) ,"): yes");
        end
        next_coil()
    end

    function rate_maybe(~, ~)
        rated_yes(coil_list.Value) = false;
        rated_maybe(coil_list.Value) = true;
        rated_no(coil_list.Value) = false;
        for n = coil_list.Value
            coil_list.String{n} = append("coil ", num2str(n), " (", data.coil_IDs(n) ,"): maybe");
        end
        next_coil()
    end

    function rate_no(~, ~)
        rated_yes(coil_list.Value) = false;
        rated_maybe(coil_list.Value) = false;
        rated_no(coil_list.Value) = true;
        for n = coil_list.Value
            coil_list.String{n} = append("coil ", num2str(n), " (", data.coil_IDs(n) ,"): no");
        end
        next_coil()
    end

    function check_all_rated(~, ~)
        all_rated_once = (sum(rated_yes + rated_maybe + rated_no) == n_coils);
        if all_rated_once
            save_and_close()
        else
            not_rated_indices = find((rated_yes + rated_maybe + rated_no) == 0);

            dialogbox = dialog('Position', [300 300 250 150], 'Name', 'My Dialog');

            uicontrol( ...
                'Parent', dialogbox,...
                'Style', 'text',...
                'Position', [20 80 210 40],...
                'String', sprintf("coils %s have not been rated", join(string(not_rated_indices), ', ')) ...
            );
 
            uicontrol( ...
                'Parent', dialogbox, ...
                'Position', [20 20 70 25], ...
                "Style", "pushbutton", ...
                'String', 'Go back', ...
                'Callback', @(~, ~) delete(dialogbox) ...
            );

            uicontrol( ...
                'Parent', dialogbox, ...
                'Position', [140 20 70 25], ...
                "Style", "pushbutton", ...
                'String', 'Close anyway', ...
                'Callback', @close_both ...
            );

            waitfor(dialogbox)
        end

        function close_both(~, ~)
            delete(dialogbox)
            save_and_close()        
        end

    end



    function save_and_close(~, ~)
        yes_indices = find(rated_yes);
        maybe_indices = find(rated_maybe);
        no_indices = find(rated_no);
        delete(f)
    end

end

 