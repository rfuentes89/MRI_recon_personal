function maps = dictionary_matching(fingerprints, dictionary)    

    T1s = nan(size(fingerprints, 2:4));
    T2s = nan(size(fingerprints, 2:4));

    for kk = 1:size(fingerprints, 4)
        for jj = 1:size(fingerprints, 3)
            for ii = 1:size(fingerprints, 2)                
                [T1s(ii,jj,kk), T2s(ii,jj,kk)] = match_fingerprint(fingerprints(:,ii,jj,kk), dictionary);
            end
        end        
    end

    maps.T1 = T1s;
    maps.T2 = T2s;

end

function [T1, T2] = match_fingerprint(fingerprint, dictionary)

    residuals = squeeze(sum((fingerprint - dictionary.simulated_fingerprints) .^ 2));
    [~, linear_index] = min(residuals, [], 'all', 'linear');
    [T1_index, T2_index] = ind2sub(size(residuals), linear_index);
    T1 = dictionary.T1s_sampled(T1_index);
    T2 = dictionary.T2s_sampled(T2_index);

end