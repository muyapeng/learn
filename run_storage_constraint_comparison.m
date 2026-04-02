function run_storage_constraint_comparison()
% 对比：
% 1) 理想储能（不考虑算力约束）
% 2) 受算力约束储能（考虑 reserve coupling）

    clc;

    base_scenario = 'active_coord';

    % 情况 A：理想储能
    overridesA = struct();
    overridesA.flag_reserve_coupling = 0;
    overridesA.alpha_reserve = 0;
    [resA, parA, ~] = run_one_case(base_scenario, overridesA);

    % 情况 B：受算力约束储能
    overridesB = struct();
    overridesB.flag_reserve_coupling = 1;
    [resB, parB, ~] = run_one_case(base_scenario, overridesB);

    rowA = result_to_row(resA, '理想储能');
    rowB = result_to_row(resB, '受算力约束储能');
    CompareTable = [rowA; rowB];

    disp('================ 储能约束对比结果 ================');
    disp(CompareTable);

    writetable(CompareTable, 'storage_constraint_comparison.xlsx');

    %% 图1：总成本与储能成本
    figure('Name','储能约束对比-成本');
    bar([CompareTable.TotalCost, CompareTable.StorageCost]);
    set(gca, 'XTickLabel', CompareTable.Scenario, 'FontSize', 11);
    ylabel('成本 / 元');
    title('理想储能与受算力约束储能的成本对比');
    legend({'总成本','储能成本'}, 'Location', 'best');
    grid on;

    %% 图2：新能源利用与弃电
    figure('Name','储能约束对比-新能源消纳');
    yyaxis left;
    bar(categorical(CompareTable.Scenario), CompareTable.RenewUtilization);
    ylabel('新能源利用率');

    yyaxis right;
    plot(1:height(CompareTable), CompareTable.E_curt, '-o', 'LineWidth', 1.5);
    ylabel('弃电量 / MWh');
    title('理想储能与受算力约束储能的新能源消纳对比');
    grid on;

    %% 图3：系统灵活性指标
    figure('Name','储能约束对比-系统灵活性');
    bar([CompareTable.SystemNetLoadPeakValley, CompareTable.ThermalPeakValley, CompareTable.StorageCycles]);
    set(gca, 'XTickLabel', CompareTable.Scenario, 'FontSize', 11);
    ylabel('指标值');
    title('理想储能与受算力约束储能的灵活性对比');
    legend({'系统净负荷峰谷差','火电调峰深度','储能等效循环'}, 'Location', 'bestoutside');
    grid on;

    %% 图4：SOC 曲线对比
    t = 1:parA.T;
    figure('Name','储能约束对比-SOC');
    plot(t, resA.SOC, '-o', 'LineWidth', 1.5); hold on;
    plot(t, resB.SOC, '-s', 'LineWidth', 1.5);
    xlabel('时间 / h');
    ylabel('SOC / MWh');
    title('理想储能与受算力约束储能的 SOC 曲线对比');
    legend({'理想储能','受算力约束储能'}, 'Location', 'best');
    grid on;

    %% 图5：算电协同指标对比
    figure('Name','储能约束对比-算电协同');
    bar([CompareTable.TaskCompletionRate, CompareTable.DCRenewMatchIndex, CompareTable.ComputeEnergyIntensity]);
    set(gca, 'XTickLabel', CompareTable.Scenario, 'FontSize', 11);
    ylabel('指标值');
    title('理想储能与受算力约束储能的算电协同指标对比');
    legend({'任务完成率','算力-绿电匹配度','单位算力能耗'}, 'Location', 'bestoutside');
    grid on;

    %#ok<NASGU>
    parB = parB;
end