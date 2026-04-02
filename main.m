clc; clear; close all;

% 是否在主程序结束后自动跑敏感性分析
run_sensitivity_after_main = false;

% 是否在主程序结束后自动跑“理想储能 vs 受算力约束储能”对比
run_storage_compare_after_main = false;

% 是否在主程序结束后自动导出主动协同场景典型日曲线
run_typical_day_export_after_main = false;

%% 场景设置
scenario_ids   = {'no_response', 'passive_shift', 'peak_shed', 'active_coord'};
scenario_names = {'无响应', '仅被动时移', '峰时削减响应', '主动协同响应'};
nS = numel(scenario_ids);

RES  = cell(nS,1);
PARS = cell(nS,1);
SOLS = cell(nS,1);

ResultTable = table();

%% 四场景批量运行
for s = 1:nS
    [res, par, sol] = run_one_case(scenario_ids{s});

    RES{s}  = res;
    PARS{s} = par;
    SOLS{s} = sol;

    row = result_to_row(res, scenario_names{s});
    ResultTable = [ResultTable; row];
end

disp('================ 四场景对比结果 ================');
disp(ResultTable);

writetable(ResultTable, 'four_scenario_results.xlsx');

%% 兼容现有绘图的 summary 矩阵 (修复缺失的套利收益)
summary = [ ...
    ResultTable.TotalCost, ...
    ResultTable.ThermalCost, ...
    ResultTable.CSPCost, ...
    ResultTable.GridCost, ...
    ResultTable.ShiftCost, ...
    ResultTable.DRServiceCost, ...
    ResultTable.DRShortCost, ...
    ResultTable.CurtailCost, ...
    ResultTable.StorageCost, ...
    -ResultTable.Savings_trans, ...  % [新增] 作为负向柱子展示
    ResultTable.E_shift, ...
    ResultTable.E_up, ...
    ResultTable.E_down, ...
    ResultTable.E_cut, ...
    ResultTable.E_up_short, ...
    ResultTable.E_down_short, ...
    ResultTable.UpRespRate, ...
    ResultTable.DownRespRate, ...
    ResultTable.E_grid, ...
    ResultTable.E_curt, ...
    ResultTable.DCPeakValley, ...
    ResultTable.SystemNetLoadPeakValley];

%% 图1：总成本对比
figure('Name','四场景总成本对比');
bar(summary(:,1));
set(gca, 'XTickLabel', scenario_names, 'FontSize', 11);
ylabel('成本 / 元');
title('四场景总成本对比');
grid on;

%% 图2：成本分解对比 (双向堆叠图，展示套利收益对冲)
figure('Name','四场景成本分解');
% 提取正向成本 (火电, 光热, 购电, 时移, DR服务, DR缺额, 弃电, 储能)
cost_positive = [ResultTable.ThermalCost, ResultTable.CSPCost, ResultTable.GridCost, ...
                 ResultTable.ShiftCost, ResultTable.DRServiceCost, ResultTable.DRShortCost, ...
                 ResultTable.CurtailCost, ResultTable.StorageCost];
% 提取负向成本 (跨区套利收益)
cost_negative = -ResultTable.Savings_trans;

% 绘制正向堆叠柱状图
b_pos = bar(cost_positive, 'stacked'); hold on;
% 绘制负向柱状图
b_neg = bar(cost_negative, 'FaceColor', [0.4660 0.6740 0.1880]); % 绿色代表收益

set(gca, 'XTickLabel', scenario_names, 'FontSize', 10);
ylabel('成本 / 元');
title('四场景成本分解 (正向成本 vs 跨区套利收益)');

% 添加图例
legend_labels = {'火电','光热','购电','时移','主动响应服务','请求缺额惩罚','弃电','储能','跨区套利收益(负值)'};
legend([b_pos, b_neg], legend_labels, 'Location', 'bestoutside');
grid on;

% 添加总成本的散点折线辅助看图
plot(1:4, ResultTable.TotalCost, '-kd', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'k');
legend_labels{end+1} = '实际总净成本';
legend([b_pos, b_neg, gca().Children(1)], legend_labels, 'Location', 'bestoutside');

%% 图3：主动响应相关电量对比
figure('Name','主动响应相关电量对比');
bar(summary(:,11:15), 'grouped');
set(gca, 'XTickLabel', scenario_names, 'FontSize', 10);
ylabel('电量 / MWh');
title('主动响应电量与缺额对比');
legend({'E_up','E_down','E_cut','E_up_short','E_down_short'}, ...
       'Location', 'bestoutside');
grid on;

%% 图4：响应完成率对比
figure('Name','响应完成率对比');
bar(summary(:,16:17));
set(gca, 'XTickLabel', scenario_names, 'FontSize', 11);
ylabel('比例');
ylim([0 1.05]);
title('上调/下调响应完成率对比');
legend({'上调完成率','下调完成率'}, 'Location', 'best');
grid on;

%% 图5：峰谷差对比
figure('Name','峰谷差对比');
bar(summary(:,20:21));
set(gca, 'XTickLabel', scenario_names, 'FontSize', 11);
ylabel('MW');
title('数据中心负荷与系统净负荷峰谷差');
legend({'数据中心负荷峰谷差','系统净负荷峰谷差'}, 'Location', 'best');
grid on;

%% 图6：四场景数据中心总负荷
t = 1:PARS{1}.T;
figure('Name','四场景数据中心总负荷');
plot(t, RES{1}.Pdc, '-o', 'LineWidth', 1.2); hold on;
plot(t, RES{2}.Pdc, '-s', 'LineWidth', 1.2);
plot(t, RES{3}.Pdc, '-^', 'LineWidth', 1.2);
plot(t, RES{4}.Pdc, '-d', 'LineWidth', 1.2);
xlabel('时间 / h');
ylabel('功率 / MW');
title('四场景数据中心总负荷曲线');
legend(scenario_names, 'Location', 'best');
grid on;

%% 图7：主动协同场景下请求与响应
figure('Name','主动协同场景下请求与响应');
yyaxis left;
plot(t, RES{4}.P_up, '-o', 'LineWidth', 1.5); hold on;
plot(t, RES{4}.P_down, '-s', 'LineWidth', 1.5);
plot(t, RES{4}.P_cut, '-^', 'LineWidth', 1.5);
ylabel('功率 / MW');

yyaxis right;
plot(t, PARS{4}.DR_up_req, '--', 'LineWidth', 1.2); hold on;
plot(t, PARS{4}.DR_down_req, ':', 'LineWidth', 1.2);
ylabel('系统请求 / MW');

xlabel('时间 / h');
title('主动协同场景下请求与响应');
legend('P_up','P_down','P_cut','DR_up_req','DR_down_req','Location','best');
grid on;

%% 图8：主动协同场景请求缺额
figure('Name','主动协同场景请求缺额');
plot(t, RES{4}.P_up_short, '-o', 'LineWidth', 1.5); hold on;
plot(t, RES{4}.P_down_short, '-s', 'LineWidth', 1.5);
xlabel('时间 / h');
ylabel('功率 / MW');
title('主动协同场景请求缺额');
legend('上调缺额','下调缺额','Location','best');
grid on;

%% 受算力约束储能对比实验入口
if run_storage_compare_after_main
    run_storage_constraint_comparison;
end

%% 主动协同场景典型日曲线导出入口
if run_typical_day_export_after_main
    export_typical_day_curves('active_coord');
end

%% 敏感性分析入口
if run_sensitivity_after_main
    run_sensitivity;
end