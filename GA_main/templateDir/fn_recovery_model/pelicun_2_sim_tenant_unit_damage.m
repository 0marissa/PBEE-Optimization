function [tenant_units] = pelicun_2_sim_tenant_unit_damage(dmg_loss_dir, model_dir)

% Load Pelicun formatted results
% addpath('performance model v2')

nstories = 3;

%  Set filename
DL_summary_filename = [dmg_loss_dir filesep 'DL_summary.csv' ];
DL_summary_stats_data = readmatrix(DL_summary_filename);
%n_sims = height(DL_summary_stats_data);
n_sims = size(DL_summary_stats_data,1);
simVector = [0:1:n_sims-1]';

DMG_filename = [dmg_loss_dir filesep 'DMG.csv' ];
RT_filename =  [dmg_loss_dir filesep 'DV_rec_time.csv'];
RC_filename =  [dmg_loss_dir filesep 'DV_rec_cost.csv'];

perf_model_filename = [dmg_loss_dir filesep 'LowRise_PM_v2.csv'];

%  Load sample Pelicun output
DMG_Data = readtable(DMG_filename,'HeaderLines', 0,'ReadVariableNames', false, 'format', 'auto','ReadRowNames', true);
DMG_Data_array = readmatrix(DMG_filename,'HeaderLines', 3);
RT_Data_array = readmatrix(RT_filename,'HeaderLines', 3);
RC_Data_array = readmatrix(RC_filename,'HeaderLines', 3);
perf_model = readtable(perf_model_filename,'ReadRowNames', true,'HeaderLines', 1);

DMG_sim = DMG_Data_array(:,1);
RT_sim = RT_Data_array(:,1);
RC_sim = RC_Data_array(:,1);

DMG_sim_rep = ismissing(simVector,DMG_sim);
RT_sim_rep = ismissing(simVector,RT_sim);
RC_sim_rep = ismissing(simVector,RC_sim);

DMG_Data_array = DMG_Data_array(:,2:end);
RT_Data_array = RT_Data_array(:,2:end);
RC_Data_array = RC_Data_array(:,2:end);


% Load all component damage states
comp_ds_filename = [model_dir filesep 'comp_ds_list_pelicun.csv'];
componentTable = readtable(comp_ds_filename,'HeaderLines', 0,'ReadVariableNames', false, 'format', 'auto','ReadRowNames', true);
num_columns = width(componentTable(1,:));

    
%  For each component damage state in the performance model
for s = 1:nstories          % asssume each story is a tenant unit
    
% Pre-populate arrays
tenant_units{s}.qnt_damaged  = zeros(n_sims, 1);
tenant_units{s}.cost         = zeros(n_sims, 1);
tenant_units{s}.worker_days  = zeros(n_sims, 1);  
    
    for i = 1:num_columns   % for each component damage state
    
    % Define DS for current component
    DS_seq = componentTable{2,i};
    DS_sub = componentTable{3,i};

    %  Define the column indicies to aggregate results on story-level basis for
    %  the damage state and component of interest.
    performanceGroup = string(DMG_Data{2,:});
    DGS_DS           = string(DMG_Data{3,:});
    DS_seq_index = extractBetween(DGS_DS,1,1) == string(DS_seq);
    DS_sub_index = extractBetween(DGS_DS,strlength(DGS_DS),strlength(DGS_DS)) == string(DS_sub);
    story_index = extractBetween(performanceGroup,strlength(performanceGroup)-1,strlength(performanceGroup)-1) == string(s);
    
    % Extra indicies for direction for use in quantity damaged on each
    % side of the building.
    dir1_index = extractBetween(performanceGroup,strlength(performanceGroup),strlength(performanceGroup)) == string(1);
    dir2_index = extractBetween(performanceGroup,strlength(performanceGroup),strlength(performanceGroup)) == string(2);

                % Story mataches                AND        Component matches        AND
                % DS Sequential matches         AND        DS sub matches
    comp_index = story_index & [string(DMG_Data{1,:}) == componentTable{1,i}]...
               & DS_seq_index & DS_sub_index;

    exterior_index  = componentTable{1,i} == "B2011.201a" || ...
                      componentTable{1,i} == "B2011.201b" || ...
                      componentTable{1,i} == "B2022.002";
           
    % If component performance group header in only single direction, then
    % component is not directional
    directional_check = sum([string(DMG_Data{1,:}) == componentTable{1,i}] & dir2_index);  
    
    % Indices to locate component columns to decouple directions
    direction_1_index = comp_index & dir1_index;
    direction_2_index = comp_index & dir2_index;
    
    %  Sum all quantities for a given component on the story of interest
    qty = sum(DMG_Data_array(:,comp_index),2); 
    cost = sum(RC_Data_array(:,comp_index),2);
    workerdays = sum(RT_Data_array(:,comp_index),2);
    
    qnt_damaged_side_1 = sum(DMG_Data_array(:,direction_1_index),2);
    qnt_damaged_side_3 = sum(DMG_Data_array(:,direction_2_index),2);
    
    % Insert desired FEMA P58 output here:
    %   story.qnt_damaged
    %   story.cost
    %   story.worker_days
    %   story.num_comps
    %   story.qnt_damaged_side_1
    %   story.qnt_damaged_side_3    
    
    tenant_units{s}.qnt_damaged(DMG_sim_rep,i) = qty;
    tenant_units{s}.cost(RC_sim_rep,i)         = cost;
    tenant_units{s}.worker_days(RT_sim_rep,i)  = workerdays;
    
    story_loc =[];
    switch(perf_model{componentTable{1,i} ,12}{1}) % check location(story) of component
        case 'all'
            story_loc = [1:nstories];
        case 'G'
            story_loc = [1];
        case 'even'
            story_loc = [2:2:nstories];            
        case '2toR'
            story_loc = [2:nstories];
        case 'R'
            story_loc = [nstories];
    end
    
    if(ismember(s,story_loc))
        tenant_units{s}.num_comps(1,i) = perf_model{componentTable{1,i},14} .* perf_model{componentTable{1,i},9};
    else
        tenant_units{s}.num_comps(1,i) = 0;
    end
        
    if(directional_check > 0 && exterior_index == 1) % If component is directional facade
        tenant_units{s}.qnt_damaged_side_1(DMG_sim_rep,i) = qnt_damaged_side_1;
        tenant_units{s}.qnt_damaged_side_3(DMG_sim_rep,i) = qnt_damaged_side_3;  
    else                      % component is not directional
        tenant_units{s}.qnt_damaged_side_1(:,i) = NaN(n_sims,1);
        tenant_units{s}.qnt_damaged_side_3(:,i) = NaN(n_sims,1);          
    end
    
    % Not simulated: side 2 and 4:
        tenant_units{s}.qnt_damaged_side_2(:,i) = zeros(n_sims,1);
        tenant_units{s}.qnt_damaged_side_4(:,i) = zeros(n_sims,1);       
    
    end
%         disp(strcat("extracted story ", num2str(s)));
end


end
