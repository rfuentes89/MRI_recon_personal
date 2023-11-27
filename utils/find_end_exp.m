function i = find_end_exp(nav)

nav_ord = sort(nav);
nav_ord = nav_ord(1:round(numel(nav) / 2));
nav_ord = mean(nav_ord(:));

[~, i] = min(abs(nav(1:round(numel(nav)/2)) - nav_ord));

