function twix = read_twix(path)
%READ_TWIX Summary of this function goes here
%   Detailed explanation goes here
    [~, twix] = evalc("mapVBVD(convertStringsToChars(path))");
end

