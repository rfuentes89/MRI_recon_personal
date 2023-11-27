function [bins] = get_bins_const_dataV2(nav,nbins,binoverlap)
% get_bins_const_data divides the respiratory cycle into bins with the same
% ammount of data

% nav: 1D real vector
% nbins: integer > 1
% binoverlap: real ? [0,1]

bindata = floor(numel(nav)/nbins);
bin_step = diff(sort(nav,"descend")); %bin_step = min(bin_step(bin_step>0));

b2 = max(nav);
set_index = 1;
bins = zeros(nbins,2);
for nnn = 1:nbins       
    
    b1 = b2 + bin_step(set_index);
    currdata = numel(find(nav>=b1 & nav<=b2));
%    while (currdata<bindata)
    for iii = (set_index+1):numel(bin_step)
        b1 = b1 + bin_step(iii);
        currdata = numel(find(nav>=b1 & nav<=b2));
        if b1<= min(nav)
            break;
        end
        if currdata>bindata
            break;
        end
        
 %       end  
    end
    set_index = iii; 
    bins(nnn,1) = b1; bins(nnn,2) = b2;
    b2 = b1 + binoverlap*(b2-b1);
end
bins = bins(end:-1:1,:);
