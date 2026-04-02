function export_typical_day_curves(scenario_name, overrides)
% 导出典型日曲线数据，默认导出主动协同场景
%
% 用法：
%   export_typical_day_curves
%   export_typical_day_curves('active_coord')
%   export_typical_day_curves('active_coord', struct('renew_scale',1.8))

    if nargin < 1 || isempty(scenario_name)
        scenario_name = 'active_coord';
    end
    if nargin < 2
        overrides = struct();
    end

    [res, par, ~] = run_one_case(scenario_name, overrides);

    t = (1:par.T)';

    CurveTable = table( ...
        t, ...
        par.Load_base, ...
        res.Pwind, res.Ppv, res.Pcsp, res.Pth, res.Pgrid, ...
        res.Pwind_curt, res.Ppv_curt, ...
        res.Pdc, res.P_rigid, res.P_shift, res.P_cut, ...
        res.P_up, res.P_down, res.P_up_short, res.P_down_short, ...
        res.Pch, res.Pdis, res.SOC, ...
        res.SystemNetLoad, ...
        res.TaskRigidProfile, ...
        res.TaskShiftProfile, ...
        res.TaskInterruptServedProfile, ...
        res.TaskInterruptCurtailedProfile, ...
        res.TaskTotalServedProfile, ...
        res.GreenPowerForDCProfile, ...
        'VariableNames', { ...
        't', ...
        'Load_base', ...
        'Pwind','Ppv','Pcsp','Pth','Pgrid', ...
        'Pwind_curt','Ppv_curt', ...
        'Pdc','P_rigid','P_shift','P_cut', ...
        'P_up','P_down','P_up_short','P_down_short', ...
        'Pch','Pdis','SOC', ...
        'SystemNetLoad', ...
        'TaskRigid','TaskShift','TaskInterruptServed','TaskInterruptCurtailed', ...
        'TaskTotalServed','GreenPowerForDC'});

    filename = ['typical_day_', scenario_name, '.xlsx'];
    writetable(CurveTable, filename);

    disp('================ 典型日曲线已导出 ================');
    fprintf('文件名：%s\n', filename);

    %% 图1：电源出力
    figure('Name',['典型日电源出力-', scenario_name]);
    plot(t, res.Pwind, '-o', 'LineWidth', 1.2); hold on;
    plot(t, res.Ppv,   '-s', 'LineWidth', 1.2);
    plot(t, res.Pcsp,  '-^', 'LineWidth', 1.2);
    plot(t, res.Pth,   '-d', 'LineWidth', 1.2);
    plot(t, res.Pgrid, '-x', 'LineWidth', 1.2);
    xlabel('时间 / h');
    ylabel('功率 / MW');
    title(['典型日电源出力 - ', scenario_name]);
    legend('风电','光伏','光热','火电','购电','Location','best');
    grid on;

    %% 图2：数据中心负荷分解
    figure('Name',['典型日数据中心负荷-', scenario_name]);
    plot(t, res.Pdc,     '-o', 'LineWidth', 1.5); hold on;
    plot(t, res.P_rigid, '-s', 'LineWidth', 1.2);
    plot(t, res.P_shift, '-^', 'LineWidth', 1.2);
    plot(t, res.P_up,    '-d', 'LineWidth', 1.2);
    plot(t, res.P_down,  '-x', 'LineWidth', 1.2);
    plot(t, res.P_cut,   '-+', 'LineWidth', 1.2);
    xlabel('时间 / h');
    ylabel('功率 / MW');
    title(['典型日数据中心负荷分解 - ', scenario_name]);
    legend('总负荷','刚性任务','时移任务','主动增载','主动减载','应急削减', 'Location','best');
    grid on;

    %% 图3：储能曲线
    figure('Name',['典型日储能曲线-', scenario_name]);
    yyaxis left;
    plot(t, res.Pch,  '-s', 'LineWidth', 1.2); hold on;
    plot(t, res.Pdis, '-^', 'LineWidth', 1.2);
    ylabel('功率 / MW');

    yyaxis right;
    plot(t, res.SOC, '-o', 'LineWidth', 1.5);
    ylabel('SOC / MWh');

    xlabel('时间 / h');
    title(['典型日储能曲线 - ', scenario_name]);
    legend('充电功率','放电功率','SOC','Location','best');
    grid on;

    %% 图4：系统净负荷
    figure('Name',['典型日系统净负荷-', scenario_name]);
    plot(t, res.SystemNetLoad, '-o', 'LineWidth', 1.5); hold on;
    plot(t, par.Load_base + res.Pdc, '--', 'LineWidth', 1.2);
    xlabel('时间 / h');
    ylabel('功率 / MW');
    title(['典型日系统净负荷 - ', scenario_name]);
    legend('系统净负荷','基础负荷+数据中心负荷','Location','best');
    grid on;

    %% 图5：算力任务执行曲线
    figure('Name',['典型日算力任务-', scenario_name]);
    plot(t, res.TaskRigidProfile, '-s', 'LineWidth', 1.2); hold on;
    plot(t, res.TaskShiftProfile, '-^', 'LineWidth', 1.2);
    plot(t, res.TaskInterruptServedProfile, '-d', 'LineWidth', 1.2);
    plot(t, res.TaskInterruptCurtailedProfile, '-x', 'LineWidth', 1.2);
    plot(t, res.TaskTotalServedProfile, '-o', 'LineWidth', 1.5);
    xlabel('时间 / h');
    ylabel('算力单位');
    title(['典型日算力任务执行 - ', scenario_name]);
    legend('刚性任务','时移任务','可中断任务执行','可中断任务削减','总算力执行', 'Location','best');
    grid on;

    %% 图6：绿电支撑算力
    figure('Name',['典型日绿电支撑算力-', scenario_name]);
    plot(t, res.GreenPowerForDCProfile, '-o', 'LineWidth', 1.5); hold on;
    plot(t, res.Pdc, '--', 'LineWidth', 1.2);
    xlabel('时间 / h');
    ylabel('功率 / MW');
    title(['典型日绿电支撑算力 - ', scenario_name]);
    legend('绿电支撑数据中心负荷','数据中心总负荷','Location','best');
    grid on;
end