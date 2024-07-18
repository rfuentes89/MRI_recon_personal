function target_struct = fill_struct_values(target_struct, default_values)
%FILL_DEFAULT_STRUCT Fills an struct with default values if not present
%   Args:
%       - target_struct: struct with any field
%       - default_values: struct with default values
    if ~isstruct(target_struct), target_struct = struct(); end

    fields = fieldnames(default_values);
    for i_field = 1:numel(fields)
        field_name = fields{i_field};
        if ~isfield(target_struct, field_name)
            target_struct.(field_name) = default_values.(field_name);
        end
    end
end

