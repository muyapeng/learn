function run_sensitivity()
% 批量敏感性分析
% 围绕主动协同场景 'active_coord' 进行
%
% 1) 系统侧：新能源渗透率、储能容量、储能保底约束
% 2) 负荷柔性：可时移任务量、时移功率上限、响应时长上限
% 3) 输出算电协同指标

    clc;

    base_scenario = 'active_coord';

    %% ---------------- 系统侧敏感性 ----------------
    vals1 = [1.2 1.4 1.6 1.8 2.0];
    out1  = sweep_one_param(base_scenario, 'renew_scale', vals1);

    vals2 = [0.8 1.0 1.2 1.4 1.6];
    out2  = sweep_one_param(base_scenario, 'storage_energy_scale', vals2);

    vals3 = [0.05 0.10 0.15 0.20 0.25];
    out3  = sweep_one_param(base_scenario, 'alpha_reserve', vals3);

    %% ---------------- 负荷柔性敏感性 ----------------
    vals4 = [20 40 60 80 100];
    out4  = sweep_one_param(base_scenario, 'E_shift_total', vals4);

    vals5 = [4 6 8 10 12];
    out5  = sweep_one_param(base_scenario, 'P_shift_max', vals5);

    vals6 = [4 6 8 10 12];
    out6  = sweep_one_param(base_scenario, 'DR_hours_max', vals6);

    %% 打印结果表
    disp('================ Sensitivity: renew_scale ================');
    disp(out1.Table);

    disp('================ Sensitivity: storage_energy_scale ================');
    disp(out2.Table);

    disp('================ Sensitivity: alpha_reserve ================');
    disp(out3.Table);

    disp('================ Sensitivity: E_shift_total ================');
    disp(out4.Table);

    disp('================ Sensitivity: P_shift_max ================');
    disp(out5.Table);

    disp('================ Sensitivity: DR_hours_max ================');
    disp(out6.Table);

    %% 导出
    writetable(out1.Table, 'sens_renew_scale.xlsx');
    writetable(out2.Table, 'sens_storage_energy_scale.xlsx');
    writetable(out3.Table, 'sens_alpha_reserve.xlsx');
    writetable(out4.Table, 'sens_E_shift_total.xlsx');
    writetable(out5.Table, 'sens_P_shift_max.xlsx');
    writetable(out6.Table, 'sens_DR_hours_max.xlsx');

    %% 绘图
    plot_sensitivity_result(out1, 'renew\_scale');
    plot_sensitivity_result(out2, 'storage\_energy\_scale');
    plot_sensitivity_result(out3, 'alpha\_reserve');
    plot_sensitivity_result(out4, 'E\_shift\_total');
    plot_sensitivity_result(out5, 'P\_shift\_max');
    plot_sensitivity_result(out6, 'DR\_hours\_max');
end

%% =======================================================================
function out = sweep_one_param(base_scenario, param_name, values)

    n = numel(values);

    TotalCost              = zeros(n,1);
    ThermalCost            = zeros(n,1);
    GridCost               = zeros(n,1);
    CurtailCost            = zeros(n,1);
    StorageCost            = zeros(n,1);
    DRServiceCost          = zeros(n,1);
    DRShortCost            = zeros(n,1);

    E_shift                = zeros(n,1);
    E_up                   = zeros(n,1);
    E_down                 = zeros(n,1);
    E_cut                  = zeros(n,1);
    E_up_short             = zeros(n,1);
    E_down_short           = zeros(n,1);

    UpRespRate             = zeros(n,1);
    DownRespRate           = zeros(n,1);
    RenewUtilization       = zeros(n,1);
    E_curt                 = zeros(n,1);
    DCPeakValley           = zeros(n,1);
    SystemNetLoadPV        = zeros(n,1);
    ThermalPeakValley      = zeros(n,1);
    StorageCycles          = zeros(n,1);

    TaskCompletionRate     = zeros(n,1);
    TaskCurtailRatio       = zeros(n,1);
    GreenPowerSupportRatio = zeros(n,1);
    DCRenewMatchIndex      = zeros(n,1);
    RenewableToDCShare     = zeros(n,1);
    ComputeEnergyIntensity = zeros(n,1);

    for i = 1:n
        overrides = struct();
        overrides.(param_name) = values(i);

        [res, ~, ~] = run_one_case(base_scenario, overrides);

        TotalCost(i)              = res.Obj_total;
        ThermalCost(i)            = res.C_th;
        GridCost(i)               = res.C_grid;
        CurtailCost(i)            = res.C_curt;
        StorageCost(i)            = res.C_es;
        DRServiceCost(i)          = res.C_DR_service;
        DRShortCost(i)            = res.C_DR_short;

        E_shift(i)                = res.E_shift;
        E_up(i)                   = res.E_up;
        E_down(i)                 = res.E_down;
        E_cut(i)                  = res.E_cut;
        E_up_short(i)             = res.E_up_short;
        E_down_short(i)           = res.E_down_short;

        UpRespRate(i)             = res.UpResponseRate;
        DownRespRate(i)           = res.DownResponseRate;
        RenewUtilization(i)       = res.RenewUtilization;
        E_curt(i)                 = res.E_curt;
        DCPeakValley(i)           = res.DCPeakValley;
        SystemNetLoadPV(i)        = res.SystemNetLoadPeakValley;
        ThermalPeakValley(i)      = res.ThermalPeakValley;
        StorageCycles(i)          = res.StorageEquivalentCycles;

        TaskCompletionRate(i)     = res.TaskCompletionRate;
        TaskCurtailRatio(i)       = res.TaskCurtailRatio;
        GreenPowerSupportRatio(i) = res.GreenPowerSupportRatio;
        DCRenewMatchIndex(i)      = res.DCRenewMatchIndex;
        RenewableToDCShare(i)     = res.RenewableToDCShare;
        ComputeEnergyIntensity(i) = res.ComputeEnergyIntensity;
    end

    out.ParamName = param_name;
    out.Values    = values(:);

    out.Table = table( ...
        values(:), ...
        TotalCost, ThermalCost, GridCost, CurtailCost, StorageCost, ...
        DRServiceCost, DRShortCost, ...
        E_shift, E_up, E_down, E_cut, E_up_short, E_down_short, ...
        UpRespRate, DownRespRate, ...
        RenewUtilization, E_curt, ...
        DCPeakValley, SystemNetLoadPV, ThermalPeakValley, StorageCycles, ...
        TaskCompletionRate, TaskCurtailRatio, GreenPowerSupportRatio, DCRenewMatchIndex, RenewableToDCShare, ComputeEnergyIntensity, ...
        'VariableNames', { ...
        param_name, ...
        'TotalCost','ThermalCost','GridCost','CurtailCost','StorageCost', ...
        'DRServiceCost','DRShortCost', ...
        'E_shift','E_up','E_down','E_cut','E_up_short','E_down_short', ...
        'UpRespRate','DownRespRate', ...
        'RenewUtilization','E_curt', ...
        'DCPeakValley','SystemNetLoadPeakValley','ThermalPeakValley','StorageCycles', ...
        'TaskCompletionRate','TaskCurtailRatio','GreenPowerSupportRatio','DCRenewMatchIndex','RenewableToDCShare','ComputeEnergyIntensity'});
end

%% =======================================================================
function plot_sensitivity_result(out, x_label_text)

    x = out.Values;
    T = out.Table;

    % 图1：总成本
    figure('Name', ['Sensitivity - ', out.ParamName, ' - TotalCost']);
    plot(x, T.TotalCost, '-o', 'LineWidth', 1.5);
    xlabel(x_label_text);
    ylabel('总成本 / 元');
    title(['敏感性分析：', out.ParamName, ' 对总成本的影响']);
    grid on;

    % 图2：新能源消纳
    figure('Name', ['Sensitivity - ', out.ParamName, ' - Renewable']);
    yyaxis left;
    plot(x, T.RenewUtilization, '-o', 'LineWidth', 1.5);
    ylabel('新能源利用率');

    yyaxis right;
    plot(x, T.E_curt, '-s', 'LineWidth', 1.5);
    ylabel('弃电量 / MWh');

    xlabel(x_label_text);
    title(['敏感性分析：', out.ParamName, ' 对新能源消纳的影响']);
    legend('新能源利用率','弃电量','Location','best');
    grid on;

    % 图3：系统灵活性
    figure('Name', ['Sensitivity - ', out.ParamName, ' - Flexibility']);
    plot(x, T.SystemNetLoadPeakValley, '-o', 'LineWidth', 1.5); hold on;
    plot(x, T.ThermalPeakValley, '-s', 'LineWidth', 1.5);
    plot(x, T.StorageCycles, '-^', 'LineWidth', 1.5);
    xlabel(x_label_text);
    ylabel('指标值');
    title(['敏感性分析：', out.ParamName, ' 对系统灵活性的影响']);
    legend('系统净负荷峰谷差','火电调峰深度','储能等效循环','Location','best');
    grid on;

    % 图4：负荷柔性/需求响应
    figure('Name', ['Sensitivity - ', out.ParamName, ' - Load Flexibility']);
    plot(x, T.E_shift, '-o', 'LineWidth', 1.5); hold on;
    plot(x, T.E_up, '-s', 'LineWidth', 1.5);
    plot(x, T.E_down, '-^', 'LineWidth', 1.5);
    plot(x, T.E_cut, '-d', 'LineWidth', 1.5);
    xlabel(x_label_text);
    ylabel('电量 / MWh');
    title(['敏感性分析：', out.ParamName, ' 对负荷柔性调用的影响']);
    legend('E\_shift','E\_up','E\_down','E\_cut','Location','best');
    grid on;

    % 图5：算电协同指标
    figure('Name', ['Sensitivity - ', out.ParamName, ' - Compute-Electric']);
    yyaxis left;
    plot(x, T.TaskCompletionRate, '-o', 'LineWidth', 1.5); hold on;
    plot(x, T.DCRenewMatchIndex, '-s', 'LineWidth', 1.5);
    plot(x, T.RenewableToDCShare, '-d', 'LineWidth', 1.5);
    ylabel('比例指标');

    yyaxis right;
    plot(x, T.ComputeEnergyIntensity, '-^', 'LineWidth', 1.5);
    ylabel('单位算力能耗');

    xlabel(x_label_text);
    title(['敏感性分析：', out.ParamName, ' 对算电协同指标的影响']);
    legend('任务完成率','算力-绿电匹配度','绿电服务算力占比','单位算力能耗','Location','best');
    grid on;
end