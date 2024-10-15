function kdata_corr = translationCorrectionAndy_V3(kdata, AtFE, motion_info)
% translationCorrectionAndy_V3. Applies XY translation correction to kdata,
% to center at position = 0.
%
% Args:
%     - kdata: cell with n_coils, array(nx,ny,nz)
%     - At: logical sampling matrix with size (nx,ny,nz,n_shots)
%     - motion_info: a struct with:
%         - fh: array of size n_shots with foot-head motion
%         - rl: array of size n_shots with right-left motion
    if any(sum(AtFE ,4) > 1)
        error('Shots are not mutually exclusive')
    end

    % Extract motion info
    Ty = motion_info.rl;
    Tx = motion_info.fh;

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
