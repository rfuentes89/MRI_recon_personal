function images = reconstruct_it_SENSE(k_spaces, E_operators, params)
% RECONSTRUCTION_IT_SENSE Reconstruct a group of images using IT-SENSE
%
% Args:
%       - k_spaces: cell with n_contrasts to reconstruct
%       - E_operators: cell with n_contrasts, each with the operator passed
%         to CG-SENSE
%       - n_iter: number of CG-SENSE iterations
%       - verbose: CG-SENSE verbosity
    images = cell(size(k_spaces));
    n_images = numel(k_spaces);

    for i_image = 1:n_images
        timer_itsense = tic();
        images{i_image} = Cart_itSENSE( ...
            k_spaces{i_image}, ...
            E_operators{i_image}, ...
            params);
        fprintf("\t\t\t itsense iter() "); toc(timer_itsense);
    end
end
