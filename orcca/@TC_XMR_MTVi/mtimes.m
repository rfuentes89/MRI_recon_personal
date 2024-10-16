function res = mtimes(a,b)

% So far implemented for (3D+time) dimensions

ref_bin = a.ref_bin;

if ~a.adjoint
    % Motion
    % Correct translations onto a chosen position
    res = zeros(size(b));
    for bbb = 1:size(b,4)
        TX = a.target_pos{ref_bin}.X - a.target_pos{bbb}.X;
        TY = a.target_pos{ref_bin}.Y - a.target_pos{bbb}.Y;
        res(:,:,:,bbb) = imtranslate(b(:,:,:,bbb),[TY, TX]);
        % affine = = affine_from_values_B(TX,TY,0,1,1,0,0);
        % res(:,:,:,bbb) = resampleImage(b(1:250,:,43,bbb), ...
        %     getDeformationFieldFromAffine(b(1:250,:,43,bbb), affine));
    end
    % TV
    res = res(:,:,:,[2:end,end]) - res(:,:,:,:);
else
    res = b(:,:,:,[1,1:end-1]) - b(:,:,:,:);
    res(:,:,:,1) = -b(:,:,:,1);
    res(:,:,:,end) = b(:,:,:,end-1);
    % Correct translations back to original position
    for bbb = 1:size(b,4)
        TX = a.target_pos{ref_bin}.X - a.target_pos{bbb}.X;
        TY = a.target_pos{ref_bin}.Y - a.target_pos{bbb}.Y;
        res(:,:,:,bbb) = imtranslate(res(:,:,:,bbb),[-TY, -TX]);
    end

end
