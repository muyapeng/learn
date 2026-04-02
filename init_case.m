function par = init_case(scenario_name, overrides)
% [导师终修版：两阶段鲁棒优化参数体系]
    if nargin < 1 || isempty(scenario_name), scenario_name = 'active_coord'; end
    if nargin < 2, overrides = struct(); end

    par.scenario_name = scenario_name;
    par.T  = 24;
    par.dt = 1;

    par.flag_storage = 1; par.flag_DR = 1; 
    par.flag_reserve_coupling = 1; par.flag_csp = 1;
    par.request_mode = 'auto'; par.request_up_scale = 1.0; 
    par.request_down_scale = 1.0; par.request_round_step = 0.5;

    par.netload_q_low = 0.35; par.netload_q_high = 0.75;
    par.price_q_low = 0.45; par.price_q_high = 0.75; par.renew_q_high = 0.60;
    par.up_trigger_score = 0.10; par.down_trigger_score = 0.15;

    par.wind_scale = 1.0; par.pv_scale = 1.0; par.csp_scale = 1.0;
    par.renew_scale = 1.80; par.storage_energy_scale = 1.20; par.storage_power_scale = 1.20;
    par.compute_power_coeff = 1.0;   

    % ==================== [核心新增] 两阶段鲁棒优化不确定集参数 ====================
    par.K = 3;                % 极端场景集合: 1=预测值, 2=最恶劣骤降(-15%), 3=最恶劣骤升(+15%)
    par.unc_margin = 0.15;    % 风光预测不确定度 (15%)
    % ==============================================================================

    par.Load_base = [60 58 57 56 55 58 65 70 75 80 85 88 90 92 93 95 96 94 90 85 80 75 70 65]';
    par.Pwind_max = [30 28 25 22 20 18 20 25 30 35 40 42 45 43 40 38 35 30 28 26 25 24 22 20]';
    par.Ppv_max   = [0 0 0 0 0 2 8 15 22 28 30 32 31 28 24 18 10 3 0 0 0 0 0 0]';
    par.Pcsp_avail= [0 0 0 0 0 1 3 6 10 14 18 20 21 20 17 12 8 3 0 0 0 0 0 0]';

    par.Pcsp_max = 25; par.Pcsp_dis_max = 15; par.Ecsp_max = 60; par.Ecsp_min = 5; par.Ecsp0 = 20;
    par.eta_csp_ch = 0.95; par.eta_csp_dis = 0.95; par.c_csp = 80;

    par.price = [420 410 400 400 420 500 620 760 920 1020 1080 1100 ...
                 1040 980 940 920 980 1180 1320 1260 1040 820 620 500]';

    par.Pth_min = 20; par.Pth_max = 80; par.RU = 20; par.RD = 20;
    par.c_th = 320; par.c_start = 2000; par.Pgrid_max = 120;
    par.E_max = 40; par.E_min = 5; par.Pch_max = 20; par.Pdis_max = 20; par.eta_ch = 0.95; par.eta_dis = 0.95; par.SOC0 = 20;

    % 数据中心物理参数
    par.Pdc_idle = 8; par.Pdc_max = 52;
    par.P_rigid = [10 10 10 10 10 10 12 12 12 12 12 12 12 12 12 12 12 12 10 10 10 10 10 10]';
    par.P_cut_base = [5 5 5 5 5 5 6 6 6 6 6 6 6 6 6 6 6 6 5 5 5 5 5 5]';
    par.cut_ratio_max = 0.5; par.E_shift_total = 60; par.P_shift_max = 10;
    par.shift_window = [0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0]';
    par.P_up_max = 16; par.P_down_max = 12; par.DR_hours_max = 10;
    % 回补/恢复效应参数（默认关闭，保持与历史版本一致）
    par.flag_rebound = 0;
    par.beta_rebound = 0.6;
    par.H_rebound = 3;
    par.P_rebound_max = 8;
    par.c_rebound = 30;

    par.T_out = [26 25 24 24 25 26 28 30 32 34 35 36 36 35 34 33 31 30 29 28 27 27 26 26]'; 
    par.T_in_min = 20.0; par.T_in_max = 26.0; par.T_in_0 = 23.0;     
    par.COP = 3.5; par.R_th = 1.5; par.C_th = 4.0; par.Pcool_max= 20.0; par.alpha_reserve = 0.15;

    par.c_shift_comp = 80; par.c_cut_comp = 180; par.c_DR_up_service = 10;
    par.c_DR_down_service = 60; par.c_DR_up_short = 180; par.c_DR_down_short = 600;
    par.c_curt = 900; par.c_es = 5;

    % 空间协同边界参数
    par.price_East = 950 * ones(par.T, 1); 
    par.P_rigid_East = 45 * ones(par.T, 1);  
    par.gamma_trans = 0.4; par.C_band = 15; par.mu_trans = 0.03;

    par.DR_up_req = zeros(par.T,1); par.DR_down_req = zeros(par.T,1); par.base_netload = zeros(par.T,1);

    switch lower(scenario_name)
        case 'no_response', par.flag_DR = 0; par.C_band = 0;
        case 'passive_shift', par.flag_DR = 0; par.C_band = 0;
        case 'peak_shed', par.flag_DR = 1; par.request_up_scale = 0.0; par.request_down_scale = 1.0;
        case 'active_coord', par.flag_DR = 1; par.request_up_scale = 1.0; par.request_down_scale = 1.0;
        otherwise, error('未知场景：%s', scenario_name);
    end

    par = apply_overrides(par, overrides);
    if strcmpi(scenario_name, 'no_response'), par = absorb_shift_into_rigid(par); end
    par = apply_scaling(par);

    if par.flag_DR == 1
        if strcmpi(par.request_mode, 'auto')
            [par.DR_up_req, par.DR_down_req, par.base_netload] = build_auto_requests(par);
        else
            if ~isfield(par, 'DR_up_req') || isempty(par.DR_up_req), par.DR_up_req = zeros(par.T,1); end
            if ~isfield(par, 'DR_down_req') || isempty(par.DR_down_req), par.DR_down_req = zeros(par.T,1); end
            par.base_netload = compute_base_netload(par);
        end
    else
        par.DR_up_req = zeros(par.T,1); par.DR_down_req = zeros(par.T,1); par.base_netload = compute_base_netload(par);
    end

    par = apply_overrides(par, overrides); par = refresh_compute_mapping(par);
end

% ---------------- 辅助函数 (保持不变) ----------------
function par = apply_overrides(par, overrides)
    if isempty(overrides), return; end
    fn = fieldnames(overrides); for i = 1:numel(fn), par.(fn{i}) = overrides.(fn{i}); end
end
function par = apply_scaling(par)
    par.Pwind_max = par.Pwind_max * par.wind_scale * par.renew_scale;
    par.Ppv_max = par.Ppv_max * par.pv_scale * par.renew_scale;
    par.Pcsp_avail = par.Pcsp_avail * par.csp_scale * par.renew_scale;
    e_scale = par.storage_energy_scale;
    if abs(e_scale - 1) > 1e-12
        par.E_max = par.E_max * e_scale; par.E_min = par.E_min * e_scale; par.SOC0 = par.SOC0 * e_scale;
    end
    p_scale = par.storage_power_scale;
    if abs(p_scale - 1) > 1e-12, par.Pch_max = par.Pch_max * p_scale; par.Pdis_max = par.Pdis_max * p_scale; end
    par.SOC0 = min(max(par.SOC0, par.E_min), par.E_max);
end
function par = absorb_shift_into_rigid(par)
    idx = find(par.shift_window > 0);
    if isempty(idx) || par.E_shift_total <= 0, par.E_shift_total = 0; par.P_shift_max = 0; return; end
    add_profile = zeros(par.T,1); add_profile(idx) = par.E_shift_total / (numel(idx) * par.dt);
    par.P_rigid = par.P_rigid + add_profile; par.E_shift_total = 0; par.P_shift_max = 0;
end
function net_load = compute_base_netload(par)
    dc_base = par.Pdc_idle + par.P_rigid + par.P_cut_base;
    renew_avail = par.Pwind_max + par.Ppv_max;
    if par.flag_csp == 1, renew_avail = renew_avail + par.Pcsp_avail; end
    net_load = par.Load_base + dc_base - renew_avail;
end
function [up_req, down_req, net_load] = build_auto_requests(par)
    T = par.T; net_load = compute_base_netload(par);
    dc_base = par.Pdc_idle + par.P_rigid + par.P_cut_base;
    renew_avail = par.Pwind_max + par.Ppv_max;
    if par.flag_csp == 1, renew_avail = renew_avail + par.Pcsp_avail; end
    nl_low = quantile(net_load, par.netload_q_low); nl_high = quantile(net_load, par.netload_q_high);
    low_netload_score = normalize_positive(nl_low - net_load); high_netload_score = normalize_positive(net_load - nl_high);
    p_low = quantile(par.price, par.price_q_low); p_high = quantile(par.price, par.price_q_high);
    cheap_score = normalize_positive(p_low - par.price); expensive_score = normalize_positive(par.price - p_high);
    r_high = quantile(renew_avail, par.renew_q_high); renew_high_score = normalize_positive(renew_avail - r_high);
    up_score = max(low_netload_score .* cheap_score, renew_high_score .* max(low_netload_score, cheap_score));
    down_score = high_netload_score .* expensive_score;
    up_score(up_score < par.up_trigger_score) = 0; down_score(down_score < par.down_trigger_score) = 0;
    raw_up_req = par.P_up_max * up_score * par.request_up_scale;
    raw_down_req = par.P_down_max * down_score * par.request_down_scale;
    if strcmpi(par.scenario_name, 'peak_shed'), raw_up_req = zeros(T,1); end
    up_cap = max(0, par.Pdc_max - dc_base);
    down_cap = min(par.P_down_max, par.P_cut_base + par.P_shift_max * par.shift_window);
    raw_up_req = min(raw_up_req, up_cap); raw_down_req = min(raw_down_req, down_cap);
    if strcmpi(par.scenario_name, 'active_coord')
        [raw_up_req, raw_down_req] = balance_request_energy(raw_up_req, raw_down_req, par.dt);
    end
    step = par.request_round_step; up_req = round(raw_up_req / step) * step; down_req = round(raw_down_req / step) * step;
    up_req = max(0, min(up_cap, up_req)); down_req = max(0, min(down_cap, down_req));
    up_req = min(up_req, par.P_up_max); down_req = min(down_req, par.P_down_max);
    if strcmpi(par.scenario_name, 'active_coord')
        [up_req, down_req] = rebalance_after_rounding(up_req, down_req, up_cap, down_cap, step, par.dt);
    end
end
function [u, d] = balance_request_energy(u, d, dt)
    Eu = sum(u) * dt; Ed = sum(d) * dt;
    if Eu > 1e-9 && Ed > 1e-9
        if Eu > Ed, u = u * (Ed / Eu); else, d = d * (Eu / Ed); end
    end
end
function [u, d] = rebalance_after_rounding(u, d, uCap, dCap, step, dt)
    maxIter = 5000;
    for it = 1:maxIter
        Eu = sum(u) * dt; Ed = sum(d) * dt; gap = Eu - Ed;
        if abs(gap) <= 0.5 * step * dt, break; end
        if gap > 0
            head = dCap - d; idxAdd = find(head >= step, 1, 'first');
            if ~isempty(idxAdd), [~, k] = max(head); d(k) = d(k) + step;
            else, idxReduce = find(u >= step, 1, 'first'); if isempty(idxReduce), break; end; [~, k] = max(u); u(k) = u(k) - step; end
        else
            head = uCap - u; idxAdd = find(head >= step, 1, 'first');
            if ~isempty(idxAdd), [~, k] = max(head); u(k) = u(k) + step;
            else, idxReduce = find(d >= step, 1, 'first'); if isempty(idxReduce), break; end; [~, k] = max(d); d(k) = d(k) - step; end
        end
        u = max(u, 0); d = max(d, 0);
    end
end
function par = refresh_compute_mapping(par)
    k = par.compute_power_coeff;
    par.TaskRigidBaseProfile = par.P_rigid / k; par.TaskInterruptBaseProfile = par.P_cut_base / k;
    par.TaskShiftDemand = par.E_shift_total / k; par.TaskRigidDemand = sum(par.P_rigid) * par.dt / k;
    par.TaskInterruptDemand = sum(par.P_cut_base) * par.dt / k;
end
function y = normalize_positive(x)
    x = max(0, x); xmax = max(x);
    if xmax <= 1e-9, y = zeros(size(x)); else, y = x / xmax; end
end
