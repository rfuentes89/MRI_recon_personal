function res = mtimes(a,b)

% So far implemented for (3D+time) dimensions

% TODO(pdpino): check if we need to use the ref bin here!
ref_bin_idx = 1; % a.ref_bin_idx

if ~a.adjoint
    % Motion
    % Correct translations onto a chosen position
    res = zeros(size(b));
    for bbb = 1:size(b,4)
        TX = a.target_pos{ref_bin_idx}.X - a.target_pos{bbb}.X;
        TY = a.target_pos{ref_bin_idx}.Y - a.target_pos{bbb}.Y;
        res(:,:,:,bbb) = imtranslate(b(:,:,:,bbb),[TY, -TX]);
        %res(:,:,:,bbb) = affine_from_values_B(b(1:250,:,43,bbb),TX,TY,0,1,1,0,0);
    end
    % TV
    res = res(:,:,:,[2:end,end]) - res(:,:,:,:);
else
    res = b(:,:,:,[1,1:end-1]) - b(:,:,:,:);
    res(:,:,:,1) = -b(:,:,:,1);
    res(:,:,:,end) = b(:,:,:,end-1);
    % Correct translations back to original position
    for bbb = 1:size(b,4)
        TX = a.target_pos{ref_bin_idx}.X - a.target_pos{bbb}.X;
        TY = a.target_pos{ref_bin_idx}.Y - a.target_pos{bbb}.Y;
        res(:,:,:,bbb) = imtranslate(res(:,:,:,bbb),[-TY, TX]);
    end
 
end
