function result = try_fields(thing_with_fields, varargin)

    first_match = find(isfield(thing_with_fields, string(varargin)), 1);

    if isempty(first_match)
        error("no matching field found")
    end

    result = thing_with_fields.(varargin{first_match});

end

