function [i] = find_25_75_end_exp_XMR(nav)

range25 = round(numel(nav)*0.50);
nav_ord = sort(nav,'ascend');
nav_ord = nav_ord(1:round(numel(nav)/2));
nav_ord = mean(nav_ord(:));

[~,i] = min(abs(nav(1:round(numel(nav)/2))-nav_ord));

end

