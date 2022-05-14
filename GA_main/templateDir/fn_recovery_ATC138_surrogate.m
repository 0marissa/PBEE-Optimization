function [FRT] = fn_recovery_ATC138_surrogate(control, x)
% FN_RECOVERY_ATC138_SURROGATE Runs ATC-138 functional recovery assessment
% using trained model

% ADD SURROGATE MODEL FOLDER TO PATH
% surr_filename = control.analysis_surr_name;
% surr_filepath = fullfile(, 'RecoverySurrogate.py');
% addpath(surr_filepath)

    switch(control.analysis_platform)
        case("hpc")
            % Run improveComonents in Python function, improveComponents()
            command = strcat('python3 RecoverySurrogate.py ',' "',regexprep(num2str(x),'\s+',','),'"')   
            [status,cmdout] = system(command);
            FRT = str2num(string(cmdout));

        case("local")
            % Run improveComonents in Python function, improveComponents()            
            command = strcat("'",control.pythonPath,"' ", "RecoverySurrogate.py", " ", regexprep(num2str(x),'\s+',','));
            [status,cmdout] = system(command);
            FRT = str2num(string(cmdout));
    end
    
end

