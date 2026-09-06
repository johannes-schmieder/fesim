*! fesim canonical CPV public handler 1.1.0-dev 05sep2026
program define _fesim_cpv, rclass
    version 16.0
    syntax [, CLEAR *]
    if `"`clear'"' == "" & (_N > 0 | c(k) > 0) {
        di as error "data are in memory; specify clear to permit replacement"
        exit 4
    }
    quietly _fesim_load
    local caller_rng `"`c(rng)'"'
    local caller_state `"`c(rngstate)'"'
    tempname timers
    quietly mata: st_matrix("`timers'", fesim_runtime_claim_timers(3))
    quietly mata: fesim_runtime_start(st_matrix("`timers'")[1,1])
    preserve
    capture noisily _fesim_cpv_run, timers(`timers') `options'
    local rc = _rc
    if !`rc' return add
    quietly mata: fesim_runtime_release(st_matrix("`timers'"))
    if `rc' {
        quietly restore
        quietly mata: fesim_rng_restore_state("`caller_rng'", "`caller_state'")
        exit `rc'
    }
    quietly restore, not
end

program define _fesim_cpv_run, rclass
    version 16.0
    syntax , TIMERS(name) [*]
    quietly fesim_config, `options'
    foreach name in dgp_alias preset calibration_class frequency time_format initial ///
        truth connectivity report config seed {
        local cfg_`name' `"`r(`name')'"'
    }
    foreach name in workers firms periods burnin start_value delta_years {
        local cfg_`name' = r(`name')
    }
    tempname parameters primitives solver firm_summary timing master_seed ///
        moments network leaveout durations flows total
    matrix `parameters' = r(parameters)
    if `"`cfg_connectivity'"' == "force" {
        di as error "connectivity(force) is not implemented for CPV"
        exit 498
    }
    matrix `primitives' = J(1, 10, .)
    local column 0
    foreach name in b p_min p_max lambda_u lambda_e delta r beta sd_worker random_firms {
        local ++column
        matrix `primitives'[1, `column'] = `parameters'["`name'", "value"]
    }
    local random_firms = `parameters'["random_firms", "value"]
    local requested_seed = `"`cfg_seed'"' != "current"
    local seed 0
    if `requested_seed' local seed `cfg_seed'
    clear
    quietly mata: st_numscalar("`master_seed'", fesim_cpv_simulate_to_stata( ///
        `cfg_workers', `cfg_firms', `cfg_periods', `cfg_start_value', ///
        "`cfg_time_format'", "`cfg_frequency'", `seed', `requested_seed', ///
        "`cfg_initial'", `cfg_burnin', "`cfg_truth'", st_matrix("`primitives'"), ///
        `random_firms', "`solver'", "`firm_summary'", "`timing'", ///
        st_matrix("`timers'")))
    quietly _fesim_network, workers(`cfg_workers') firms(`cfg_firms') ///
        periods(`cfg_periods') connectivity(`cfg_connectivity')
    matrix `network' = r(network)
    matrix `leaveout' = r(leaveout)
    local sample_workers = r(N_workers_sample)
    local components = r(components)
    local obs_share = r(largest_component_obs_share)
    local worker_share = r(largest_component_worker_share)
    local firm_share = r(largest_component_firm_share)
    quietly _fesim_durations, deltayears(`cfg_delta_years')
    matrix `durations' = r(durations)
    quietly _fesim_moments, firms(`cfg_firms')
    matrix `moments' = r(moments)
    local firms_active = r(N_firms_active)
    local employment = r(employment_rate)
    local eu = r(p_eu_realized)
    local ue = r(p_ue_realized)
    local ee = r(p_ee_realized)
    quietly mata: fesim_cpv_results_to_stata("`solver'", "`flows'", ///
        `cfg_delta_years', `ue', `eu', `ee')
    quietly drop _cpv_eu _cpv_ee _cpv_ue _cpv_e _cpv_u _cpv_reneg
    quietly mata: st_numscalar("`total'", ///
        fesim_runtime_stop(st_matrix("`timers'")[1,1]))
    local solve = `timing'[1,1]
    local simulate = `timing'[1,2]
    local output = max(0, scalar(`total') - `solve' - `simulate')
    local seed : display %21.0f scalar(`master_seed')
    local seed = strtrim(`"`seed'"')
    local scientific = subinstr(`"`cfg_config'"', " report=`cfg_report'", "", .)
    _fesim_finalize, dgp(cpv) dgpalias(`cfg_dgp_alias') preset(`cfg_preset') ///
        calibrationclass(`cfg_calibration_class') command(`"fesim `scientific'"') ///
        seed(`seed') rng(mt64s) ///
        rngmethod(fixed_nonoverlapping_mt64s_component_streams) ///
        frequency(`cfg_frequency') internalclock(continuous_time) ///
        jobrule(end) truth(`cfg_truth') burnin(`cfg_burnin') ///
        connectivity(`cfg_connectivity') networkdesign(random) reference(none) ///
        workers(`sample_workers') firms(`cfg_firms') periods(`cfg_periods') ///
        parameters(`parameters') moments(`moments') solver(`solver') ///
        network(`network') leaveout(`leaveout') durations(`durations') ///
        firmsactive(`firms_active') employmentrate(`employment') ///
        peu(`eu') pue(`ue') pee(`ee') components(`components') ///
        largestcomponentobsshare(`obs_share') ///
        largestcomponentworkershare(`worker_share') ///
        largestcomponentfirmshare(`firm_share') ///
        runtimetotal(`=scalar(`total')') runtimesolve(`solve') ///
        runtimesimulate(`simulate') runtimeoutput(`output') reporting(`cfg_report')
    return add
    return matrix cpv_flows = `flows'
    return matrix cpv_firms = `firm_summary'
    return local model_class "canonical_CPV_bargaining"
    return local solver_status "converged_analytic"
    return local cpv_theory_scope "unconditioned_finite_economy"
    return local cpv_sample_scope "returned_worker_panel"
    return scalar cpv_events = `timing'[1,3]
    return scalar cpv_peak_block_rows = `timing'[1,5]
    return scalar cpv_block_workers = `timing'[1,6]
    char _dta[fesim_model_class] canonical_CPV_bargaining
    char _dta[fesim_cpv_theory_scope] unconditioned_finite_economy
    char _dta[fesim_cpv_sample_scope] returned_worker_panel
end
