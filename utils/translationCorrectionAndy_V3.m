function kdata_corr = translationCorrectionAndy_V3(kdata, At, motion_info)

% Reshape shot information
AtFE = At;
% if ndims(AtFE )<=3
%     AtFE = repmat(AtFE,[1 1 1 size(kdata,1)]); 
%     AtFE = permute(AtFE,[4 1 2 3]);
% end

if any(sum(AtFE ,4) > 1)
    error('Shots are not mutually exclusive')
end

% Extract motion info 
Ty = motion_info.Ty;
Tx = motion_info.Tx;

if size(AtFE,4)>100
    nchunks = floor(size(AtFE,4)/100);
end

AffMats = zeros(3,3,size(AtFE,4));
% Create affine matrices
for nshots = 1:size(AtFE,4)
    [~,Affine_FH] = affine_from_values_B(eye(3),-Tx(nshots),-Ty(nshots),0,1,1,0,0);
    AffMats(:,:,nshots) = Affine_FH;
end

% Create grid and shifts
Nm = size(AffMats,3);
[d1, d2, d3, d4] = size(kdata);
d = [d1, d2, d3, d4];
[x,y,~] = ndgrid(linspace(-0.5,0.5-1/d(1), d(1)), linspace(-0.5,0.5-1/d(2), d(2)), linspace(-0.5,0.5-1/d(3), d(3)));
shifts_x = reshape(AffMats(1,end,:),[1 1 1 Nm]);
shifts_y = reshape(AffMats(2,end,:),[1 1 1 Nm]);

% Reshape shift into matrix for point-wise multiplication
phase = repmat(x,[1 1 1 Nm]).*repmat(shifts_x,[d(1:3), 1]) +  ...
        repmat(y,[1 1 1 Nm]).*repmat(shifts_y,[d(1:3), 1]);
phase = phase.*AtFE;
phase = sum(phase,4);  
phase = exp(2*pi*1i*phase) ;
kdata_corr = kdata.*repmat(phase,[1 1 1 d(4)]);








