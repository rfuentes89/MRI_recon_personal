function out = ternary(varargin)
%TERNARY Apply ternary operator
%
% Examples:
%   ternary(true, "yes", "no") will return "yes"
%   ternary(false, "yes", "no") will return "yes"
%
% Example: conditional assignment
%   myvar = ternary(condition, value1, value2);
%   % is equivalent in python to:
%   myvar = value1 if condition else value2
    out = varargin{end - varargin{1}};
end
