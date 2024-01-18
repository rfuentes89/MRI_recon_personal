function kdata_corr = translationCorrectionAndy_V3(kdata, At, motion_info, params)
    if ~exist("params", "var"), params = struct(); end
    if ~isfield(params, "chunksize"), params.chunksize = 100; end
    if ~isfield(params, "force_chunks"), params.force_chunks = false; end
    if ~isfield(params, "force_nochunks"), params.force_nochunks = false; end

    % Split the data if it is too large
    if ~params.force_nochunks && (params.force_chunks || size(At,4) > params.chunksize)
        nchunks = floor(size(At,4)/params.chunksize);
        kdata_corr = zeros(size(kdata,1),size(kdata,2),size(kdata,3),size(kdata,4),nchunks+1);

        % Phase shift each chunk
        for ccc = 1:nchunks+1
            if ccc < nchunks + 1
                until_idx = params.chunksize*ccc;
            else
                until_idx = size(At,4);
            end

            curr_idx = 1+(params.chunksize*(ccc-1)):until_idx;
            curr_At =  At(:,:,:,curr_idx);
            curr_info.Tx = motion_info.Tx(curr_idx);
            curr_info.Ty = motion_info.Ty(curr_idx);
            curr_kdata = apply_translationCorrectionAndy_V3(kdata, curr_At, curr_info);
            kdata_corr(:,:,:,:,ccc) = sample_dataV2(curr_kdata, curr_At);
        end

        kdata_corr = sum(kdata_corr,5);
    else
        kdata_corr =  apply_translationCorrectionAndy_V3(kdata, At, motion_info);
    end
end


function kdata_corr = apply_translationCorrectionAndy_V3(kdata, At, motion_info)

    % Reshape shot information
    AtFE = At;

    if any(sum(AtFE ,4) > 1)
        error('Shots are not mutually exclusive')
    end

    % Extract motion info
    Ty = motion_info.Ty;
    Tx = motion_info.Tx;

    n_shots = size(AtFE, 4);
    assert(n_shots == numel(Tx), "n_shots mismatches with x motion: " + string(size(Tx)));
    assert(n_shots == numel(Ty), "n_shots mismatches with y motion: " + string(size(Ty)));

    AffMats = zeros(3,3,n_shots);
    % Create affine matrices
    for i_shot = 1:size(AtFE,4)
        [~,Affine_FH] = affine_from_values_B(eye(3),-Tx(i_shot),-Ty(i_shot),0,1,1,0,0);
        AffMats(:,:,i_shot) = Affine_FH;
    end

    % Create grid and shifts
    [d1, d2, d3, d4] = size(kdata);
    d = [d1, d2, d3, d4];
    [k_x,k_y,~] = ndgrid(linspace(-0.5,0.5-1/d(1), d(1)), linspace(-0.5,0.5-1/d(2), d(2)), linspace(-0.5,0.5-1/d(3), d(3)));
    shifts_x = reshape(AffMats(1,end,:),[1 1 1 n_shots]);
    shifts_y = reshape(AffMats(2,end,:),[1 1 1 n_shots]);

    % Reshape shift into matrix for point-wise multiplication
    phase = repmat(k_x,[1 1 1 n_shots]).*repmat(shifts_x,[d(1:3), 1]) +  ...
            repmat(k_y,[1 1 1 n_shots]).*repmat(shifts_y,[d(1:3), 1]);
    phase = phase.*AtFE;
    phase = sum(phase,4);
    phase = exp(2*pi*1i*phase) ;
    kdata_corr = kdata.*repmat(phase,[1 1 1 d(4)]);

end
