function [res, par, sol] = run_one_case(scenario_name, overrides)
% 统一单场景求解入口

    if nargin < 1 || isempty(scenario_name)
        scenario_name = 'active_coord';
    end
    if nargin < 2
        overrides = struct();
    end

    par = init_case(scenario_name, overrides);
    var = define_variables(par);
    Constraints = build_constraints(var, par);
    Objective   = build_objective(var, par);
    sol         = solve_model(Constraints, Objective);
    res         = extract_results(var, par, Objective, sol);
end