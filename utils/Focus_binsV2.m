function [kdata_OUT,At_bins] = Focus_binsV2(raw_data,At,motion_info,bins, apply_TL)
% Focus_binsV2. Splits raw data into multiple bins and applies
% translational correction to each bin (to the average position).
%
% Args:
%     - raw_data: cell with n_coils, array(nx,ny,nz)
%     - At: logical sampling matrix with size (nx,ny,nz,n_shots)
%     - motion_info: a struct with:
%         - fh: array of size n_shots with foot-head motion, will be used as navigator
%         - rl: array of size n_shots with right-left motion
%     - bins: cell with size n_bins, each with a struct with:
%         - lower: lower limit for data to be included in this bin
%         - upper: upper limit for data to be included in this bin

nav = motion_info.fh;
n_bins = numel(bins);
kdata_OUT = cell(n_bins, 1);
At_bins = cell(n_bins, 1);

% Focus ALL data onto each bin
for bbb = 1:n_bins
    curr_shots  = nav>=bins{bbb}.lower & nav<bins{bbb}.upper;

    % Save bin positions
    bin_At = At(:,:,:,curr_shots);
    At_bins{bbb} = sum(bin_At,4);

    if apply_TL
        %bin_mean_Tx = (bins{bbb}.lower + bins{bbb}.upper) / 2;
        bin_mean_fh = mean(motion_info.fh(curr_shots));
        bin_mean_rl = mean(motion_info.rl(curr_shots));

        bin_motion.fh = -(motion_info.fh - bin_mean_fh);
        bin_motion.rl = -(motion_info.rl - bin_mean_rl);

        % Andy's fast phase shift
        kdata_corr = translationCorrectionAndy_V3(raw_data, At, bin_motion);
        % NOTE: we need to correct all data (pass At instead of bin_At)
        % due to soft gating later: some data outside of the bin is also
        % used for the reconstruction, that data also needs to be corrected
    else
        kdata_corr = raw_data;
    end

    % Push data on bin level
    kdata_OUT{bbb} = kdata_corr;
end
