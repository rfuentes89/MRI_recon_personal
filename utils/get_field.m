function out = get_field(obj, field_name, default_value)
%GET_FIELD Access a field from a struct w/o error if doesnt exist
    if nargin < 3
        default_value = -1;
    end
    if isfield(obj, field_name)
        out = obj.(field_name);
    else
        out = default_value;
    end
end

