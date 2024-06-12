function data = read_raw_data(twix, selected_contrasts, selected_coils)

    coil_IDs = get_coil_IDs(twix);

    twix = twix{end};
    unsorted_data = twix.image.unsorted(); % all data in acquisition order

    n_readouts = twix.image.NAcq; % Number of readouts acquired
    n_segments = twix.image.NSeg; % Number of acquisition windows (heartbeats, iNavs)

    n_k_x         = twix.image.NCol; % Number of samples in each readout
    n_k_y         = twix.image.NLin; % Number of phase encoding lines
    n_k_z         = twix.image.NPar; % Number of slices
    n_echoes      = twix.image.NEco; % Number of echoes
    n_sets        = twix.image.NSet; % Number of interleaved contrasts
    n_repetitions = twix.image.NRep; % Number of sequential contrasts (cardiac phases)

    specified_n_x = try_fields(twix.hdr.Config, "NImageCols", "N0FImageColumns");
    specified_n_y = try_fields(twix.hdr.Config, "NImageLins", "N0FImagesLines");
    specified_n_z = try_fields(twix.hdr.Config, "NImagePar", "N0FImagePartitions", "NPar");
    
    n_coils = size(unsorted_data, 2); % Number of coils

    k_space_dimensions = [n_k_x, n_k_y, n_k_z];
    specified_image_dimensions = [specified_n_x, specified_n_y, specified_n_z];
    
    % Location of the centre of K-space
    central_k_x = twix.image.centerCol(1);
    central_k_y = twix.image.centerLin(1);
    central_k_z = twix.image.centerPar(1);
    
    k_space_centre = [central_k_x, central_k_y, central_k_z];

    k_y_at_readout = double(twix.image.Lin); % ky coordinate of each readout
    k_z_at_readout = double(twix.image.Par); % kz coordinate of each readout
    
    segment_at_readout = double(twix.image.Seg); % number of heart beat when each 
                                              % readout was acquired
    set_at_readout  = double(twix.image.Set);
    echo_at_readout = double(twix.image.Eco);
    repetition_at_readout = double(twix.image.Rep);

    if isempty(selected_contrasts.sets)
        selected_contrasts.sets = 1:n_sets;
    end
    if isempty(selected_contrasts.echoes)
        selected_contrasts.echoes = 1:n_echoes;
    end
    if isempty(selected_contrasts.repetitions)
        selected_contrasts.repetitions = 1:n_repetitions;
    end
    if isempty(selected_coils)
        selected_coils = 1:n_coils;
    end
    
    n_selected_coils = length(selected_coils);
    n_selected_echoes = length(selected_contrasts.echoes);
    n_selected_sets = length(selected_contrasts.sets);
    n_selected_repetitions = length(selected_contrasts.repetitions);

    scanner_software_version = twix.hdr.Dicom.SoftwareVersions;

    %% Unpack
    
    raw_k_space       = zeros(n_k_x, n_k_y, n_k_z, n_selected_coils, n_echoes, n_sets, n_repetitions);
    raw_segment_masks = false(1,     n_k_y, n_k_z, n_segments,       n_echoes, n_sets, n_repetitions);

    for readout = 1:n_readouts
        k_y = k_y_at_readout(readout);
        k_z = k_z_at_readout(readout);

        segment = segment_at_readout(readout);

        echo       = echo_at_readout(readout);
        set        = set_at_readout(readout);
        repetition = repetition_at_readout(readout);

              raw_k_space(:,k_y,k_z,:,      echo,set,repetition) = unsorted_data(:,selected_coils,readout);
        raw_segment_masks(1,k_y,k_z,segment,echo,set,repetition) = true;
    end

    % If the centre of k-space is not located in the centre of the matrix, we 
    % need to pad the kSpace & At matrices, so that centre of k-space is 
    % located in (Nx / 2 + 1, Ny / 2 + 1, Nz / 2 + 1)
    padded_k_space_dimensions = 2 * max(k_space_dimensions - k_space_centre + 1, k_space_centre - 1); % Size of the padded k-space
    base_offset = padded_k_space_dimensions / 2 - k_space_centre + 1;

    k_spaces = cell(n_selected_echoes, n_selected_sets, n_selected_repetitions);
    segment_masks = cell(n_selected_echoes, n_selected_sets, n_selected_repetitions);
    sampling_masks = cell(n_selected_echoes, n_selected_sets, n_selected_repetitions);
    for repetition = 1:n_selected_repetitions
        for set = 1:n_selected_sets
            for echo = 1:n_selected_echoes
                k_spaces{echo, set, repetition} = zeros([padded_k_space_dimensions, n_selected_coils]);
                segment_masks{echo, set, repetition} = false([padded_k_space_dimensions, n_segments]);

                % Need to handle asymmetric echoes here
                % On Free.Max (ver. XA50), all echoes acquire the same side of k space (makes sense right) so padding is consistent
                % On Aera/XMR (ver. E11C), odd and even echoes acquire different parts of k space (idk why), so padding is needed in different places
                % Behaviour of other versions is currently unverified
                switch scanner_software_version
                    case "syngo MR E11" % Aera
                        used_offsets = ternary(mod(echo, 2), base_offset, [0, 0, 0]);
                    case "syngo MR XA50" % Free.Max
                        used_offsets = base_offset;
                    otherwise
                        warning("unrecognised scanner: %s, defaulting to XA50 behaviour", scanner_software_version);
                        used_offsets = base_offset;
                end

                % Prepare aux variables
                x_range = used_offsets(1) + (1:n_k_x);
                y_range = used_offsets(2) + (1:n_k_y);
                z_range = used_offsets(3) + (1:n_k_z);
                sel_echo = selected_contrasts.echoes(echo);
                sel_set = selected_contrasts.sets(set);
                sel_rep = selected_contrasts.repetitions(repetition);

                % Actually copy data
                k_spaces{echo,set,repetition}(x_range,y_range,z_range,:) = raw_k_space(:,:,:,:,sel_echo,sel_set,sel_rep);
                segment_masks{echo,set,repetition}(x_range,y_range,z_range,:) = repmat(raw_segment_masks(1,:,:,:,sel_echo,sel_set,sel_rep), n_k_x, 1);
                sampling_masks{echo,set,repetition} = sum(segment_masks{echo,set,repetition}, 4);
            end
        end
    end

    %% Construct output

    data.kY                 = k_y_at_readout;
    data.kZ                 = k_z_at_readout;
    % raw_data.n_coils            = n_coils;

    data.padded_dimensions  = padded_k_space_dimensions;
    data.specified_image_dimensions = specified_image_dimensions; % To remove readout oversampling
    % raw_data.k_space_dimensions = k_space_dimensions; % TODO check if needed
    % raw_data.k_space_centre     = k_space_centre; % TODO check if needed
    % raw_data.dPad               = [offset_x, offset_y, offset_z]; % TODO check if needed

    data.k_spaces           = k_spaces;
    data.sampling_masks     = sampling_masks;
    data.segment_masks      = segment_masks;

    data.coil_IDs = coil_IDs;

    % Variables in this structure are used throughout the code, and may be
    % modified by the various stages. Any variables you add may also need
    % to be modified accordingly.

 end