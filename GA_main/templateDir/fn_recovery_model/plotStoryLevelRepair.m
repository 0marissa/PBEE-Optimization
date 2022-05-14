function [] = plotStoryLevelRepair(functionality, n_stories, n_sim, ub, colorspec)
% plotStoryLevelRepair
% plots repairs for a given simulation #, n_sim, defined by the user.

%% Repairs taking place per story (start and end bounds)
figure
set(gcf,'Position',[500 100 800 600])

 subplot(3,2,[1 3])
 Positions=[1:n_stories]; % vertical axis coordinates
 plotLengths = zeros(n_stories,2);

    for i =1:n_stories
        plotLengths(i,1) = functionality.building_repair_schedule.repair_start_day.per_story(n_sim,i);

        plotLengths(i,2) = functionality.building_repair_schedule.repair_complete_day.per_story(n_sim,i) ...
                         - functionality.building_repair_schedule.repair_start_day.per_story(n_sim,i);
    end

    yyaxis left
    ylim([0 n_stories])
    H2 = barh((Positions),plotLengths,'stacked','FaceColor',[0.7 0.7 0.7],'BarWidth',0.4);    
    xlim([0 ub])
    set(H2(1),'Visible','off');
    ylabel('Story', 'interpreter', 'latex')

    % Overlay functionality plot
    hold on
    grid on
    
    yyaxis right
    ylim([0 1])
    reocc = plot(functionality.recovery.reoccupancy.recovery_trajectory.recovery_day(n_sim,:),functionality.recovery.reoccupancy.recovery_trajectory.percent_recovered,'linewidth',2);
    func = plot(functionality.recovery.functional.recovery_trajectory.recovery_day(n_sim,:),functionality.recovery.functional.recovery_trajectory.percent_recovered,'-b','linewidth',2);
    ylabel('Recovery','interpreter','latex')
    legend([reocc, func],'reoccupancy','function','location','southeast','interpreter','latex')
    xlabel('Time (days)', 'interpreter', 'latex')

    yyaxis left
    ylim([0 n_stories])

%% Repairs taking place per story (system)

 subplot(3,2,[2 4])
 Positions=[1:n_stories]; % vertical axis coordinates
 plotLengths = zeros(n_stories,2);
 
for sys_ID = 1:10
   
 
    plotLengths(:,1) = functionality.building_repair_schedule.repair_start_day.per_system_story(n_sim,[sys_ID:10:end]);

    plotLengths(:,2) = functionality.building_repair_schedule.repair_complete_day.per_system_story(n_sim,[sys_ID:10:end]) ...
                     - functionality.building_repair_schedule.repair_start_day.per_system_story(n_sim,[sys_ID:10:end]);
    yyaxis left
    ylim([0 n_stories])
    H2(sys_ID,:) = barh((Positions),plotLengths,'stacked','FaceColor',colorspec{sys_ID},'BarWidth',0.4);  
    ylabel('Story', 'interpreter', 'latex')

    xlim([0 ub])
    set(H2(sys_ID,1),'Visible','off');
    hold on
    grid on

end 
    % Overlay functionality plot
    hold on
    yyaxis right
    ylim([0 1])
    reocc = plot(functionality.recovery.reoccupancy.recovery_trajectory.recovery_day(n_sim,:),functionality.recovery.reoccupancy.recovery_trajectory.percent_recovered,'linewidth',2);
    func = plot(functionality.recovery.functional.recovery_trajectory.recovery_day(n_sim,:),functionality.recovery.functional.recovery_trajectory.percent_recovered,'-b','linewidth',2);
    ylabel('Recovery','interpreter','latex')
    legend([reocc, func],'reoccupancy','function','interpreter','latex')

    sys_names = functionality.building_repair_schedule.system_names;
    legend('',sys_names{1},'',sys_names{2},'',sys_names{3},'',sys_names{4}, ...
           '',sys_names{5},'',sys_names{6},'',sys_names{7},'',sys_names{8},'',sys_names{9},'',sys_names{10}, 'reoccupancy','function',...
           'location','southeast','interpreter', 'latex')

    xlabel('Time (days)', 'interpreter', 'latex')

%% Number of workers over time

 subplot(3,2,5)
 plot(functionality.worker_data.day_vector(n_sim,:),functionality.worker_data.total_workers(n_sim,:), 'Color', [0.5 0.5 0.5], 'linewidth', 2)
 xlabel('Days', 'interpreter', 'latex')
 ylabel('Number of workers', 'interpreter', 'latex')
 grid on
 xlim([0 ub])

    
 subplot(3,2,6)
 plot(functionality.worker_data.day_vector(n_sim,:),functionality.worker_data.total_workers(n_sim,:), 'Color', [0.5 0.5 0.5], 'linewidth', 2)
 xlabel('Days', 'interpreter', 'latex')
 ylabel('Number of workers', 'interpreter', 'latex')
 grid on
 xlim([0 ub])

    
end

