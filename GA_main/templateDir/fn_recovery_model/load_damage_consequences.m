function [damage_consequences] = load_damage_consequences(dmg_loss_dir, model_dir, n_stories, replacement_cost)
%LOAD_DAMAGE_CONSEQUENCES Function responsible for organizing
%building-scale consequences from FEMA P-58 analysis in Pelicun

% Load FEMA P58 Results
DL_summary_data = readtable('DL_summary.csv','ReadVariableNames',true );
RC_matrix = readmatrix('DV_rec_cost_agg.csv');

% Simulation information
n_sims = height(DL_summary_data);

% Red tag
damage_consequences.red_tag = DL_summary_data{:,'red_tagged_'};
damage_consequences.red_tag(isnan(damage_consequences.red_tag)) = 1;
damage_consequences.red_tag = logical(damage_consequences.red_tag);

% Global Failure
collapse_sims = DL_summary_data{:,'collapses_collapsed'};
irreperable_sims = DL_summary_data{:,'reconstruction_irreparable'};
damage_consequences.global_fail = logical((collapse_sims == 1) | (irreperable_sims == 1));

% racked_stair_doors_per_story - [NOT MODELED]
damage_consequences.racked_stair_doors_per_story = zeros(n_sims,n_stories);

% racked_entry_doors_side_1 - [NOT MODELED]
damage_consequences.racked_entry_doors_side_1 = zeros(n_sims,1);

% racked_entry_doors_side_2 - [NOT MODELED]
damage_consequences.racked_entry_doors_side_2 = zeros(n_sims,1);

% inspection_trigger - [NOT MODELED]
damage_consequences.inpsection_trigger = logical(zeros(n_sims,1));

% Repair cost ratio
damage_consequences.repair_cost_ratio = zeros(n_sims,1);
damage_consequences.repair_cost_ratio(~damage_consequences.global_fail) = sum(RC_matrix(:,2:end),2)./replacement_cost;
damage_consequences.repair_cost_ratio(damage_consequences.global_fail) = 1;

end

