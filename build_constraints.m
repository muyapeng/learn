function Constraints = build_constraints(var, par)
% [导师终修版：两阶段鲁棒多场景约束集]

    T  = par.T;
    dt = par.dt;
    K  = par.K;
    Constraints = [];

    %% === 第一阶段 非预期性约束 (Non-anticipative Constraints) ===
    % 这些决策在未知实际风光前就必须下达
    Constraints = [Constraints, var.P_rigid == par.P_rigid];
    Constraints = [Constraints, sum(var.P_shift) * dt == par.E_shift_total];
    Constraints = [Constraints, var.SUth(1) >= var.Uth(1)];

    for t = 1:T
        Constraints = [Constraints, 0 <= var.P_shift(t) <= par.P_shift_max * par.shift_window(t)];
        if par.flag_DR == 1
            Constraints = [Constraints, var.U_up(t) + var.U_down(t) <= 1];
        else
            Constraints = [Constraints, var.U_up(t) == 0, var.U_down(t) == 0];
        end
        if par.flag_storage == 1
            Constraints = [Constraints, var.Uch(t) + var.Udis(t) <= 1];
        else
            Constraints = [Constraints, var.Uch(t) == 0, var.Udis(t) == 0];
        end
        if t > 1
            Constraints = [Constraints, var.SUth(t) >= var.Uth(t) - var.Uth(t-1)];
        end
    end

    if par.flag_DR == 1
        Constraints = [Constraints, sum(var.U_up + var.U_down) <= par.DR_hours_max];
    end

    %% === 第二阶段 极端场景实时物理约束 ===
    for k = 1:K
        % 动态生成不确定边界
        if k == 1
            W_avail = par.Pwind_max; P_avail = par.Ppv_max;
        elseif k == 2
            W_avail = par.Pwind_max * (1 - par.unc_margin); P_avail = par.Ppv_max * (1 - par.unc_margin);
        elseif k == 3
            W_avail = par.Pwind_max * (1 + par.unc_margin); P_avail = par.Ppv_max * (1 + par.unc_margin);
        end

        for t = 1:T
            % 1. 新能源与电网基础约束
            Constraints = [Constraints, 0 <= var.Pwind(t,k) <= W_avail(t), 0 <= var.Ppv(t,k) <= P_avail(t)];
            Constraints = [Constraints, var.Pwind(t,k) + var.Pwind_curt(t,k) == W_avail(t)];
            Constraints = [Constraints, var.Ppv(t,k) + var.Ppv_curt(t,k) == P_avail(t)];
            Constraints = [Constraints, var.Pwind_curt(t,k) >= 0, var.Ppv_curt(t,k) >= 0];
            Constraints = [Constraints, par.Pth_min * var.Uth(t) <= var.Pth(t,k) <= par.Pth_max * var.Uth(t)];
            Constraints = [Constraints, 0 <= var.Pgrid(t,k) <= par.Pgrid_max];

            if t > 1
                Constraints = [Constraints, var.Pth(t,k) - var.Pth(t-1,k) <= par.RU, var.Pth(t-1,k) - var.Pth(t,k) <= par.RD];
            end

            % 2. 光热与储能约束
            if par.flag_csp == 1
                Constraints = [Constraints, 0 <= var.Pcsp_dir(t,k) <= par.Pcsp_avail(t), 0 <= var.Pcsp_ch(t,k) <= par.Pcsp_avail(t)];
                Constraints = [Constraints, var.Pcsp_dir(t,k) + var.Pcsp_ch(t,k) <= par.Pcsp_avail(t)];
                Constraints = [Constraints, 0 <= var.Pcsp_dis(t,k) <= par.Pcsp_dis_max, 0 <= var.Pcsp(t,k) <= par.Pcsp_max];
                Constraints = [Constraints, var.Pcsp(t,k) == var.Pcsp_dir(t,k) + var.Pcsp_dis(t,k)];
                if t == 1
                    Constraints = [Constraints, var.Ecsp(t,k) == par.Ecsp0 + par.eta_csp_ch*var.Pcsp_ch(t,k)*dt - var.Pcsp_dis(t,k)*dt/par.eta_csp_dis];
                else
                    Constraints = [Constraints, var.Ecsp(t,k) == var.Ecsp(t-1,k) + par.eta_csp_ch*var.Pcsp_ch(t,k)*dt - var.Pcsp_dis(t,k)*dt/par.eta_csp_dis];
                end
                Constraints = [Constraints, par.Ecsp_min <= var.Ecsp(t,k) <= par.Ecsp_max];
            else
                Constraints = [Constraints, var.Pcsp_dir(t,k)==0, var.Pcsp_ch(t,k)==0, var.Pcsp_dis(t,k)==0, var.Pcsp(t,k)==0, var.Ecsp(t,k)==0];
            end

            if par.flag_storage == 1
                Constraints = [Constraints, 0 <= var.Pch(t,k) <= par.Pch_max*var.Uch(t), 0 <= var.Pdis(t,k) <= par.Pdis_max*var.Udis(t)];
                if t == 1
                    Constraints = [Constraints, var.SOC(t,k) == par.SOC0 + par.eta_ch*var.Pch(t,k)*dt - var.Pdis(t,k)*dt/par.eta_dis];
                else
                    Constraints = [Constraints, var.SOC(t,k) == var.SOC(t-1,k) + par.eta_ch*var.Pch(t,k)*dt - var.Pdis(t,k)*dt/par.eta_dis];
                end
                Constraints = [Constraints, par.E_min <= var.SOC(t,k) <= par.E_max];
                if par.flag_reserve_coupling == 1
                    Constraints = [Constraints, var.SOC(t,k) >= par.E_min + par.alpha_reserve * var.P_rigid(t)];
                end
            else
                Constraints = [Constraints, var.Pch(t,k)==0, var.Pdis(t,k)==0, var.SOC(t,k)==par.SOC0];
            end

            % 3. 需求响应约束
            if par.flag_DR == 1
                Constraints = [Constraints, 0 <= var.P_cut(t,k) <= par.cut_ratio_max * par.P_cut_base(t), var.P_cut(t,k) <= par.DR_down_req(t)];
                Constraints = [Constraints, 0 <= var.P_up(t,k) <= par.P_up_max * var.U_up(t), 0 <= var.P_down(t,k) <= par.P_down_max * var.U_down(t)];
                Constraints = [Constraints, var.P_up(t,k) <= par.DR_up_req(t), var.P_down(t,k) <= par.DR_down_req(t)];
                Constraints = [Constraints, var.P_down(t,k) <= var.P_shift(t) + (par.P_cut_base(t) - var.P_cut(t,k))];
                Constraints = [Constraints, var.P_IT(t,k) + var.P_cool(t,k) <= par.Pdc_max];
                Constraints = [Constraints, var.P_up_short(t,k) >= 0, var.P_down_short(t,k) >= 0];
                Constraints = [Constraints, var.P_up(t,k) + var.P_up_short(t,k) == par.DR_up_req(t)];
                Constraints = [Constraints, var.P_down(t,k) + var.P_cut(t,k) + var.P_down_short(t,k) == par.DR_down_req(t)];
            else
                Constraints = [Constraints, var.P_cut(t,k)==0, var.P_up(t,k)==0, var.P_down(t,k)==0, var.P_up_short(t,k)==0, var.P_down_short(t,k)==0];
            end

            % 4. 东数西算与热惯性
            Constraints = [Constraints, 0 <= var.P_trans(t,k) <= par.C_band, var.P_trans(t,k) <= par.gamma_trans * par.P_rigid_East(t)];
            Constraints = [Constraints, var.P_IT(t,k) == par.Pdc_idle + var.P_rigid(t) + var.P_shift(t) + (par.P_cut_base(t) - var.P_cut(t,k)) + var.P_up(t,k) - var.P_down(t,k) + var.P_trans(t,k)];
            Constraints = [Constraints, var.Pdc(t,k) == var.P_IT(t,k) + var.P_cool(t,k) + par.mu_trans * var.P_trans(t,k)];
            Constraints = [Constraints, 0 <= var.P_cool(t,k) <= par.Pcool_max];
            
            decay = par.dt / (par.R_th * par.C_th);
            if t == 1
                Constraints = [Constraints, var.T_in(t,k) == par.T_in_0*(1-decay) + par.T_out(t)*decay + (par.dt/par.C_th)*var.P_IT(t,k) - (par.dt*par.COP/par.C_th)*var.P_cool(t,k)];
            else
                Constraints = [Constraints, var.T_in(t,k) == var.T_in(t-1,k)*(1-decay) + par.T_out(t)*decay + (par.dt/par.C_th)*var.P_IT(t,k) - (par.dt*par.COP/par.C_th)*var.P_cool(t,k)];
                Constraints = [Constraints, -1.5 <= var.T_in(t,k) - var.T_in(t-1,k) <= 1.5];
            end
            Constraints = [Constraints, par.T_in_min <= var.T_in(t,k) <= par.T_in_max];

            % 5. 功率平衡
            Constraints = [Constraints, var.Pwind(t,k) + var.Ppv(t,k) + var.Pcsp(t,k) + var.Pth(t,k) + var.Pgrid(t,k) + var.Pdis(t,k) == par.Load_base(t) + var.Pdc(t,k) + var.Pch(t,k)];
        end % end t

        % 强耦合：所有极端场景的日末状态必须恢复 (保证真正鲁棒闭环)
        Constraints = [Constraints, var.SOC(T,k) == par.SOC0];
        if par.flag_csp == 1, Constraints = [Constraints, var.Ecsp(T,k) == par.Ecsp0]; end
        if par.flag_DR == 1, Constraints = [Constraints, sum(var.P_up(:,k))*dt == sum(var.P_down(:,k))*dt]; end
    end % end k
end