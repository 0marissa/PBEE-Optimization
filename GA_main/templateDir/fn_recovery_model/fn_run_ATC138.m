function [REOC_T, FRT, functionality] = fn_run_ATC138(model_name, save_output, impeding_factors, mainDir, n_stories, replacement_cost)
% fn_recovery_ATC138: function to pre-process inputs, run, and post-process
% ATC-138 Beta (v1.1.1) results
%
% modified from github: PBEE-Recovery/driver_PBEErecovery.m

% This script facilitates the performance based functional recovery and
% reoccupancy assessment of a single building for a single intensity level

% Input data consists of building model info and simulated component-level
% damage and conesequence data for a suite of realizations, likely assessed
% as part of a FEMA P-58 analysis. Inputs are read in as matlab variables
% direclty from matlab data files.

% Output data is saved to a specified outputs directory and is saved into a
% single matlab variable as at matlab data file.

%% Define User Inputs
                        % inputs are expected to be in a directory with this name
                        % outputs will save to a directory with this name

recovery_dir = [mainDir filesep 'fn_recovery_model'];
dmg_loss_dir = [mainDir filesep 'fn_FEMAP58'];
model_dir    = [recovery_dir filesep 'inputs'  filesep model_name]; % Directory where the simulated inputs are located
outputs_dir  = [recovery_dir filesep 'outputs' filesep model_name]; % Directory where the assessment outputs are saved

%% Import Packages
import recovery.repair_schedule.main_repair_schedule
import recovery.functionality.main_functionality
import recovery.impedance.main_impeding_factors

%% Load required static data
systems = readtable([recovery_dir filesep 'static_tables' filesep 'systems.csv']);
subsystems = readtable([recovery_dir filesep 'static_tables' filesep 'subsystems.csv']);
impeding_factor_medians = readtable([mainDir filesep 'fn_recovery_model' filesep 'static_tables' filesep 'impeding_factors.csv']);

%% Pre-process FEMA P-58 performance model data and simulated damage and loss
build_simulatedinputs(recovery_dir, dmg_loss_dir, model_dir, outputs_dir, n_stories, replacement_cost);

%% Load building model
building_model = load_building_model();

%% Load FEMA P-58 performance model data and simulated damage and loss
load([outputs_dir filesep 'simulated_inputs.mat'])

switch(impeding_factors)
    case 0
        impedance_options.include_impedance.inspection = false;
        impedance_options.include_impedance.financing = false;
        impedance_options.include_impedance.permitting = false;
        impedance_options.include_impedance.engineering = false;
        impedance_options.include_impedance.contractor = false;
    case 1
        impedance_options.include_impedance.inspection = true;
        impedance_options.include_impedance.financing = true;
        impedance_options.include_impedance.permitting = true;
        impedance_options.include_impedance.engineering = true;
        impedance_options.include_impedance.contractor = true;
    otherwise        
        warning('Unexpected impeding factor flag entered.')
end
%% Combine compoment attributes into recovery filters to expidite recovery assessment
[damage.fnc_filters] = fn_preprocessing(damage.comp_ds_table);

%% Simulate ATC 138 Impeding Factors
[functionality.impeding_factors] = main_impeding_factors(damage, impedance_options, ...
    damage_consequences.repair_cost_ratio, damage_consequences.inpsection_trigger, ...
    systems, building_model.building_value, impeding_factor_medians, regional_impact.surge_factor); 

%% Construct the Building Repair Schedule
% [damage, functionality.worker_data, functionality.building_repair_schedule ] = ...
%     main_repair_schedule(damage, building_model, damage_consequences.red_tag, ...
%     repair_time_options, systems, functionality.impeding_factors, regional_impact.surge_factor);

[damage, functionality.worker_data, functionality.building_repair_schedule ] = ...
    main_repair_schedule( damage, building_model, damage_consequences, damage_consequences.red_tag, repair_time_options, ...
    systems, functionality.impeding_factors, regional_impact.surge_factor);

%% Calculate the Recovery of Building Reoccupancy and Function
[ functionality.recovery ] = main_functionality( damage, building_model, ...
    damage_consequences, functionality.utilities, functionality_options, ...
    tenant_units, subsystems );

%% Save Outputs
if(save_output == true)
    if ~exist(outputs_dir,'dir')
        mkdir(outputs_dir)
    end
    save([outputs_dir filesep 'recovery_outputs.mat'],'functionality')
    fprintf('Recovery assessment of model %s complete\n',model_name)
end

% Store results for later use.
FRT.functionality = functionality;

% Store results for later use.
REOC_T.tenPer = prctile(functionality.recovery.reoccupancy.building_level.recovery_day,10);
REOC_T.fiftyPer = prctile(functionality.recovery.reoccupancy.building_level.recovery_day,50);
REOC_T.ninetyPer = prctile(functionality.recovery.reoccupancy.building_level.recovery_day,90);
REOC_T.max = prctile(functionality.recovery.reoccupancy.building_level.recovery_day,100);

FRT.tenPer = prctile(functionality.recovery.functional.building_level.recovery_day,10);
FRT.fiftyPer = prctile(functionality.recovery.functional.building_level.recovery_day,50);
FRT.ninetyPer = prctile(functionality.recovery.functional.building_level.recovery_day,90);
FRT.max = prctile(functionality.recovery.functional.building_level.recovery_day,100);



end

