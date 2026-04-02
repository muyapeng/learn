% 验证东数西算：空间套利与算力迁移机制
clc; close all;

[res, par, sol] = run_one_case('active_coord');

figure('Name', '空间协同机制验证');
yyaxis left;
plot(1:par.T, res.P_trans, '-o', 'LineWidth', 2, 'MarkerFaceColor', 'b');
ylabel('西迁算力负荷 P_{trans} / MW');
ylim([-1, par.C_band + 2]); 

yyaxis right;
price_diff = par.price_East - par.price; 
plot(1:par.T, price_diff, '-s', 'LineWidth', 2, 'Color', [0.8500 0.3250 0.0980]);
ylabel('东西部电价差 / 元');

xlabel('时间 / h');
title('空间协同：东西部套利驱动下的算力跨网调度');
legend('西迁算力负荷 P_{trans}', '跨区电价差', 'Location', 'best');
grid on;