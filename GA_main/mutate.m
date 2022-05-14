function y = mutate(x, mu, sigma)
% MUTATE implementation of mutation - each "bit" has a small probability
% of being mutated, in the form of zero-mean gaussian noise for
% real-coded GA

flag = (rand(size(x)) < mu);

y = x;

r = randn(size(x));
y(flag) = x(flag) + r(flag)*sigma;

end

