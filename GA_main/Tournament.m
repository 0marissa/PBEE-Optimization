function [i] = Tournament(p)
% TOURNAMENT - implementation of Tournament selection

% r = rand*sum(p);
% c = cumsum(p);
% i = find(r <= c, 1, 'first');

% Select subset at random -> half of population
r = datasample(p,ceil(length(p)/2),'Replace',false);
i = find(max(r) == p, 1, 'first');

end

