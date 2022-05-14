function [f_x, FRT_return, functionality] = objFunction(x, baseDir, control);
% objFunction 
% function used to map x_i input vector to recovery times.

% Analysis set-up
    % With each new analysis, create new folder (copy of original) for fragility modification
    status = copyfile('fn_FEMAP58/Fragility Data', 'fn_FEMAP58/Fragility Data with modifications', 'f');

% Create an a component array with indexed components (1,...,n)
    % Requires performance model.
    % Decode JSON input file containing performance model
    data = jsondecode(fileread('fn_FEMAP58/input.json'))';
    componentList = fieldnames(data.DamageAndLoss.Components);

    cd('fn_FEMAP58')
% Improve component fragilities using x_i
for i = 1:length(componentList)
   
    switch(control.analysis_platform)
        case("hpc")
            % Run improveComonents in Python function, improveComponents()
            componentName = strrep(componentList{i},'_','.');
            command = strcat('python3 pyFunctions.py', " ", num2str(x(i)), " ",componentName);    
            [status,cmdout] = system(command);
            
        case("local")
            % Run improveComonents in Python function, improveComponents()
            componentName = strrep(componentList{i},'_','.');
            %command = strcat("'",control.pythonPath," pyFunctions.py'", " ", num2str(x(i)), " ",componentName);    
            command = strcat('python3 pyFunctions.py', " ", num2str(x(i)), " ",componentName);
            [status,cmdout] = system(command);
    end
end
    cd(baseDir)

%% Run loss and recovery simulation
    
    switch(control.analysis_recovery_model)
    
        case("ATC138_sim")
            % Add to path
            addpath('fn_FEMAP58')
            addpath('fn_recovery_model')

            % Run FEMA-P58 
            [~] = fn_run_FEMAP58(control.analysis_platform, control.inputJSON_FEMAP58, control.inputEDP_FEMAP58, control.pythonPath, control.pelicunDLPath);

            % Run ATC-138 assessment
            [~, FRT, functionality] = fn_run_ATC138(control.model_name, control.save_output, control.analysis_impeding_factors, baseDir, control.n_stories, control.replacement_cost);
            cd(baseDir)

            % Retrun recovery time
            FRT_return = FRT.fiftyPer;  

        case("ATC138_surr")
            [    FRT] = fn_recovery_ATC138_surrogate(control, x); 
            FRT_return = FRT;
            functionality = 1;
    end
   
    cost = sum(x);
    f_x = cost + 10e7*max((FRT_return - control.opt_T_target) , 0)^2;
     
end

