function [out] = fn_optimize(control, problem, params)
% fn_optimize 
%

disp("Running functional recovery optimization framework ");

% Navigate to template directory
cd 'templateDir'

% Set the user-defined analysis_nsim value
status = copyfile('fn_FEMAP58/input_template.json', 'fn_FEMAP58/input.json', 'f');
updatedJSON = fileread('fn_FEMAP58/input.json');
updatedJSON = strrep(updatedJSON,'"Realizations":""',strcat('"Realizations":"',control.analysis_nsim,'"'));
fid = fopen('fn_FEMAP58/input.json', 'w');
fprintf(fid, '%s', updatedJSON);
fclose(fid);
cd ..

% Problem
objFunction = problem.objFunction;
nVar = problem.nVar;
VarSize = [1, nVar];
VarMin = problem.VarMin;
VarMax = problem.VarMax;

% Params
MaxIt = params.MaxIt;
nPop = params.nPop;
beta = params.beta;
pC = params.pC;
nC = round(pC*nPop/2)*2;
mu = params.mu;
sigma = params.sigma;

% Template for Empty Individuals
empty_individual.Position = [];            % Store the position
empty_individual.Cost = [];                % Store the cost
empty_individual.RT = [];                  % Store the recovery time
empty_individual.functionality = [];       % Store the functionality structure


% Best Solution Ever Found
bestsol.Cost = inf;
bestsol.RT = inf;
bestsol.functionality = [];

% Initialization
pop = repmat(empty_individual, nPop, 1);
cost_hist = [];
it_hist = [];

% switch(control.analysis_platform)
%     case "hpc"
%         parpool('local', str2num(getenv('SLURM_CPUS_PER_TASK')))
%     case "local"
%         parpool('local')
% end

% Create temporary folders for Pelicun to run parallel FEMA-P58 and ATC-138
% analyses. The number of folders should equal the number of children.

%parfor i = 1:nC
for i = 1:nC

    % Create workDir folders using template.
    tempFileName = strcat('workDir_',num2str(i));
    copyfile('templateDir',tempFileName)
    disp(strcat("workDir ",num2str(i)," created"));
end
    disp(strcat("all workDir folders created"));

mainDir = pwd;

disp(strcat("Generating initial population of size ", num2str(nPop)));

for i = 1:nPop

    % Return to main directory.
    cd(mainDir)

    % Generate Random Solution
    if(i==1)
        pop(i).Position = problem.InitialDesign;
    else
        pop(i).Position = unifrnd(VarMin, VarMax, VarSize);
    end
    
    % Restrict to 2 decimal place.
    pop(i).Position = round(pop(i).Position,2);
    
    % Evalute fitness function in temporary directory to avoid overlapping
    % access of resources.
    tempFileName = strcat('workDir_',num2str(i));
    cd(tempFileName)
    
    % Set baseDir to temporary directory for purposes of evaluating the objective function.  
    baseDir = pwd;
    
    % Evaluate the objective function in the temporary directory.
    [pop(i).Cost pop(i).RT pop(i).functionality] = objFunction(pop(i).Position, pwd);
    
    % Return to main directory.
    cd(mainDir)

end

    % Compare Solution to Best Solution Ever Found
for i = 1:nPop
    
    if pop(i).Cost < bestsol.Cost
        bestsol = pop(i);
    end
    
end

% Best Cost of Iterations
bestcost = nan(MaxIt, 1);
bestpos_hist = nan(MaxIt,nVar);
bestpos_RT = nan(MaxIt,1);


disp("Entering main loop")

% Main Loop
for it = 1:MaxIt
    
disp(strcat("Initiating generation #", num2str(it)))
    
    tic
 %% Update lambda based on the current population 
    
    % Selection Probabilities
    c = [pop.Cost];
    avgc = mean(c);
    if avgc ~= 0
        c = c/avgc;
    end
    probs = exp(-beta*c);

    % Initialize Offsprings Population
    popc = repmat(empty_individual, nC/2, 2);

    % Crossover
    for k = 1:nC/2

        % Select Parents
        p1 = pop(Tournament(probs));
        p2 = pop(Tournament(probs));
            
        % Perform Crossover
        [popc(k, 1).Position, popc(k, 2).Position] = ...
            SBXcrossover(p1.Position, p2.Position, nVar);

    end

    % Convert popc to Single-Column Matrix
    popc = popc(:);

    % Mutation
    for l = 1:nC

        % Return to main directory.
        cd(mainDir)

        % Perform Mutation
        popc(l).Position = mutate(popc(l).Position, mu, sigma);

        % Check for Variable Bounds
        popc(l).Position = max(popc(l).Position, VarMin);
        popc(l).Position = min(popc(l).Position, VarMax);
        
        % Restrict to 2 decimal place.
        popc(l).Position = round(popc(l).Position,2);

        % Evalute fitness function in temporary directory to avoid overlapping
        % access of resources.
        tempFileName = strcat('workDir_',num2str(l));
        cd(tempFileName)

        % Set baseDir to temporary directory for purposes of evaluating the objective function.  
        baseDir = pwd;

        % Evaluate the objective function in the temporary directory.
        [popc(l).Cost, popc(l).RT popc(l).functionality] = objFunction(popc(l).Position, pwd);

        % Return to main directory.
        cd(mainDir)

        % Store in array for tracking.
        cost_hist = [cost_hist; popc(l).Cost];
        it_hist = [it_hist; it];
        
    end

    % Compare Solution to Best Solution Ever Found
    for l = 1:nC

        if popc(l).Cost < bestsol.Cost
            bestsol = popc(l);
        end

    end    

    % Merge (parents and children) and Sort combined populations
    pop = SortPopulation([pop; popc]);

    % Remove unfit individuals, keep population steady at nPop
    pop = pop(1:nPop);
   
    
%%
    % Update best cost of current iteration
    bestcost(it) = bestsol.Cost;
    bestpos_hist(it,:) = double(bestsol.Position);
    x = bestpos_hist(it,:);
    
    % Store repair time associated with this iteration.
    bestpos_RT(it) = bestsol.RT;
    
    % Display Itertion Information
    disp(['Iteration ' num2str(it) ': Best Cost = ' num2str(bestcost(it))]);
    disp(bestsol)
    
    % Save output as csv file
    fileName = strcat('resultsIP','.csv')
    writematrix([bestpos_hist, bestcost, bestpos_RT], fileName)     
    
    % Save cost history as csv file
    fileName = strcat('cost_history_IP','.csv')
    writematrix([it_hist, cost_hist], fileName)   
    
    % Save functionality as .mat
    save(strcat('functional_recovery_best_',num2str(it),'.mat'), 'bestsol')
    toc
end


% Results
out.pop          = pop;
out.bestsol      = bestsol;
out.bestpos_hist = bestpos_hist;
out.bestcost     =  bestcost;
out.RT           = bestpos_RT;

end

