*! fesim BLM finite-type public handler 1.2.0-rc.1 06sep2026
program define _fesim_blm, rclass
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
    capture noisily _fesim_blm_run, timers(`timers') `options'
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

program define _fesim_blm_run, rclass
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

    tempname parameters primitives timing master_seed moments network leaveout durations total ///
        cells generated_cells worker_counts generated_workers
    local matrix_results "`r(matrix_results)'"
    local cfg_model `"`r(blm_model)'"'
    local cfg_fingerprint "`r(blm_fingerprint)'"
    local matrix_inputs ""
    foreach result of local matrix_results {
        tempname tmp_`result'
        matrix `tmp_`result'' = r(`result')
    }
    matrix `parameters' = r(parameters)
    if "`cfg_connectivity'"=="force" {
        di as error "connectivity(force) is not implemented for BLM"
        exit 498
    }
    matrix `primitives' = J(1,12,.)
    local column 0
    foreach name in worker_types firm_types mu sd_worker sd_firm interaction sd_error ///
        lambda_move sorting rho mobility_wage origin_dependence {
        local ++column
        matrix `primitives'[1,`column'] = `parameters'["`name'","value"]
    }
    foreach result of local matrix_results {
        local matrix_inputs "`matrix_inputs' `tmp_`result''"
    }
    local L = `parameters'["worker_types","value"]
    local K = `parameters'["firm_types","value"]
    local requested_seed = "`cfg_seed'"!="current"
    local seed 0
    if `requested_seed' local seed `cfg_seed'
    clear
    quietly mata: st_numscalar("`master_seed'", fesim_blm_simulate_to_stata( ///
        `cfg_workers',`cfg_firms',`cfg_periods',`cfg_start_value', ///
        "`cfg_time_format'","`cfg_frequency'",`seed',`requested_seed', ///
        `cfg_burnin',"`cfg_truth'",st_matrix("`primitives'"), ///
        tokens(st_local("matrix_inputs")),"`cfg_preset'","`timing'",st_matrix("`timers'")))
    * Preserve the configuration's canonical values; repeated normalization is not provenance.
    quietly mata: fesim_blm_metadata(st_local("cfg_model"))
    quietly mata: fesim_blm_cells_to_stata(`L',`K',`cfg_periods',"`generated_cells'","`generated_workers'")
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

    if "`cfg_connectivity'"=="largest" {
        quietly mata: fesim_blm_cells_to_stata(`L',`K',`cfg_periods',"`cells'","`worker_counts'")
    }
    else {
        matrix `cells' = `generated_cells'
        matrix `worker_counts' = `generated_workers'
    }
    quietly drop _blm_l _blm_k _blm_epsilon _blm_moves
    quietly mata: st_numscalar("`total'", ///
        fesim_runtime_stop(st_matrix("`timers'")[1,1]))
    local solve = `timing'[1,1]
    local simulate = `timing'[1,2]
    local output = max(0, scalar(`total') - `solve' - `simulate')
    local seed : display %21.0f scalar(`master_seed')
    local seed = strtrim(`"`seed'"')
    local scientific = subinstr(`"`cfg_config'"', " report=`cfg_report'", "", .)
    _fesim_finalize, dgp(blm) dgpalias(`cfg_dgp_alias') preset(`cfg_preset') ///
        calibrationclass(`cfg_calibration_class') command(`"fesim `scientific'"') ///
        seed(`seed') rng(mt64s) ///
        rngmethod(fixed_nonoverlapping_mt64s_component_streams) ///
        frequency(`cfg_frequency') internalclock(month) ///
        jobrule(end) truth(`cfg_truth') burnin(`cfg_burnin') ///
        connectivity(`cfg_connectivity') networkdesign(random) reference(Bonhomme_Lamadon_Manresa_2019) ///
        workers(`sample_workers') firms(`cfg_firms') periods(`cfg_periods') ///
        parameters(`parameters') moments(`moments') ///
        network(`network') leaveout(`leaveout') durations(`durations') ///
        firmsactive(`firms_active') employmentrate(`employment') ///
        peu(`eu') pue(`ue') pee(`ee') components(`components') ///
        largestcomponentobsshare(`obs_share') ///
        largestcomponentworkershare(`worker_share') ///
        largestcomponentfirmshare(`firm_share') ///
        runtimetotal(`=scalar(`total')') runtimesolve(`solve') ///
        runtimesimulate(`simulate') runtimeoutput(`output') reporting(`cfg_report')
    return add

    foreach result of local matrix_results {
        return matrix `result' = `tmp_`result'', copy
    }
    return matrix blm_cells = `cells', copy
    return matrix blm_cells_generated = `generated_cells', copy
    tempname workers_table
    matrix `workers_table' = (`tmp_blm_worker_weights'',`generated_workers',`worker_counts')
    matrix colnames `workers_table' = probability generated returned
    local rownames ""
    forvalues l=1/`L' {
        local rownames "`rownames' l`l'"
    }
    matrix rownames `workers_table' = `rownames'
    return matrix blm_workers = `workers_table'
    return local matrix_results "`matrix_results'"
    return local model_class "BLM_style_finite_types"
    return local blm_model `"`cfg_model'"'
    return local blm_fingerprint "`cfg_fingerprint'"
    return local blm_model_scope "generated_finite_economy"
    return local blm_sample_scope "returned_complete_worker_panel"
    return scalar blm_moves_generated = `timing'[1,3]
    return scalar blm_peak_block_rows = `timing'[1,4]
    return scalar blm_block_workers = `timing'[1,5]
    return scalar blm_worker_months = `timing'[1,6]
    char _dta[fesim_model_class] BLM_style_finite_types
    char _dta[fesim_blm_model_scope] generated_finite_economy
    char _dta[fesim_blm_sample_scope] returned_complete_worker_panel
    char _dta[fesim_initial] random
    char _dta[fesim_blm_initialization] uniform_actual_firm_normal_cell_earnings_zero_tenure
end
