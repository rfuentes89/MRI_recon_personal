function deformation_field = displacement_to_deformation(displacement_field)
% Transforms displacement fields to deformation fields
% 
% - displacement fields = delta
% - deformation fields = original position + delta
%
% This function was previously named Add_mesh_to_DF
    [fh_size,rl_size,ap_size,dims] = size(displacement_field);
    assert(dims == 3);
    
    % Note: the order here must be [RL, FH, AP], because matlab's meshgrid
    % uses this order (first param is columns, second param is rows)
    [grid_rl,grid_fh,grid_ap] = meshgrid(1:rl_size,1:fh_size,1:ap_size);

    % Note: the order here must be [FH, RL, AP], because that's the order
    % in the DFs
    grid_full = cat(4, grid_fh, grid_rl, grid_ap);

    % Deformation = position + displacement
    deformation_field = grid_full + displacement_field;
end