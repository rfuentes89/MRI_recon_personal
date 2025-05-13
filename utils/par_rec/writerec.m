function writerec(fname,data,format)

% save REC file
% format : optional, 'uint16' by default
% Claudia Prieto
tmp1 = 1:ndims(data);

tmp = tmp1; tmp(1) = tmp1(2);  tmp(2) = tmp1(1);
data = permute(data,tmp);

% data = data/max(data(:))*10000;

if (nargin == 2)
  format = 'uint16';
end

pid = fopen(fname,'w');
if (pid == -1),
    error('could not create file...');
end
%fwrite(pid,[data(:)],format);   %[data(:); data(:)]
fwrite(pid,data(:),format);   %[data(:); data(:)]
fclose(pid);

