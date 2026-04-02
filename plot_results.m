function plot_results(res, par)
% 单场景绘图函数

    t = 1:par.T;

    %% 图1：电源出力
    figure('Name', '电源出力');
    plot(t, res.Pwind, '-o', 'LineWidth', 1.2); hold on;
    plot(t, res.Ppv,   '-s', 'LineWidth', 1.2);
    plot(t, res.Pcsp,  '-^', 'LineWidth', 1.2);
    plot(t, res.Pth,   '-d', 'LineWidth', 1.2);
    plot(t, res.Pgrid, '-x', 'LineWidth', 1.2);
    xlabel('时间 / h');
    ylabel('功率 / MW');
    title('各类电源出力');
    legend('风电', '光伏', '光热', '火电', '购电', 'Location', 'best');
    grid on;

    %% 图2：数据中心负荷分解
    figure('Name', '数据中心负荷');
    plot(t, res.Pdc,     '-o', 'LineWidth', 1.5); hold on;
    plot(t, res.P_rigid, '-s', 'LineWidth', 1.2);
    plot(t, res.P_shift, '-^', 'LineWidth', 1.2);
    plot(t, res.P_up,    '-d', 'LineWidth', 1.2);
    plot(t, res.P_down,  '-x', 'LineWidth', 1.2);
    plot(t, res.P_cut,   '-+', 'LineWidth', 1.2);
    xlabel('时间 / h');
    ylabel('功率 / MW');
    title('数据中心负荷分解');
    legend('总负荷', '刚性任务', '时移任务', '主动增载', '主动减载', '应急削减', ...
           'Location', 'best');
    grid on;

    %% 图3：储能功率与 SOC
    figure('Name', '储能状态');
    yyaxis left;
    plot(t, res.Pch,  '-s', 'LineWidth', 1.2); hold on;
    plot(t, res.Pdis, '-^', 'LineWidth', 1.2);
    ylabel('功率 / MW');

    yyaxis right;
    plot(t, res.SOC, '-o', 'LineWidth', 1.5);
    ylabel('电量 / MWh');

    xlabel('时间 / h');
    title('储能充放电功率与 SOC');
    legend('充电功率', '放电功率', 'SOC', 'Location', 'best');
    grid on;

    %% 图4：弃风弃光
    figure('Name', '弃风弃光');
    plot(t, res.Pwind_curt, '-o', 'LineWidth', 1.2); hold on;
    plot(t, res.Ppv_curt,   '-s', 'LineWidth', 1.2);
    xlabel('时间 / h');
    ylabel('功率 / MW');
    title('弃风弃光情况');
    legend('弃风', '弃光', 'Location', 'best');
    grid on;

    %% 图5：光热机组与热储状态
    figure('Name', '光热状态');
    yyaxis left;
    plot(t, res.Pcsp,     '-o', 'LineWidth', 1.5); hold on;
    plot(t, res.Pcsp_dir, '-s', 'LineWidth', 1.2);
    plot(t, res.Pcsp_dis, '-^', 'LineWidth', 1.2);
    ylabel('功率 / MW');

    yyaxis right;
    plot(t, res.Ecsp, '-d', 'LineWidth', 1.5);
    ylabel('热储能量 / MWh');

    xlabel('时间 / h');
    title('光热出力与热储状态');
    legend('光热总出力','直接发电','放热发电','热储能量','Location','best');
    grid on;

    %% 图6：主动协同请求缺额
    figure('Name','请求缺额');
    plot(t, res.P_up_short, '-o', 'LineWidth', 1.5); hold on;
    plot(t, res.P_down_short, '-s', 'LineWidth', 1.5);
    xlabel('时间 / h');
    ylabel('功率 / MW');
    title('未满足系统请求的缺额');
    legend('增载请求缺额','减载请求缺额','Location','best');
    grid on;

    %% 图7：算力任务剖面
    figure('Name','算力任务剖面');
    plot(t, res.TaskRigidProfile, '-s', 'LineWidth', 1.2); hold on;
    plot(t, res.TaskShiftProfile, '-^', 'LineWidth', 1.2);
    plot(t, res.TaskInterruptServedProfile, '-d', 'LineWidth', 1.2);
    plot(t, res.TaskInterruptCurtailedProfile, '-x', 'LineWidth', 1.2);
    plot(t, res.TaskTotalServedProfile, '-o', 'LineWidth', 1.5);
    xlabel('时间 / h');
    ylabel('算力单位');
    title('算力任务执行剖面');
    legend('刚性任务','时移任务','可中断任务执行','可中断任务削减','总算力执行', ...
           'Location','best');
    grid on;

    %% 图8：绿电支撑算力
    figure('Name','绿电支撑算力');
    plot(t, res.GreenPowerForDCProfile, '-o', 'LineWidth', 1.5); hold on;
    plot(t, res.Pdc, '--', 'LineWidth', 1.2);
    xlabel('时间 / h');
    ylabel('功率 / MW');
    title('绿电对数据中心负荷支撑情况');
    legend('绿电支撑数据中心负荷','数据中心总负荷','Location','best');
    grid on;
end