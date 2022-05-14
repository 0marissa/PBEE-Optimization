function [RT] = fn_run_FEMAP58(analysis_platform, inputFileName, EDPPath, pythonPath, pelicunDLPath)
% FEMAP58RT Runs FEMA P58 Damage and loss assessment and computes the
% sequential repair time.

% SETTINGS - modifies command line instructions
switch(analysis_platform)
    case("hpc")
        command = strcat("python3"," ", pelicunDLPath, " ", '"--filenameDL"',...
                  " ", inputFileName, " ", '"--filenameEDP"', " ", EDPPath, " ", '"--outputEDP" "EDP.csv"',...
                  " ", '"--outputDM" "DM.csv"', " ",  '"--outputDV" "DV.csv" "--detailed_results" "true"')
    case("local")
        command = strcat(pythonPath," ", pelicunDLPath, " ", '"--filenameDL"',...
                  " ", inputFileName, " ", '"--filenameEDP"', " ", EDPPath, " ", '"--outputEDP" "EDP.csv"',...
                  " ", '"--outputDM" "DM.csv"', " ",  '"--outputDV" "DV.csv" "--detailed_results" "true"')   
end
                  
[status,cmdout] = system(command);

% Extract results from DL_summary_stats.csv
DL = readtable('fn_FEMAP58/DL_summary_stats.csv');
 
% Store FEMAP58 sequential repair time metric 
% 1 = 'count'
% 2 = 'mean'
% 3 = 'std'
% 4 = 'min'
% 5 = '10%'
% 6 = '50%'
% 7 = '90%'
% 8 = 'max'

RT_seq = DL.reconstruction_time_sequential;

RT.count = RT_seq(1);
RT.mean = RT_seq(2);
RT.std = RT_seq(3);
RT.min = RT_seq(4);
RT.tenPer = RT_seq(5);
RT.fiftyPer = RT_seq(6);
RT.ninetyPer = RT_seq(7);
RT.max = RT_seq(8);
end

