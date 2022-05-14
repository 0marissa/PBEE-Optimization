function [i] = rouletteWheel(p)
% ROULETTEWHEEL - implementation of Roulette wheel selection

r = rand*sum(p);
c = cumsum(p);
i = find(r <= c, 1, 'first');

end

