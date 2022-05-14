function [building_model] = load_building_model()
%LOAD_BUILDING_MODEL user-specified settings go here.

building_model.building_value = 8018161;
building_model.num_stories = 3;
building_model.total_area_sf = 30000;
building_model.area_per_story_sf = [10000, 10000, 10000];
building_model.ht_per_story_ft = [13, 13, 13];
building_model.edge_lengths = [100, 100, 100; 100, 100, 100]; % Edge of each wall in each direction?
building_model.struct_bay_area_per_story = [600, 600, 600]; % Area of single bay on each floor? (25 x 25)
building_model.num_entry_doors = 4;
building_model.num_elevators = 3;
building_model.stairs_per_story = [2,2,2];
building_model.occupants_per_story = [40, 40, 40];
building_model.replacement_time_days = 540;
end