function var = define_variables(par)
% [导师终修版：两阶段变量解耦]

    T = par.T;
    K = par.K; % 极端场景维度

    %% 第一阶段变量 (日前独立于场景)
    var.Uth     = binvar(T,1);
    var.SUth    = binvar(T,1);
    var.Uch     = binvar(T,1);
    var.Udis    = binvar(T,1);
    var.U_up    = binvar(T,1);
    var.U_down  = binvar(T,1);
    var.P_shift = sdpvar(T,1); % 日前算力时移统筹
    var.P_rigid = sdpvar(T,1); % 刚性基线 (常数等效)

    %% 第二阶段变量 (日内受制于不确定场景 k)
    var.Pwind    = sdpvar(T,K,'full');
    var.Ppv      = sdpvar(T,K,'full');
    
    var.Pcsp     = sdpvar(T,K,'full');
    var.Pcsp_dir = sdpvar(T,K,'full');
    var.Pcsp_ch  = sdpvar(T,K,'full');
    var.Pcsp_dis = sdpvar(T,K,'full');
    var.Ecsp     = sdpvar(T,K,'full');

    var.Pth      = sdpvar(T,K,'full');
    var.Pgrid    = sdpvar(T,K,'full');

    var.Pch      = sdpvar(T,K,'full');
    var.Pdis     = sdpvar(T,K,'full');
    var.SOC      = sdpvar(T,K,'full');

    % 数据中心日内实际运行
    var.P_cut    = sdpvar(T,K,'full');
    var.P_IT     = sdpvar(T,K,'full');
    var.P_cool   = sdpvar(T,K,'full');
    var.T_in     = sdpvar(T,K,'full');
    var.P_trans  = sdpvar(T,K,'full');
    var.Pdc      = sdpvar(T,K,'full');

    var.P_up     = sdpvar(T,K,'full');
    var.P_down   = sdpvar(T,K,'full');
    var.P_rebound = sdpvar(T,K,'full');
    var.P_up_short   = sdpvar(T,K,'full');
    var.P_down_short = sdpvar(T,K,'full');

    var.Pwind_curt = sdpvar(T,K,'full');
    var.Ppv_curt   = sdpvar(T,K,'full');
end
