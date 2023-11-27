function [kdata] = sample_dataV2(kdata,At)

At = logical(sum(At,4));  At= repmat(At,[1 1 1 size(kdata,4)]);

kdata = kdata.*At;

end

