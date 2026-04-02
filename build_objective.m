function [Objective, obj_aux] = build_objective(var, par)
% [导师终修版：两阶段鲁棒优化目标函数(epigraph形式)]
    dt = par.dt;
    K  = par.K;

    % 第一阶段确定性成本
    C_first = par.c_start * sum(var.SUth) + par.c_shift_comp * sum(var.P_shift) * dt;

    % 计算各极端场景下的第二阶段成本（保留每个场景表达式）
    C_second_array = sdpvar(1, K);
    for k = 1:K
        C_th_k   = par.c_th * sum(var.Pth(:,k)) * dt;
        C_csp_k  = par.flag_csp * par.c_csp * sum(var.Pcsp(:,k)) * dt;
        C_grid_k = sum(par.price .* var.Pgrid(:,k)) * dt;

        if par.flag_DR == 1
            C_DR_k = par.c_DR_up_service * sum(var.P_up(:,k)) * dt + ...
                     par.c_DR_down_service * sum(var.P_down(:,k)) * dt + ...
                     par.c_cut_comp * sum(var.P_cut(:,k)) * dt + ...
                     par.c_DR_up_short * sum(var.P_up_short(:,k)) * dt + ...
                     par.c_DR_down_short * sum(var.P_down_short(:,k)) * dt;
        else
            C_DR_k = 0;
        end

        C_curt_k = par.c_curt * (sum(var.Pwind_curt(:,k)) + sum(var.Ppv_curt(:,k))) * dt;
        if par.flag_storage == 1
            C_es_k = par.c_es * (sum(var.Pch(:,k)) + sum(var.Pdis(:,k))) * dt;
        else
            C_es_k = 0;
        end

        Savings_trans_k = sum(par.price_East .* var.P_trans(:,k)) * dt;

        C_second_array(k) = C_th_k + C_csp_k + C_grid_k + C_DR_k + C_curt_k + C_es_k - Savings_trans_k;
    end

    % epigraph鲁棒目标：min C_first + Zworst, s.t. Zworst >= C_second_k
    Objective = C_first + var.Zworst;

    % 额外返回，供约束层与结果层复用
    obj_aux = struct();
    obj_aux.C_first = C_first;
    obj_aux.C_second_array = C_second_array;
end
