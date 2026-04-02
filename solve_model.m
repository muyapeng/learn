function sol = solve_model(Constraints, Objective)
% 调用求解器求解

    ops = sdpsettings;
    ops.solver = 'cplex';
    ops.verbose = 0;
    ops.warning = 1;
    ops.debug = 0;
    ops.savesolveroutput = 1;
    ops.savesolverinput  = 1;

    try
        ops.cplex.mip.display = 0;
    catch
    end

    btState = warning('query', 'backtrace');
    warning('off', 'backtrace');

    tic;
    sol = optimize(Constraints, Objective, ops);
    sol.solve_time = toc;

    warning(btState.state, 'backtrace');

    if sol.problem ~= 0
        disp('模型求解失败:');
        disp(sol.info);
        error('请检查模型约束或参数设置。');
    else
        disp('模型求解成功。');
        fprintf('求解时间：%.4f s\n', sol.solve_time);
    end
end