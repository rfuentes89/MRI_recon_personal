function selected_for_rating = select_for_coil_rating(data)

    % Do SOS reconstruction using all coils for all echo/set/repetition
    % Visualise all in a grid (because one dimension should have size one
    % with current sequences)
    % Select image with the most homogenous contrast
    % Return echo/set/repetition indices for selected image    

    images = cell(size(data.k_spaces));

    [n_echoes, n_sets, n_repetitions] = size(data.k_spaces);

    for repetition = 1:n_repetitions
        for set = 1:n_sets
            for echo = 1:n_echoes
                coil_images = ktoi(data.k_spaces{echo,set,repetition}, 1:3);
                images{echo,set,repetition} = flip(flip(flip(sum(abs(coil_images) .^ 2, 4), 1), 2), 3);
            end
        end
    end

    peak_intensity = max(cellfun(@(image) max(image, [], "all"), images), [], "all");

    x = n_echoes;
    x_label = "echo";

    if n_repetitions == 1
        y = n_sets;
        y_label = "set";
    else % n_sets == 1
        y = n_repetitions;
        y_label = "repetition";
    end

    images = squeeze(images); % remove either sets or repetitions dimension

    if y > x
        [y, x] = deal(x, y); % swap values of x and y so x is largest
        [y_label, x_label] = deal(x_label, y_label);        
    else
        images = images.'; % ensures smallest dimension comes first
    end

    n_slices = size(data.k_spaces{1,1,1}, 3);
    current_slice = floor(n_slices / 2);

    figure("WindowScrollWheelFcn", @change_slice, "CloseRequestFcn", @save_and_close)

    layout = tiledlayout(y, x);
    if x > 1
        layout.XLabel.String = x_label;
    end
    if y > 1
        layout.YLabel.String = y_label;
    end

    selected_image = [];
    draw_all();
    
    uicontrol( ...
        "Style", "pushbutton", ...
        "String", "save", ...
        "Callback", @save_and_close ...
    );
    
    waitfor(gcf)

    function draw_all()
        for row = 1:y
            for column = 1:x
                nexttile(column + x * (row - 1));
                current_image = imshow(images{row, column}(:,:,current_slice), [0, peak_intensity]);
                current_image.ButtonDownFcn = {@select_image, row, column};
                if ~isempty(selected_image) ...
                && row == selected_image.row ...
                && column == selected_image.column
                    add_border(gca);
                end
            end
        end
    end

    function add_border(axes)
        axes.XTick = [];
        axes.YTick = [];
        axes.XAxis.Color = "red";
        axes.XAxis.LineWidth = 3;
        axes.YAxis.Color = "red";
        axes.YAxis.LineWidth = 3;
        axes.Box = "on";
        axes.Visible = "on";
    end

    function select_image(~, ~, row, column)
        selected_image.row = row;
        selected_image.column = column;
        draw_all();
    end
    
    function change_slice(~, scroll_wheel_data)
        scroll_amount = scroll_wheel_data.VerticalScrollCount;
        % TODO: which scroll direction should move which way through the
        % slices?
        % scroll_amount > 0 => downward scroll
        current_slice = min(max(current_slice + scroll_amount, 1), n_slices);
        draw_all();
    end

    function save_and_close(~, ~)

        if isempty(selected_image)
            warndlg("please select an image")
            return
        end

        selected_for_rating.echo       = 1;
        selected_for_rating.set        = 1;
        selected_for_rating.repetition = 1;

        switch x_label
            case "echo"
                selected_for_rating.echo = selected_image.column;
            case "set"
                selected_for_rating.set = selected_image.column;
            case "repetition"
                selected_for_rating.repetition = selected_image.column;
            otherwise
                assert(false)
        end

        switch y_label
            case "echo"
                selected_for_rating.echo = selected_image.row;
            case "set"
                selected_for_rating.set = selected_image.row;
            case "repetition"
                selected_for_rating.repetition = selected_image.row;
            otherwise
                assert(false)
        end

        delete(gcf)        
    end


end

