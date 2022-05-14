%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Functional Recovery optimization framework 
%   Program to aid recovery-based design (RBD) 
%   Main wrapper
%   Omar Issa, Stanford Urban Resilience Initaitive (SURI)
%   05/2022
%
%%%%%%%%%%%%%%%%%%%%%%%%9%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [] = fn_FRT_opt_fm_main(analysis_run_number, analysis_hazardLevel, analysis_nsim,  analysis_n_CPU, ...    
                                 analysis_impeding_factors, analysis_platform, opt_pop, opt_T_target)

analysis_type = "optimize"
% optimize

% Enter analysis settings
control.model_name         = 'LowriseWSMF';
control.save_output        = false;
control.n_stories          = 3;
control.replacement_cost   = 8018161;

% Enter desired number of samples
params.nCPUs     = str2num(analysis_n_CPU);

analysis_recovery_model = "ATC138_sim";
analysis_surr_name = "475_year"
% 72_year
% 475_year
% 2475_year

% analysis_platform = "local";
% local
% hpc

opt_method = "GA";
opt_max_iterations = "1000";
opt_percentile = "50";
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Store arguments in control structure
control.analysis_base_dir          = pwd;
control.analysis_type              = analysis_type;
control.analysis_run_number        = analysis_run_number;
control.analysis_platform          = analysis_platform;
control.analysis_nsim              = analysis_nsim;
control.analysis_recovery_model    = analysis_recovery_model;
control.analysis_surr_name         = analysis_surr_name;
control.analysis_impeding_factors  = str2num(analysis_impeding_factors);
control.analysis_hazardLevel       = str2num(analysis_hazardLevel);

control.opt_method                 = opt_method;
control.opt_max_iterations         = str2num(opt_max_iterations);
control.opt_percentile             = str2num(opt_percentile);
control.opt_T_target               = str2num(opt_T_target);
control.opt_pop                    = str2num(opt_pop);

% Note: python path only used if run locally
control.pythonPath        = "/opt/homebrew/Caskroom/miniforge/base/bin/python3";
control.inputJSON_FEMAP58 = '"fn_FEMAP58/input.json"';
control.pelicunDLPath     = '"fn_FEMAP58/performDL/pelicun/DL_calculation.py"';
control.inputEDP_FEMAP58  = '"input_EDPs/LowRise_Ie1_00_475RP_FN.csv"';

% Turn warning output off.
warning('off')

% Place MATLAB routine in base directory 

% Copy all contents of GA_main into new one.
newFolder = strcat(analysis_nsim, '_', analysis_run_number,'_',analysis_type,'_RP',analysis_hazardLevel,'_',analysis_recovery_model,'_P',opt_percentile,'_T',opt_T_target,'_Imp',analysis_impeding_factors,'_',analysis_platform);
status = copyfile('GA_main', newFolder, 'f');

% Change to analysis directory.
cd(newFolder)
baseDir = pwd;

% Load performance model compoennts
data = jsondecode(fileread('templateDir/fn_FEMAP58/input_template.json'))';
componentList = fieldnames(data.DamageAndLoss.Components);

% Define cost function and optimization boundaries
problem.objFunction = @(x, baseDir) objFunction(x, baseDir, control);
problem.nVar = length(componentList);
problem.InitialDesign = ones(1, problem.nVar);
problem.VarMin = 1 * ones(1, problem.nVar);
problem.VarMax = [1 * ones(1, 5),  3 * ones(1, 36)];

%% Genetic algorithm parameters
params.MaxIt = control.opt_max_iterations;    
params.nPop  = control.opt_pop;      
params.beta  = 1;        
params.pC    = 1;          
params.mu    = 10/100;  % Mutation rate
params.sigma = 0.1;     

%% Run selected analysis
out = fn_optimize(control, problem, params);

% Save output as csv file
fileName = strcat(opt_pop, '_', opt_max_iterations, '_', opt_T_target ,'.csv')
writematrix([out.bestpos_hist, out.bestcost, out.RT], fileName) 

% Remove all working directories at the end of analysis
rmdir('workDir_*', 's')

end