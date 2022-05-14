function [] = plotFRTDash(functionality, n_stories, n_sim, ub, colorspec)
% plotStoryLevelRepair
% plots repairs for a given simulation #, n_sim, defined by the user.

n_systems = length(functionality.building_repair_schedule.system_names);

    plot1 = subplot(2,2,1);
    Positions=[1:n_systems];
    H1 = barh(Positions,flip(functionality.impeding_factors.time_sys(n_sim,:)),'BarWidth',0.4);
    title('Impeding factors','interpreter','latex')
    yticklabels(flip(functionality.building_repair_schedule.system_names))
    grid on

% Subplot 2: system level

    plot2 = subplot(2,2,3);
    Positions=[1:n_systems]; % vertical axis coordinates
    plotLengths = zeros(n_systems,2);
    xlim([0 150])

    for i =1:n_systems
        plotLengths(i,1) = functionality.building_repair_schedule.repair_start_day.per_system(n_sim,i);

        plotLengths(i,2) = functionality.building_repair_schedule.repair_complete_day.per_system(n_sim,i) ...
                         - functionality.building_repair_schedule.repair_start_day.per_system(n_sim,i);
    end

    yyaxis left
    H2 = barh(flip(Positions),plotLengths,'stacked','BarWidth',0.4);
    title('Repair sequence','interpreter','latex')
    hold on
    barh(Positions,flip(functionality.impeding_factors.time_sys(n_sim,:)),'BarWidth',0.4,'FaceColor', [0.85 0.85 0.85],'LineStyle','none');
    xlim([0 ub])

    grid on
    yticklabels(flip(functionality.building_repair_schedule.system_names))
    xlabel('days after earthquake','interpreter','latex')
    set(H2(1),'Visible','off');


    % Overlay functionality plot
    hold on
    yyaxis right
    ylim([0 1])
    reocc = plot(functionality.recovery.reoccupancy.recovery_trajectory.recovery_day(n_sim,:),functionality.recovery.reoccupancy.recovery_trajectory.percent_recovered,'linewidth',2);
    func = plot(functionality.recovery.functional.recovery_trajectory.recovery_day(n_sim,:),functionality.recovery.functional.recovery_trajectory.percent_recovered,'-b','linewidth',2);
    ylabel('Recovery','interpreter','latex')
    %legend([reocc, func],'reoccupancy','function','interpreter','latex')

    linkaxes([plot1 plot2],'x')

% %% Plot results in a Gantt Chart: component - level
n_components = length(functionality.building_repair_schedule.component_names);

    plot2 = subplot(2,2,[2 4]);
    Positions=[1:n_components]; % vertical axis coordinates
    plotLengths = zeros(n_components,2);

    for i =1:n_components
        plotLengths(i,1) = functionality.building_repair_schedule.repair_start_day.per_component(n_sim,i);

        plotLengths(i,2) = functionality.building_repair_schedule.repair_complete_day.per_component(n_sim,i) ...
                         - functionality.building_repair_schedule.repair_start_day.per_component(n_sim,i);
    end


    yyaxis left
    H2 = barh(flip(Positions),plotLengths,'stacked','BarWidth',0.4);
    title('Repair sequence','interpreter','latex')
    hold on

    grid on
    yticks(1:1:41)
    %yticklabels(flip(functionality.building_repair_schedule.component_names))
    set(gca,'YTickLabel',flip(functionality.building_repair_schedule.component_names))
    xlabel('days after earthquake','interpreter','latex')
    set(H2(1),'Visible','off');
    xlim([0 ub])
    ylim([0 n_components + 1])


    % Overlay functionality plot
    hold on
    grid on
    yyaxis right
    ylim([0 1])
    reocc = plot(functionality.recovery.reoccupancy.recovery_trajectory.recovery_day(n_sim,:),functionality.recovery.reoccupancy.recovery_trajectory.percent_recovered,'linewidth',2);
    func = plot(functionality.recovery.functional.recovery_trajectory.recovery_day(n_sim,:),functionality.recovery.functional.recovery_trajectory.percent_recovered,'-b','linewidth',2);
    ylabel('Recovery','interpreter','latex')
    legend([reocc, func],'reoccupancy','function','interpreter','latex')

    end