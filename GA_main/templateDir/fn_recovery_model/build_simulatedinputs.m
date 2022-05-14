function [] = build_simulatedinputs(recovery_dir, dmg_loss_dir, model_dir, outputs_dir, n_stories, replacement_cost)
% build_simulatedinputs
% This function is organized into the following calculations:

    % Load required data tables

    % Tenant units
    % - load tenant_unit_list from file
    % - pull default tenant unit attributes

    % FEMA-P58 performance model and damage
    % - extract damage.tenant_units from raw FEMA-P58 (Pelicun) output
    % - extract damage_consequences from raw FEMA-P58 (Pelicun) output
    % - pull default component and damage state attributes for each component 

    % FEMA-P58 damage 
    % - extract simulated utilitiies from file (if applicable)

    % Optional input
    % - load optional inputs (if applicable)

%% Load required data tables

    component_attributes = readtable([recovery_dir filesep 'static_tables' filesep 'component_attributes.csv']);
    damage_state_attribute_mapping = readtable([recovery_dir filesep 'static_tables' filesep 'damage_state_attribute_mapping.csv']);
    subsystems = readtable([recovery_dir filesep 'static_tables' filesep 'subsystems.csv']);
    tenant_function_requirements = readtable([recovery_dir filesep 'static_tables' filesep 'tenant_function_requirements.csv']);
    
    % List of component and damage states in the performance model
    comp_ds_list = readtable([model_dir filesep 'comp_ds_list.csv']);

    
%% Tenant units
% Load tenant_unit_list from file
[tenant_unit_list] = readtable([model_dir filesep 'tenant_unit_list.csv']);

% Pull default tenant unit attributes for each tenant unit listed in the
% tenant_unit_list
tenant_units = tenant_unit_list;
for tu = 1:height(tenant_unit_list)
    fnc_requirements_filt = tenant_function_requirements.occupancy_id == tenant_units.occupancy_id(tu);
    if sum(fnc_requirements_filt) ~= 1
        error('Tenant Unit Requirements for This Occupancy Not Found')
    end
    tenant_units.exterior(tu) = tenant_function_requirements.exterior(fnc_requirements_filt);
    tenant_units.interior(tu) = tenant_function_requirements.interior(fnc_requirements_filt);
    tenant_units.occ_per_elev(tu) = tenant_function_requirements.occ_per_elev(fnc_requirements_filt);
    if tenant_function_requirements.is_elevator_required(fnc_requirements_filt) && ...
            tenant_function_requirements.max_walkable_story(fnc_requirements_filt) < tenant_units.story(tu)
        tenant_units.is_elevator_required(tu) = 1;
    else
        tenant_units.is_elevator_required(tu) = 0;
    end
    tenant_units.is_electrical_required(tu) = tenant_function_requirements.is_electrical_required(fnc_requirements_filt);
    tenant_units.is_water_required(tu) = tenant_function_requirements.is_water_required(fnc_requirements_filt);
    tenant_units.is_hvac_required(tu) = tenant_function_requirements.is_hvac_required(fnc_requirements_filt);
end

%% FEMA-P58 performance model and damage
% Extract damage.tenant_units from raw FEMA-P58 (Pelicun) output
    [tenant_unit_damage] = pelicun_2_sim_tenant_unit_damage(dmg_loss_dir, model_dir);
    damage.tenant_units = tenant_unit_damage;

% Extract damage_consequences from raw FEMA-P58 (Pelicun) output
    damage_consequences = load_damage_consequences(dmg_loss_dir, model_dir, n_stories, replacement_cost);

% Pull default component and damage state attributes for each component 
    % Pull default component and damage state attributes for each component 
    % in the comp_ds_list
    comp_idx = 1;
    for c = 1:height(comp_ds_list)
        % Basic Component and DS identifiers
        comp_ds_info.comp_id{c,1} = comp_ds_list.comp_id{c};
        comp_ds_info.comp_type_id{c,1} = comp_ds_list.comp_id{c}(1:5); % first 5 characters indicate the type
        if c > 1 && ~strcmp(comp_ds_info.comp_id{c},comp_ds_info.comp_id{c-1})
            % if not the same as the previous component
            comp_idx = comp_idx + 1;
        end
        comp_ds_info.comp_idx(c,1) = comp_idx;
        comp_ds_info.ds_seq_id(c,1) = comp_ds_list.ds_seq_id(c);
        comp_ds_info.ds_sub_id(c,1) = comp_ds_list.ds_sub_id(c);

        % Find idx of this component in the  component attribute tables
        comp_attr_filt = strcmp(component_attributes.fragility_id,comp_ds_info.comp_id{c,1});
        if sum(comp_attr_filt) ~= 1
            error('Could not find component attrubutes')
        end

        % Set Component Attributes
        comp_ds_info.system(c,1) = component_attributes.system_id(comp_attr_filt);
        comp_ds_info.subsystem_id(c,1) = component_attributes.subsystem_id(comp_attr_filt);
        comp_ds_info.unit{c,1} = component_attributes.unit(comp_attr_filt);
        comp_ds_info.unit_qty(c,1) = component_attributes.unit_qty(comp_attr_filt);
        comp_ds_info.service_location{c,1} = component_attributes.service_location{comp_attr_filt};

        % Find idx of this damage state in the damage state attribute tables
        ds_comp_filt = ~cellfun(@isempty,regexp(comp_ds_info.comp_id{c,1},damage_state_attribute_mapping.fragility_id_regex));
        ds_seq_filt = damage_state_attribute_mapping.ds_index == comp_ds_info.ds_seq_id(c,1);
        if comp_ds_info.ds_sub_id(c,1) == 1
            % 1 or NA are acceptable for the sub ds
            ds_sub_filt = ismember(damage_state_attribute_mapping.sub_ds_index, {'1', 'NA'});
        else
            ds_sub_filt = ismember(damage_state_attribute_mapping.sub_ds_index, num2str(comp_ds_info.ds_sub_id(c,1)));
        end
        ds_attr_filt = ds_comp_filt & ds_seq_filt & ds_sub_filt;
        if sum(ds_attr_filt) ~= 1
            error('Could not find damage state attrubutes')
        end

        % Set Damage State Attributes
        comp_ds_info.is_sim_ds(c,1) = damage_state_attribute_mapping.is_sim_ds(ds_attr_filt);
        comp_ds_info.safety_class(c,1) = damage_state_attribute_mapping.safety_class(ds_attr_filt);
        comp_ds_info.affects_envelope_safety(c,1) = damage_state_attribute_mapping.affects_envelope_safety(ds_attr_filt);
        comp_ds_info.ext_falling_hazard(c,1) = damage_state_attribute_mapping.exterior_falling_hazard(ds_attr_filt);
        comp_ds_info.int_falling_hazard(c,1) = damage_state_attribute_mapping.interior_falling_hazard(ds_attr_filt);
        comp_ds_info.global_hazardous_material(c,1) = damage_state_attribute_mapping.global_hazardous_material(ds_attr_filt);
        comp_ds_info.local_hazardous_material(c,1) = damage_state_attribute_mapping.local_hazardous_material(ds_attr_filt);
        comp_ds_info.affects_access(c,1) = damage_state_attribute_mapping.affects_access(ds_attr_filt);
        comp_ds_info.damages_envelope_seal(c,1) = damage_state_attribute_mapping.damages_envelope_seal(ds_attr_filt);
        comp_ds_info.obstructs_interior_space(c,1) = damage_state_attribute_mapping.obstructs_interior_space(ds_attr_filt);
        comp_ds_info.impairs_system_operation(c,1) = damage_state_attribute_mapping.impairs_system_operation(ds_attr_filt);
        comp_ds_info.fraction_area_affected(c,1) = damage_state_attribute_mapping.fraction_area_affected(ds_attr_filt);
        comp_ds_info.area_affected_unit(c,1) = damage_state_attribute_mapping.area_affected_unit(ds_attr_filt);
        comp_ds_info.crew_size(c,1) = damage_state_attribute_mapping.crew_size(ds_attr_filt);
        comp_ds_info.tmp_fix(c,1) = damage_state_attribute_mapping.has_tmp_fix(ds_attr_filt);
        comp_ds_info.tmp_fix_time(c,1) = damage_state_attribute_mapping.tmp_fix_time(ds_attr_filt);
        comp_ds_info.requires_shoring(c,1) = damage_state_attribute_mapping.requires_shoring(ds_attr_filt);
        comp_ds_info.permit_type(c,1) = damage_state_attribute_mapping.permit_type(ds_attr_filt);
        comp_ds_info.redesign(c,1) = damage_state_attribute_mapping.redesign(ds_attr_filt);

        % Find idx of this damage state in the subsystem attribute tables
        subsystem_filt = subsystems.id == comp_ds_info.subsystem_id(c,1);
        if comp_ds_info.subsystem_id(c,1) == 0
            % No subsytem
            comp_ds_info.n1_redundancy(c,1) = 0;
            comp_ds_info.parallel_operation(c,1) = 0;
        elseif sum(subsystem_filt) ~= 1
            error('Could not find damage state attrubutes')
        else
            % Set Damage State Attributes
            comp_ds_info.n1_redundancy(c,1) = subsystems.n1_redundancy(subsystem_filt);
            comp_ds_info.parallel_operation(c,1) = subsystems.parallel_operation(subsystem_filt);
        end

    end
    damage.comp_ds_table = struct2table(comp_ds_info);


%% Extract simulated utilitiies from file (if applicable)
    % Simulated utility downtimes for electrical, water, and gas networks - 
    % for each realization of the monte carlo simulation.
    if exist('utility_downtime.json','file')
        functionality = jsondecode(fileread('utility_downtime.json'));
    else
        % If no data exist, assume there is no consequence of network downtime
        num_reals = length(damage_consequences.red_tag);
        functionality.utilities.electrical = zeros(num_reals,1);
        functionality.utilities.water = zeros(num_reals,1);
        functionality.utilities.gas = zeros(num_reals,1);
    end

%% Optional input
    % Load default optional inputs
    % various assessment otpions. Set to default options in the
    % optional_inputs.m file. This file is expected to be in this input
    % directory. This file can be customized for each assessment if desired.
    optional_inputs

%% Save simulated_inputs.mat in appropriate directory
save([outputs_dir filesep 'simulated_inputs.mat'],...
    'damage','damage_consequences','functionality',...
    'functionality_options','impedance_options','regional_impact',...
    'repair_time_options','tenant_units')


end