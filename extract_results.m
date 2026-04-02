function res = extract_results(var, par, Objective, sol)
% [导师终修版：平滑映射鲁棒决策至画图层]
    dt  = par.dt; tol = 1e-8;
    if isfield(par, 'compute_power_coeff') && ~isempty(par.compute_power_coeff)
        k = par.compute_power_coeff;
    else
        k = 1.0;
    end

    % 提取基础标称场景(k=1)用于可视化，保障与之前所有的作图脚本完全兼容
    res.Pwind = clip_nonneg(value(var.Pwind(:,1)), tol);
    res.Ppv   = clip_nonneg(value(var.Ppv(:,1)), tol);

    res.Pcsp     = clip_nonneg(value(var.Pcsp(:,1)), tol);
    res.Pcsp_dir = clip_nonneg(value(var.Pcsp_dir(:,1)), tol);
    res.Pcsp_ch  = clip_nonneg(value(var.Pcsp_ch(:,1)), tol);
    res.Pcsp_dis = clip_nonneg(value(var.Pcsp_dis(:,1)), tol);
    res.Ecsp     = clip_nonneg(value(var.Ecsp(:,1)), tol);

    res.Pth   = clip_nonneg(value(var.Pth(:,1)), tol);
    res.Pgrid = clip_nonneg(value(var.Pgrid(:,1)), tol);
    res.Pch   = clip_nonneg(value(var.Pch(:,1)), tol);
    res.Pdis  = clip_nonneg(value(var.Pdis(:,1)), tol);
    res.SOC   = clip_small(value(var.SOC(:,1)), tol);

    res.Pdc     = clip_nonneg(value(var.Pdc(:,1)), tol);
    res.P_IT    = clip_nonneg(value(var.P_IT(:,1)), tol);
    res.P_cool  = clip_nonneg(value(var.P_cool(:,1)), tol);
    res.T_in    = value(var.T_in(:,1)); 
    res.P_trans = clip_nonneg(value(var.P_trans(:,1)), tol); 

    res.P_rigid = clip_nonneg(value(var.P_rigid), tol);
    res.P_shift = clip_nonneg(value(var.P_shift), tol);
    res.P_cut   = clip_nonneg(value(var.P_cut(:,1)), tol);

    res.P_up         = clip_nonneg(value(var.P_up(:,1)), tol);
    res.P_down       = clip_nonneg(value(var.P_down(:,1)), tol);
    res.P_up_short   = clip_nonneg(value(var.P_up_short(:,1)), tol);
    res.P_down_short = clip_nonneg(value(var.P_down_short(:,1)), tol);

    res.Pwind_curt = clip_nonneg(value(var.Pwind_curt(:,1)), tol);
    res.Ppv_curt   = clip_nonneg(value(var.Ppv_curt(:,1)), tol);

    res.Uth  = clip_small(value(var.Uth), tol);
    res.SUth = clip_nonneg(value(var.SUth), tol);

    % --- 其余所有指标计算原封不动保留 (计算的也是 k=1 下的表现) ---
    res.DynamicPUE = (res.P_IT + res.P_cool) ./ max(res.P_IT, 1e-4);
    res.AveragePUE = mean(res.DynamicPUE);

    res.C_th = par.c_th * sum(res.Pth) * dt + par.c_start * sum(res.SUth);
    if isfield(par,'flag_csp') && par.flag_csp == 1, res.C_csp = par.c_csp * sum(res.Pcsp) * dt; else, res.C_csp = 0; end
    res.C_grid = sum(par.price .* res.Pgrid) * dt; res.C_shift = par.c_shift_comp * sum(res.P_shift) * dt;
    if isfield(par,'flag_DR') && par.flag_DR == 1
        res.C_DR_service = par.c_DR_up_service * sum(res.P_up) * dt + par.c_DR_down_service * sum(res.P_down) * dt + par.c_cut_comp * sum(res.P_cut) * dt;
        res.C_DR_short   = par.c_DR_up_short * sum(res.P_up_short) * dt + par.c_DR_down_short * sum(res.P_down_short) * dt;
    else
        res.C_DR_service = 0; res.C_DR_short = 0;
    end
    res.C_curt = par.c_curt * (sum(res.Pwind_curt) + sum(res.Ppv_curt)) * dt;
    if isfield(par,'flag_storage') && par.flag_storage == 1, res.C_es = par.c_es * (sum(res.Pch) + sum(res.Pdis)) * dt; else, res.C_es = 0; end

    res.C_th = clip_nonneg(res.C_th, tol); res.C_csp = clip_nonneg(res.C_csp, tol);
    res.C_grid = clip_nonneg(res.C_grid, tol); res.C_shift = clip_nonneg(res.C_shift, tol);
    res.C_DR_service = clip_nonneg(res.C_DR_service, tol); res.C_DR_short = clip_nonneg(res.C_DR_short, tol);
    res.C_curt = clip_nonneg(res.C_curt, tol); res.C_es = clip_nonneg(res.C_es, tol);
    res.C_DR_total = clip_nonneg(res.C_shift + res.C_DR_service + res.C_DR_short, tol);
    if isfield(par, 'price_East'), res.Savings_trans = sum(par.price_East .* res.P_trans) * dt; else, res.Savings_trans = 0; end

    res.Obj_total = clip_nonneg(value(Objective), tol); res.sol_info = sol.info;
    if isfield(sol, 'solve_time'), res.solve_time = sol.solve_time; else, res.solve_time = NaN; end

    res.E_shift = clip_nonneg(sum(res.P_shift) * dt, tol); res.E_cut = clip_nonneg(sum(res.P_cut) * dt, tol);
    res.E_up = clip_nonneg(sum(res.P_up) * dt, tol); res.E_down = clip_nonneg(sum(res.P_down) * dt, tol);
    res.E_up_short = clip_nonneg(sum(res.P_up_short) * dt, tol); res.E_down_short = clip_nonneg(sum(res.P_down_short) * dt, tol);
    res.E_grid = clip_nonneg(sum(res.Pgrid) * dt, tol); res.E_curt = clip_nonneg((sum(res.Pwind_curt) + sum(res.Ppv_curt)) * dt, tol);
    res.E_wind_used = clip_nonneg(sum(res.Pwind) * dt, tol); res.E_pv_used = clip_nonneg(sum(res.Ppv) * dt, tol);
    res.E_csp_used = clip_nonneg(sum(res.Pcsp) * dt, tol); res.E_renew_used = clip_nonneg(res.E_wind_used + res.E_pv_used + res.E_csp_used, tol);
    res.E_wind_avail = clip_nonneg(sum(par.Pwind_max) * dt, tol); res.E_pv_avail = clip_nonneg(sum(par.Ppv_max) * dt, tol);
    if isfield(par,'flag_csp') && par.flag_csp == 1, res.E_csp_avail = clip_nonneg(sum(par.Pcsp_avail) * dt, tol); else, res.E_csp_avail = 0; end
    res.E_renew_avail = clip_nonneg(res.E_wind_avail + res.E_pv_avail + res.E_csp_avail, tol);

    if res.E_renew_avail > tol, res.RenewUtilization = res.E_renew_used / res.E_renew_avail; else, res.RenewUtilization = 0; end
    res.RenewUtilization = min(max(clip_small(res.RenewUtilization, tol), 0), 1);

    if (res.E_up + res.E_up_short) > tol, res.UpResponseRate = res.E_up / (res.E_up + res.E_up_short); else, res.UpResponseRate = 1; end
    if (res.E_down + res.E_cut + res.E_down_short) > tol, res.DownResponseRate = (res.E_down + res.E_cut) / (res.E_down + res.E_cut + res.E_down_short); else, res.DownResponseRate = 1; end
    res.UpResponseRate = min(max(clip_small(res.UpResponseRate, tol), 0), 1); res.DownResponseRate = min(max(clip_small(res.DownResponseRate, tol), 0), 1);
    E_up_req = max(sum(par.DR_up_req) * dt, eps);
    E_down_req = max(sum(par.DR_down_req) * dt, eps);
    res.DRContributionUp = clip_nonneg(res.E_up / E_up_req, tol);
    res.DRContributionDown = clip_nonneg((res.E_down + res.E_cut) / E_down_req, tol);
    res.DRShortfallRateUp = clip_nonneg(res.E_up_short / E_up_req, tol);
    res.DRShortfallRateDown = clip_nonneg(res.E_down_short / E_down_req, tol);
    res.EquivalentPeakingCapacity = clip_nonneg(max(res.P_down + res.P_cut), tol);
    res.EquivalentValleyFillingCapacity = clip_nonneg(max(res.P_up), tol);

    res.DCPeak = max(res.Pdc); res.DCValley = min(res.Pdc); res.DCPeakValley = clip_nonneg(res.DCPeak - res.DCValley, tol); res.DCStd = clip_nonneg(std(res.Pdc), tol);
    res.SystemNetLoad = clip_small(par.Load_base + res.Pdc + res.Pch - res.Pdis - res.Pwind - res.Ppv - res.Pcsp, tol);
    res.SystemNetLoadPeak = max(res.SystemNetLoad); res.SystemNetLoadValley = min(res.SystemNetLoad);
    res.SystemNetLoadPeakValley = clip_nonneg(res.SystemNetLoadPeak - res.SystemNetLoadValley, tol); res.SystemNetLoadStd = clip_nonneg(std(res.SystemNetLoad), tol);
    res.ThermalMin = min(res.Pth); res.ThermalMax = max(res.Pth); res.ThermalPeakValley = clip_nonneg(res.ThermalMax - res.ThermalMin, tol);
    res.E_charge = clip_nonneg(sum(res.Pch) * dt, tol); res.E_discharge = clip_nonneg(sum(res.Pdis) * dt, tol);
    if isfield(par,'E_max') && par.E_max > tol, res.StorageEquivalentCycles = 0.5 * (res.E_charge + res.E_discharge) / par.E_max; else, res.StorageEquivalentCycles = 0; end
    res.StorageEquivalentCycles = clip_nonneg(res.StorageEquivalentCycles, tol);

    res.TaskRigidProfile = clip_nonneg(res.P_rigid / k, tol); res.TaskShiftProfile = clip_nonneg(res.P_shift / k, tol);
    res.TaskInterruptBaseProfile = clip_nonneg(par.P_cut_base / k, tol); res.TaskInterruptServedProfile = clip_nonneg((par.P_cut_base - res.P_cut) / k, tol);
    res.TaskInterruptCurtailedProfile = clip_nonneg(res.P_cut / k, tol); res.TaskTotalServedProfile = clip_nonneg(res.P_IT / k, tol);
    res.TaskRigidDemand = clip_nonneg(sum(par.P_rigid) * dt / k, tol); res.TaskShiftDemand = clip_nonneg(par.E_shift_total / k, tol);
    res.TaskInterruptDemand = clip_nonneg(sum(par.P_cut_base) * dt / k, tol); res.TaskTotalDemand = clip_nonneg(res.TaskRigidDemand + res.TaskShiftDemand + res.TaskInterruptDemand, tol);
    res.TaskRigidServed = clip_nonneg(sum(res.P_rigid) * dt / k, tol); res.TaskShiftServed = clip_nonneg(sum(res.P_shift) * dt / k, tol);
    res.TaskInterruptServed = clip_nonneg(sum(par.P_cut_base - res.P_cut) * dt / k, tol); res.TaskInterruptCurtailed = clip_nonneg(sum(res.P_cut) * dt / k, tol);
    res.TaskTotalServed = clip_nonneg(sum(res.TaskTotalServedProfile) * dt, tol);

    if res.TaskTotalDemand > tol, res.TaskCompletionRate = res.TaskTotalServed / res.TaskTotalDemand; else, res.TaskCompletionRate = 1; end
    res.TaskCompletionRate = min(max(clip_small(res.TaskCompletionRate, tol), 0), 1);
    if res.TaskInterruptDemand > tol, res.TaskCurtailRatio = res.TaskInterruptCurtailed / res.TaskInterruptDemand; else, res.TaskCurtailRatio = 0; end
    res.TaskCurtailRatio = min(max(clip_small(res.TaskCurtailRatio, tol), 0), 1);
    if res.TaskTotalDemand > tol, res.TaskShiftRatio = res.TaskShiftServed / res.TaskTotalDemand; res.TaskResponseRatio = (res.E_up + res.E_down + res.E_cut) / res.TaskTotalDemand; else, res.TaskShiftRatio = 0; res.TaskResponseRatio = 0; end
    res.TaskShiftRatio = min(max(clip_small(res.TaskShiftRatio, tol), 0), 1); res.TaskResponseRatio = min(max(clip_small(res.TaskResponseRatio, tol), 0), 1);

    renew_profile = res.Pwind + res.Ppv + res.Pcsp; res.GreenPowerForDCProfile = clip_nonneg(min(res.Pdc, renew_profile), tol); res.GreenPowerForDC = clip_nonneg(sum(res.GreenPowerForDCProfile) * dt, tol);
    E_dc = clip_nonneg(sum(res.Pdc) * dt, tol);
    if E_dc > tol, res.GreenPowerSupportRatio = res.GreenPowerForDC / E_dc; else, res.GreenPowerSupportRatio = 0; end
    if res.E_renew_used > tol, res.RenewableToDCShare = res.GreenPowerForDC / res.E_renew_used; else, res.RenewableToDCShare = 0; end
    if (E_dc + res.E_renew_used) > tol, res.DCRenewMatchIndex = 2 * res.GreenPowerForDC / (E_dc + res.E_renew_used); else, res.DCRenewMatchIndex = 0; end
    res.GreenPowerSupportRatio = min(max(clip_small(res.GreenPowerSupportRatio, tol), 0), 1); res.RenewableToDCShare = min(max(clip_small(res.RenewableToDCShare, tol), 0), 1); res.DCRenewMatchIndex = min(max(clip_small(res.DCRenewMatchIndex, tol), 0), 1);
    if res.TaskTotalServed > tol, res.ComputeEnergyIntensity = clip_nonneg(E_dc / res.TaskTotalServed, tol); else, res.ComputeEnergyIntensity = 0; end
end
function x = clip_small(x, tol), x(abs(x) < tol) = 0; end
function x = clip_nonneg(x, tol), x(abs(x) < tol) = 0; x = max(x, 0); end
