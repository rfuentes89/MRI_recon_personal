function sum_of_navigators = sum_navigators(navigators)
    n_total_navigators = numel(navigators);
    sum_of_navigators = zeros(size(navigators{1}));

    for i_navigator = 1:n_total_navigators
        sum_of_navigators = sum_of_navigators + mat2gray(abs(navigators{i_navigator}));
    end
end

