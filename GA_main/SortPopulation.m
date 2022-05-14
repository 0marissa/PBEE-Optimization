function pop = SortPopulation(pop)
% SORTPOPULATION - sorts population in increasing order of cost
% sorts population (parents and children) by increasing fitness.

    [~, so] = sort([pop.Cost]);
    pop = pop(so);
    
end