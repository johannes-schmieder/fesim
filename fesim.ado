*! fesim 1.2.0-dev 06sep2026
program define fesim, rclass
    version 16.0

    local invocation `"`0'"'
    gettoken first rest : invocation, parse(" ,")
    local first = lower(strtrim(`"`first'"'))

    if `"`first'"' == "version" {
        fesim__version `rest'
        return add
        exit
    }
    if `"`first'"' == "list" {
        fesim__list `rest'
        return add
        exit
    }
    if `"`first'"' == "presets" {
        fesim__presets `rest'
        return add
        exit
    }
    if `"`first'"' == "describe" {
        if strtrim(`"`rest'"') == "" {
            di as error "fesim describe requires a DGP name"
            exit 198
        }
        fesim__describe `rest'
        return add
        exit
    }
    if `"`first'"' == "" | `"`first'"' == "," {
        fesim__simulate `invocation'
        return add
        exit
    }

    di as error "unknown fesim subcommand: `first'"
    di as error "available discovery commands are version, list, presets, and describe"
    exit 198
end

program define fesim__version, rclass
    version 16.0
    if strtrim(`"`0'"') != "" {
        di as error "fesim version does not accept arguments or options"
        exit 198
    }

    quietly fesim_version_info
    local version `"`r(version)'"'
    local status `"`r(status)'"'
    return add
    return local command "version"
    di as txt "fesim " as result `"`version'"' as txt " (" `"`status'"' ")"
end

program define fesim__list, rclass
    version 16.0
    if strtrim(`"`0'"') != "" {
        di as error "fesim list does not accept arguments or options"
        exit 198
    }

    quietly fesim_registry, action(list)
    local dgps `"`r(dgps)'"'
    local all_aliases `"`r(aliases)'"'
    local qualified `"`r(qualified)'"'
    local status `"`r(status)'"'
    local n_dgps = r(n_dgps)

    di as txt _newline "Registered fesim DGP families"
    di as txt "  DGP          Presets            Aliases                    Status"
    foreach dgp of local dgps {
        quietly fesim_registry, action(resolve) dgp(`dgp')
        local presets `"`r(presets)'"'
        local aliases `"`r(aliases)'"'
        if `"`aliases'"' == "" local aliases "-"
        di as txt "  " %-12s `"`dgp'"' %-19s `"`presets'"' ///
            %-27s `"`aliases'"' `"`r(status)'"'
    }
    di as txt _newline "Qualified presets: `qualified'."

    return local command "list"
    return local dgps `"`dgps'"'
    return local aliases `"`all_aliases'"'
    return local qualified `"`qualified'"'
    return local status `"`status'"'
    return scalar n_dgps = `n_dgps'
end

program define fesim__presets, rclass
    version 16.0
    capture syntax [name(name=requested id="DGP")]
    if _rc {
        di as error "fesim presets accepts at most one DGP name"
        exit 198
    }

    if `"`requested'"' == "" {
        quietly fesim_registry, action(list)
        local dgps `"`r(dgps)'"'
        di as txt _newline "Registered fesim presets"
        foreach dgp of local dgps {
            quietly fesim_registry, action(resolve) dgp(`dgp')
            di as txt "  " %-12s `"`dgp'"' as result `"`r(presets)'"'
        }
        return local command "presets"
        return local dgps `"`dgps'"'
        exit
    }

    quietly fesim_registry, action(resolve) dgp(`requested')
    local dgp `"`r(dgp)'"'
    local alias `"`r(dgp_alias)'"'
    local presets `"`r(presets)'"'
    local aliases `"`r(aliases)'"'
    di as txt _newline "Presets for " as result `"`dgp'"' as txt ": " as result `"`presets'"'
    return local command "presets"
    return local dgp `"`dgp'"'
    return local dgp_alias `"`alias'"'
    return local presets `"`presets'"'
    return local aliases `"`aliases'"'
end

program define fesim__describe, rclass
    version 16.0
    syntax name(name=requested id="DGP") [ , PRESet(string) ]

    local registry_options `"action(resolve) dgp(`requested')"'
    if strtrim(`"`preset'"') != "" {
        local registry_options `"`registry_options' preset(`preset')"'
    }
    quietly fesim_registry, `registry_options'
    local dgp `"`r(dgp)'"'
    local alias `"`r(dgp_alias)'"'
    local resolved_preset `"`r(preset)'"'
    local title `"`r(title)'"'
    local calibration `"`r(calibration_class)'"'
    local status `"`r(status)'"'
    local configurable `"`r(configurable)'"'
    local config_schema `"`r(config_schema)'"'
    local frequencies `"`r(frequencies)'"'
    local jobrules `"`r(jobrules)'"'

    di as txt _newline `"`title'"'
    di as txt "  requested name:      " as result `"`alias'"'
    di as txt "  canonical DGP:       " as result `"`dgp'"'
    di as txt "  preset:              " as result `"`resolved_preset'"'
    di as txt "  calibration class:   " as result `"`calibration'"'
    di as txt "  implementation:      " as result `"`status'"'
    di as txt "  output frequencies:  " as result `"`frequencies'"'
    di as txt "  employer rule:       " as result `"`jobrules'"'

    if `"`configurable'"' == "yes" {
        quietly fesim_config, dgp(`dgp') preset(`resolved_preset')
        local config `"`r(config)'"'
        local config_sources `"`r(config_sources)'"'
        local scalar_parameters `"`r(parameter_names)'"'
        local returned_calibration `"`r(calibration_class)'"'
        tempname parameters
        matrix `parameters' = r(parameters)
        local matrix_results "`r(matrix_results)'"
        local matrix_parameters "`r(matrix_parameters)'"
        foreach result of local matrix_results {
            tempname tmp_`result'
            matrix `tmp_`result'' = r(`result')
        }

        di as txt _newline "  resolved defaults: " as result `"`config'"'
        di as txt _newline "Scalar parameter metadata (value, default, lower, upper)"
        matrix list `parameters', noheader format(%12.6g)
        return local config `"`config'"'
        return local config_sources `"`config_sources'"'
        return local calibration_class `"`returned_calibration'"'
    }
    else {
        di as txt _newline "Configuration metadata for this preset is planned."
        return local calibration_class `"`calibration'"'
    }
    if inlist(`"`dgp'"', "bm", "cpv", "blm") | (`"`dgp'"' == "akm" & ///
        inlist(`"`resolved_preset'"', "simple", "stylized", ///
        "germany_chk_2002_2009")) | ///
        (`"`dgp'"' == "akmpaygap" & ///
        inlist(`"`resolved_preset'"', "simple", "cck2016")) {
        di as txt "Simulation is available for this preset."
    }
    else {
        di as txt "Simulation is not yet available for this preset."
    }

    quietly _fesim_schema, dgp(`dgp') preset(`resolved_preset')
    foreach item in observed_variables truth_basic_variables truth_full_variables ///
        conditional_variables initial_modes networks source_note target_scope {
        local schema_`item' `"`r(`item')'"'
    }
    di as txt _newline "Observed variables: " as result `"`schema_observed_variables'"'
    di as txt "Basic truth additions: " as result `"`schema_truth_basic_variables'"'
    di as txt "Full truth further additions: " as result `"`schema_truth_full_variables'"'
    di as txt "Conditional variables: " as result `"`schema_conditional_variables'"'
    di as txt "Initial modes: " as result `"`schema_initial_modes'"'
    di as txt "Networks: " as result `"`schema_networks'"'
    di as txt "Source: " as result `"`schema_source_note'"'
    di as txt "Target scope: " as result `"`schema_target_scope'"'
    if `"`dgp'"' == "akmpaygap" ///
        di as txt "Network parameter rows are reserved; only network(random) is supported."
    di as txt _newline "Parameter units and bound endpoints (yes means included)"
    local parameter_units ""
    foreach name of local scalar_parameters {
        quietly fesim_registry, action(parameter) dgp(`dgp') ///
            preset(`resolved_preset') parameter(`name')
        di as txt "  `name': " as result `"`r(unit)'"' ///
            as txt " [lower included: `r(lower_closed)'; upper included: `r(upper_closed)']"
        local parameter_units `"`parameter_units' `name'=`r(unit)';"'
    }
    foreach item in observed_variables truth_basic_variables truth_full_variables ///
        conditional_variables initial_modes networks source_note target_scope {
        return local `item' `"`schema_`item''"'
    }
    if "`dgp'"=="blm" {
        di as txt "Optional matrix parameters: `matrix_parameters'"
        di as txt "Rows of three-index tables: (worker_type-1)*firm_types + origin_class."
        foreach result of local matrix_results {
            return matrix `result' = `tmp_`result''
        }
        return local matrix_parameters "`matrix_parameters'"
        return local matrix_results "`matrix_results'"
    }
    return local parameter_units `"`parameter_units'"'
    return matrix parameters = `parameters'
    return local config `"`config'"'
    return local config_sources `"`config_sources'"'
    return local calibration_class `"`returned_calibration'"'

    return local command "describe"
    return local dgp `"`dgp'"'
    return local dgp_alias `"`alias'"'
    return local preset `"`resolved_preset'"'
    return local title `"`title'"'
    return local status `"`status'"'
    return local configurable `"`configurable'"'
    return local config_schema `"`config_schema'"'
    return local frequencies `"`frequencies'"'
    return local jobrules `"`jobrules'"'
end

program define fesim__simulate, rclass
    version 16.0
    syntax [ , DGP(string) PRESet(string) WORKers(string) FIRMs(string) ///
        PERIODs(string) FREQuency(string) START(string) SEED(string) ///
        INITIAL(string) BURNIN(string) JOBRULE(string) TRUTH(string) ///
        CONNECTivity(string) NETWork(string) PARAMETERS(string asis) noREPORT CLEAR ]

    local noreport ""
    if `"`report'"' == "noreport" {
        local noreport "noreport"
        local report ""
    }
    local config_options ""
    foreach name in dgp preset workers firms periods frequency start seed ///
        initial burnin jobrule truth connectivity network {
        if `"``name''"' != "" {
            local config_options `"`config_options' `name'(``name'')"'
        }
    }
    if strtrim(`"`parameters'"') != "" {
        local config_options `"`config_options' parameters(`parameters')"'
    }
    if `"`report'"' != "" local config_options `"`config_options' report"'
    if `"`noreport'"' != "" local config_options `"`config_options' noreport"'

    quietly fesim_config, `config_options'
    if "`r(dgp)'"=="blm" {
        _fesim_blm, `config_options' `clear'
        return add
        exit
    }
    if `"`r(dgp)'"' == "cpv" {
        _fesim_cpv, `config_options' `clear'
        return add
        exit
    }
    if `"`r(dgp)'"' == "bm" {
        _fesim_bm, `config_options' `clear'
        return add
        exit
    }
    local resolved_dgp `"`r(dgp)'"'
    local resolved_alias `"`r(dgp_alias)'"'
    local resolved_preset `"`r(preset)'"'
    local calibration_class `"`r(calibration_class)'"'
    local resolved_frequency `"`r(frequency)'"'
    local resolved_seed `"`r(seed)'"'
    local resolved_initial `"`r(initial)'"'
    local resolved_jobrule `"`r(jobrule)'"'
    local resolved_truth `"`r(truth)'"'
    local resolved_connectivity `"`r(connectivity)'"'
    local resolved_network_mode `"`r(network)'"'
    local resolved_reporting `"`r(report)'"'
    local resolved_internal_clock `"`r(internal_clock)'"'
    local resolved_config `"`r(config)'"'
    local resolved_workers = r(workers)
    local resolved_firms = r(firms)
    local resolved_periods = r(periods)
    local resolved_burnin = r(burnin)
    local resolved_start = r(start_value)
    local resolved_delta = r(delta_years)
    local resolved_time_format `"`r(time_format)'"'
    tempname resolved_parameters p_mu p_sd_worker p_sd_firm p_sd_error ///
        p_firm_size_sd p_wage_trend p_eu p_ee p_ue p_rho_z_alpha ///
        p_rho_q_psi p_kappa_eu p_eu_worker p_eu_firm p_eu_duration ///
        p_kappa_ee p_ee_worker p_ee_firm p_ee_duration p_kappa_ue ///
        p_ue_worker p_ue_duration p_theta_sort p_theta_quality ///
        p_theta_up p_theta_down p_block_count p_block_log_bonus ///
        p_bridge_count p_ladder_down_share p_ladder_lateral_share ///
        p_ladder_up_share p_ladder_band p_female_share p_mu_m p_mu_f ///
        p_sd_worker_m p_sd_worker_f p_premium_intercept_m ///
        p_premium_intercept_f p_premium_loading_m p_premium_loading_f ///
        p_premium_deviation_sd_m p_premium_deviation_sd_f ///
        p_sd_error_m p_sd_error_f p_p_eu_m p_p_ee_m p_p_ue_m ///
        p_p_eu_f p_p_ee_f p_p_ue_f p_group_sort_m p_group_sort_f ///
        p_worker_sort_m p_worker_sort_f p_wage_trend_m p_wage_trend_f
    matrix `resolved_parameters' = r(parameters)
    scalar `p_firm_size_sd' = `resolved_parameters'["firm_size_sd", "value"]
    scalar `p_block_count' = `resolved_parameters'["block_count", "value"]
    scalar `p_block_log_bonus' = ///
        `resolved_parameters'["block_log_bonus", "value"]
    scalar `p_bridge_count' = `resolved_parameters'["bridge_count", "value"]
    scalar `p_ladder_down_share' = ///
        `resolved_parameters'["ladder_down_share", "value"]
    scalar `p_ladder_lateral_share' = ///
        `resolved_parameters'["ladder_lateral_share", "value"]
    scalar `p_ladder_up_share' = ///
        `resolved_parameters'["ladder_up_share", "value"]
    scalar `p_ladder_band' = ///
        `resolved_parameters'["ladder_band", "value"]
    if `"`resolved_dgp'"' == "akmpaygap" {
        foreach name in female_share mu_m mu_f sd_worker_m sd_worker_f ///
            premium_intercept_m premium_intercept_f premium_loading_m ///
            premium_loading_f premium_deviation_sd_m ///
            premium_deviation_sd_f sd_error_m sd_error_f p_eu_m p_ee_m ///
            p_ue_m p_eu_f p_ee_f p_ue_f group_sort_m group_sort_f ///
            worker_sort_m worker_sort_f wage_trend_m wage_trend_f {
            scalar `p_`name'' = ///
                `resolved_parameters'["`name'", "value"]
        }
    }
    else {
        scalar `p_mu' = `resolved_parameters'["mu", "value"]
        scalar `p_sd_worker' = `resolved_parameters'["sd_worker", "value"]
        scalar `p_sd_firm' = `resolved_parameters'["sd_firm", "value"]
        scalar `p_sd_error' = `resolved_parameters'["sd_error", "value"]
        scalar `p_wage_trend' = `resolved_parameters'["wage_trend", "value"]
    }
    if `"`resolved_dgp'"' == "akm" & ///
        `"`resolved_preset'"' == "simple" {
        scalar `p_eu' = `resolved_parameters'["p_eu", "value"]
        scalar `p_ee' = `resolved_parameters'["p_ee", "value"]
        scalar `p_ue' = `resolved_parameters'["p_ue", "value"]
    }
    else if `"`resolved_dgp'"' == "akm" {
        foreach name in rho_z_alpha rho_q_psi kappa_eu eu_worker ///
            eu_firm eu_duration kappa_ee ee_worker ee_firm ee_duration ///
            kappa_ue ue_worker ue_duration theta_sort theta_quality ///
            theta_up theta_down {
            scalar `p_`name'' = ///
                `resolved_parameters'["`name'", "value"]
        }
    }

    if `"`clear'"' == "" & (_N > 0 | c(k) > 0) {
        di as error "data are in memory; specify clear to permit replacement"
        exit 4
    }
    if !((`"`resolved_dgp'"' == "akm" & ///
        inlist(`"`resolved_preset'"', "simple", "stylized", ///
        "germany_chk_2002_2009")) | ///
        (`"`resolved_dgp'"' == "akmpaygap" & ///
        inlist(`"`resolved_preset'"', "simple", "cck2016"))) {
        di as error "simulation is not yet implemented for dgp(`resolved_dgp') preset(`resolved_preset')"
        exit 498
    }
    if `"`resolved_connectivity'"' == "force" {
        di as error "connectivity(`resolved_connectivity') is not implemented for `resolved_dgp'/`resolved_preset'"
        exit 498
    }
    quietly _fesim_load

    local seed_was_requested 0
    local seed_value 0
    if `"`resolved_seed'"' != "current" {
        local seed_was_requested 1
        local seed_value `resolved_seed'
    }
    local caller_rng `"`c(rng)'"'
    local caller_rngstate `"`c(rngstate)'"'
    local had_data = _N > 0 | c(k) > 0
    if `had_data' quietly preserve
    clear

    tempname runtime_timers runtime_simulate_scalar runtime_total_scalar
    quietly mata: st_matrix("`runtime_timers'", ///
        fesim_runtime_claim_timers(2))
    quietly mata: fesim_runtime_start(st_matrix("`runtime_timers'")[1, 1])
    quietly mata: fesim_runtime_start(st_matrix("`runtime_timers'")[1, 2])

    local handler_truth `"`resolved_truth'"'
    if `"`resolved_dgp'"' == "akmpaygap" local handler_truth "full"
    if `"`resolved_connectivity'"' == "largest" & ///
        `"`resolved_truth'"' == "none" & ///
        `"`resolved_dgp'"' != "akmpaygap" local handler_truth "basic"

    tempname master_seed truth_moments truth_targets bridge_ledger ///
        covariance_target group_moments group_targets decomposition ///
        decomposition_targets
    if `"`resolved_dgp'"' == "akm" & ///
        `"`resolved_preset'"' == "simple" {
        capture noisily mata: st_numscalar("`master_seed'", ///
            fesim_akm_simulate_to_stata( ///
            `resolved_workers', `resolved_firms', `resolved_periods', ///
            `resolved_start', "`resolved_time_format'", `resolved_delta', ///
            `seed_value', `seed_was_requested', "`resolved_initial'", ///
            `resolved_burnin', "`handler_truth'", ///
            "`resolved_network_mode'", ///
            st_numscalar("`p_block_count'"), ///
            st_numscalar("`p_block_log_bonus'"), ///
            st_numscalar("`p_bridge_count'"), ///
            st_numscalar("`p_ladder_down_share'"), ///
            st_numscalar("`p_ladder_lateral_share'"), ///
            st_numscalar("`p_ladder_up_share'"), ///
            st_numscalar("`p_ladder_band'"), ///
            st_numscalar("`p_mu'"), st_numscalar("`p_sd_worker'"), ///
            st_numscalar("`p_sd_firm'"), st_numscalar("`p_sd_error'"), ///
            st_numscalar("`p_firm_size_sd'"), st_numscalar("`p_eu'"), ///
            st_numscalar("`p_ee'"), st_numscalar("`p_ue'"), ///
            st_numscalar("`p_wage_trend'"), ///
            "`truth_moments'", "`truth_targets'", "`bridge_ledger'"))
    }
    else if `"`resolved_dgp'"' == "akm" {
        scalar `covariance_target' = .
        if `"`resolved_preset'"' == "germany_chk_2002_2009" ///
            scalar `covariance_target' = .0205
        capture noisily mata: st_numscalar("`master_seed'", ///
            fesim_emp_simulate_to_stata( ///
            `resolved_workers', `resolved_firms', `resolved_periods', ///
            `resolved_start', "`resolved_time_format'", `resolved_delta', ///
            `seed_value', `seed_was_requested', "`resolved_initial'", ///
            `resolved_burnin', "`handler_truth'", ///
            "`resolved_network_mode'", ///
            st_numscalar("`p_block_count'"), ///
            st_numscalar("`p_block_log_bonus'"), ///
            st_numscalar("`p_bridge_count'"), ///
            st_numscalar("`p_ladder_down_share'"), ///
            st_numscalar("`p_ladder_lateral_share'"), ///
            st_numscalar("`p_ladder_up_share'"), ///
            st_numscalar("`p_ladder_band'"), ///
            st_numscalar("`p_mu'"), st_numscalar("`p_sd_worker'"), ///
            st_numscalar("`p_sd_firm'"), st_numscalar("`p_sd_error'"), ///
            st_numscalar("`p_firm_size_sd'"), ///
            st_numscalar("`p_wage_trend'"), ///
            st_numscalar("`p_rho_z_alpha'"), ///
            st_numscalar("`p_rho_q_psi'"), ///
            st_numscalar("`p_kappa_eu'"), ///
            st_numscalar("`p_eu_worker'"), ///
            st_numscalar("`p_eu_firm'"), ///
            st_numscalar("`p_eu_duration'"), ///
            st_numscalar("`p_kappa_ee'"), ///
            st_numscalar("`p_ee_worker'"), ///
            st_numscalar("`p_ee_firm'"), ///
            st_numscalar("`p_ee_duration'"), ///
            st_numscalar("`p_kappa_ue'"), ///
            st_numscalar("`p_ue_worker'"), ///
            st_numscalar("`p_ue_duration'"), ///
            st_numscalar("`p_theta_sort'"), ///
            st_numscalar("`p_theta_quality'"), ///
            st_numscalar("`p_theta_up'"), ///
            st_numscalar("`p_theta_down'"), ///
            st_numscalar("`covariance_target'"), ///
            "`truth_moments'", "`truth_targets'", "`bridge_ledger'"))
    }
    else {
        capture noisily mata: st_numscalar("`master_seed'", ///
            fesim_paygap_simulate_to_stata( ///
            `resolved_workers', `resolved_firms', `resolved_periods', ///
            `resolved_start', "`resolved_time_format'", `resolved_delta', ///
            `seed_value', `seed_was_requested', "`resolved_initial'", ///
            `resolved_burnin', st_numscalar("`p_female_share'"), ///
            st_numscalar("`p_mu_m'"), st_numscalar("`p_mu_f'"), ///
            st_numscalar("`p_sd_worker_m'"), ///
            st_numscalar("`p_sd_worker_f'"), ///
            st_numscalar("`p_premium_intercept_m'"), ///
            st_numscalar("`p_premium_intercept_f'"), ///
            st_numscalar("`p_premium_loading_m'"), ///
            st_numscalar("`p_premium_loading_f'"), ///
            st_numscalar("`p_premium_deviation_sd_m'"), ///
            st_numscalar("`p_premium_deviation_sd_f'"), ///
            st_numscalar("`p_sd_error_m'"), ///
            st_numscalar("`p_sd_error_f'"), ///
            st_numscalar("`p_firm_size_sd'"), ///
            st_numscalar("`p_p_eu_m'"), st_numscalar("`p_p_ee_m'"), ///
            st_numscalar("`p_p_ue_m'"), st_numscalar("`p_p_eu_f'"), ///
            st_numscalar("`p_p_ee_f'"), st_numscalar("`p_p_ue_f'"), ///
            st_numscalar("`p_group_sort_m'"), ///
            st_numscalar("`p_group_sort_f'"), ///
            st_numscalar("`p_worker_sort_m'"), ///
            st_numscalar("`p_worker_sort_f'"), ///
            st_numscalar("`p_wage_trend_m'"), ///
            st_numscalar("`p_wage_trend_f'")))
    }
    local simulation_rc = _rc
    if `simulation_rc' {
        quietly mata: fesim_runtime_stop( ///
            st_matrix("`runtime_timers'")[1, 2])
        quietly mata: fesim_runtime_stop( ///
            st_matrix("`runtime_timers'")[1, 1])
        quietly mata: fesim_runtime_release(st_matrix("`runtime_timers'"))
        if `had_data' quietly restore
        else clear
        quietly mata: fesim_rng_restore_state( ///
            "`caller_rng'", "`caller_rngstate'")
        exit `simulation_rc'
    }
    quietly mata: st_numscalar("`runtime_simulate_scalar'", ///
        fesim_runtime_stop(st_matrix("`runtime_timers'")[1, 2]))

    local bridge_option ""
    if `"`resolved_network_mode'"' == "bridges" {
        capture confirm matrix `bridge_ledger'
        if _rc {
            if `had_data' quietly restore
            else clear
            quietly mata: fesim_rng_restore_state( ///
                "`caller_rng'", "`caller_rngstate'")
            di as error "bridge simulation did not return its exact ledger"
            exit 459
        }
        matrix colnames `bridge_ledger' = bridge_id workerid ///
            output_period internal_period source_firm target_firm ///
            source_block target_block
        local bridge_rows = rowsof(`bridge_ledger')
        local bridge_names ""
        forvalues bridge = 1/`bridge_rows' {
            local bridge_names `"`bridge_names' bridge_`bridge'"'
        }
        matrix rownames `bridge_ledger' = `bridge_names'
        local bridge_option "bridges(`bridge_ledger')"
    }

    if `"`resolved_dgp'"' == "akm" {
        matrix rownames `truth_moments' = alpha_true_mean alpha_true_sd ///
            alpha_true_var psi_true_mean psi_true_sd psi_true_var ///
            epsilon_true_mean epsilon_true_sd epsilon_true_var ///
            cov_alpha_psi_true
        matrix colnames `truth_moments' = realized
        matrix rownames `truth_targets' = alpha_true_mean alpha_true_sd ///
            alpha_true_var psi_true_mean psi_true_sd psi_true_var ///
            epsilon_true_mean epsilon_true_sd epsilon_true_var
        if inlist(`"`resolved_preset'"', "simple", ///
            "germany_chk_2002_2009") {
            matrix rownames `truth_targets' = alpha_true_mean alpha_true_sd ///
                alpha_true_var psi_true_mean psi_true_sd psi_true_var ///
                epsilon_true_mean epsilon_true_sd epsilon_true_var ///
                cov_alpha_psi_true
        }
        matrix colnames `truth_targets' = target
    }

    capture quietly _fesim_network, workers(`resolved_workers') ///
        firms(`resolved_firms') periods(`resolved_periods') ///
        connectivity(`resolved_connectivity')
    local network_rc = _rc
    if `network_rc' {
        quietly mata: fesim_runtime_stop( ///
            st_matrix("`runtime_timers'")[1, 1])
        quietly mata: fesim_runtime_release(st_matrix("`runtime_timers'"))
        if `had_data' quietly restore
        else clear
        quietly mata: fesim_rng_restore_state( ///
            "`caller_rng'", "`caller_rngstate'")
        exit `network_rc'
    }
    tempname resolved_network resolved_leaveout
    matrix `resolved_network' = r(network)
    matrix `resolved_leaveout' = r(leaveout)
    local network_workers = r(N_workers_sample)
    local network_components = r(components)
    local largest_observation_share = r(largest_component_obs_share)
    local largest_worker_share = r(largest_component_worker_share)
    local largest_firm_share = r(largest_component_firm_share)

    if `"`resolved_connectivity'"' == "largest" & ///
        `"`resolved_dgp'"' != "akmpaygap" {
        capture quietly _fesim_truth
        local truth_rc = _rc
        if `truth_rc' {
            quietly mata: fesim_runtime_stop( ///
                st_matrix("`runtime_timers'")[1, 1])
            quietly mata: fesim_runtime_release(st_matrix("`runtime_timers'"))
            if `had_data' quietly restore
            else clear
            quietly mata: fesim_rng_restore_state( ///
                "`caller_rng'", "`caller_rngstate'")
            exit `truth_rc'
        }
        matrix `truth_moments' = r(moments)
        if `"`resolved_truth'"' == "none" {
            quietly drop alpha_true psi_true time_true xb_true match_true ///
                epsilon_true lnwage_true
        }
    }

    local paygap_option ""
    if `"`resolved_dgp'"' == "akmpaygap" {
        capture noisily mata: fesim_paygap_results_to_stata( ///
            `resolved_periods', st_numscalar("`p_mu_m'"), ///
            st_numscalar("`p_mu_f'"), "`resolved_preset'", ///
            "`truth_moments'", "`group_moments'", "`group_targets'", ///
            "`decomposition'", "`decomposition_targets'")
        local paygap_rc = _rc
        if `paygap_rc' {
            quietly mata: fesim_runtime_stop( ///
                st_matrix("`runtime_timers'")[1, 1])
            quietly mata: fesim_runtime_release(st_matrix("`runtime_timers'"))
            if `had_data' quietly restore
            else clear
            quietly mata: fesim_rng_restore_state( ///
                "`caller_rng'", "`caller_rngstate'")
            exit `paygap_rc'
        }
        matrix rownames `truth_moments' = alpha_true_mean alpha_true_sd ///
            alpha_true_var psi_true_mean psi_true_sd psi_true_var ///
            epsilon_true_mean epsilon_true_sd epsilon_true_var ///
            cov_alpha_psi_true
        matrix colnames `truth_moments' = realized
        matrix `truth_targets' = J(10, 1, .)
        matrix rownames `truth_targets' = alpha_true_mean alpha_true_sd ///
            alpha_true_var psi_true_mean psi_true_sd psi_true_var ///
            epsilon_true_mean epsilon_true_sd epsilon_true_var ///
            cov_alpha_psi_true
        matrix colnames `truth_targets' = target
        matrix rownames `group_moments' = N_workers N_employed ///
            employment_rate lnwage_mean lnwage_sd alpha_mean alpha_sd ///
            premium_mean premium_sd epsilon_mean epsilon_sd ///
            corr_alpha_premium surplus_mean surplus_sd p_eu_realized ///
            p_ue_realized p_ee_realized
        matrix colnames `group_moments' = men women
        matrix rownames `group_targets' = N_workers N_employed ///
            employment_rate lnwage_mean lnwage_sd alpha_mean alpha_sd ///
            premium_mean premium_sd epsilon_mean epsilon_sd ///
            corr_alpha_premium surplus_mean surplus_sd p_eu_realized ///
            p_ue_realized p_ee_realized
        matrix colnames `group_targets' = men women
        matrix rownames `decomposition' = total_gap intercept ///
            worker_composition firm_total sorting premium_schedule time ///
            residual adding_up_error
        matrix colnames `decomposition' = male_reference female_reference ///
            symmetric
        matrix rownames `decomposition_targets' = total_gap intercept ///
            worker_composition firm_total sorting premium_schedule time ///
            residual adding_up_error
        matrix colnames `decomposition_targets' = male_reference ///
            female_reference symmetric
        local paygap_option ///
            "groupmoments(`group_moments') grouptargets(`group_targets') decomposition(`decomposition') decompositiontargets(`decomposition_targets')"
        if `"`resolved_truth'"' == "none" {
            quietly drop alpha_true psi_true time_true xb_true match_true ///
                epsilon_true lnwage_true firm_surplus_true ///
                psi_male_true psi_female_true
        }
        else if `"`resolved_truth'"' == "basic" {
            quietly drop firm_surplus_true psi_male_true psi_female_true
        }
    }

    local duration_option ""
    if `"`resolved_dgp'"' == "akm" & ///
        `"`resolved_preset'"' != "simple" {
        capture quietly _fesim_durations, deltayears(`resolved_delta')
        local duration_rc = _rc
        if `duration_rc' {
            quietly mata: fesim_runtime_stop( ///
                st_matrix("`runtime_timers'")[1, 1])
            quietly mata: fesim_runtime_release(st_matrix("`runtime_timers'"))
            if `had_data' quietly restore
            else clear
            quietly mata: fesim_rng_restore_state( ///
                "`caller_rng'", "`caller_rngstate'")
            exit `duration_rc'
        }
        tempname resolved_durations
        matrix `resolved_durations' = r(durations)
        local duration_option "durations(`resolved_durations')"
    }

    local common_target_option ""
    if `"`resolved_dgp'"' == "akm" ///
        local common_target_option "targets(`truth_targets')"
    capture quietly _fesim_moments, firms(`resolved_firms') ///
        truthmoments(`truth_moments') `common_target_option'
    local moments_rc = _rc
    if `moments_rc' {
        quietly mata: fesim_runtime_stop( ///
            st_matrix("`runtime_timers'")[1, 1])
        quietly mata: fesim_runtime_release(st_matrix("`runtime_timers'"))
        if `had_data' quietly restore
        else clear
        quietly mata: fesim_rng_restore_state( ///
            "`caller_rng'", "`caller_rngstate'")
        exit `moments_rc'
    }
    tempname resolved_moments resolved_targets
    matrix `resolved_moments' = r(moments)
    local common_targets_finalize ""
    if `"`resolved_dgp'"' == "akm" {
        matrix `resolved_targets' = r(targets)
        local common_targets_finalize "targets(`resolved_targets')"
    }
    local firms_active = r(N_firms_active)
    local employment_rate = r(employment_rate)
    local realized_eu = r(p_eu_realized)
    local realized_ue = r(p_ue_realized)
    local realized_ee = r(p_ee_realized)
    quietly mata: st_numscalar("`runtime_total_scalar'", ///
        fesim_runtime_stop(st_matrix("`runtime_timers'")[1, 1]))
    quietly mata: fesim_runtime_release(st_matrix("`runtime_timers'"))
    local runtime_total = scalar(`runtime_total_scalar')
    local runtime_simulate = scalar(`runtime_simulate_scalar')
    local runtime_output = max(`runtime_total' - `runtime_simulate', 0)
    if `had_data' quietly restore, not

    local recorded_seed : display %21.0f scalar(`master_seed')
    local recorded_seed = strtrim(`"`recorded_seed'"')
    local scientific_config = subinstr(`"`resolved_config'"', ///
        " report=`resolved_reporting'", "", .)
    local resolved_command `"fesim `scientific_config'"'
    local resolved_reference "none"
    local paygap_metadata ""
    if `"`resolved_dgp'"' == "akmpaygap" {
        local resolved_reference "male_premium_schedule"
        local paygap_metadata ///
            "groupcoding(0_men_1_women) gapdirection(men_minus_women) surplusnormalization(population_standard_normal_no_sample_restandardization)"
    }
    _fesim_finalize, dgp(`resolved_dgp') dgpalias(`resolved_alias') ///
        preset(`resolved_preset') calibrationclass(`calibration_class') ///
        command(`"`resolved_command'"') seed(`recorded_seed') rng(mt64s) ///
        rngmethod(fixed_nonoverlapping_mt64s_component_streams) ///
        frequency(`resolved_frequency') ///
        internalclock(`resolved_internal_clock') jobrule(`resolved_jobrule') ///
        truth(`resolved_truth') burnin(`resolved_burnin') ///
        connectivity(`resolved_connectivity') ///
        networkdesign(`resolved_network_mode') ///
        reference(`resolved_reference') `paygap_metadata' ///
        workers(`network_workers') firms(`resolved_firms') ///
        periods(`resolved_periods') parameters(`resolved_parameters') ///
        moments(`resolved_moments') `common_targets_finalize' ///
        `duration_option' `bridge_option' `paygap_option' ///
        network(`resolved_network') leaveout(`resolved_leaveout') ///
        components(`network_components') ///
        largestcomponentobsshare(`largest_observation_share') ///
        largestcomponentworkershare(`largest_worker_share') ///
        largestcomponentfirmshare(`largest_firm_share') ///
        runtimetotal(`runtime_total') runtimesolve(0) ///
        runtimesimulate(`runtime_simulate') ///
        runtimeoutput(`runtime_output') ///
        firmsactive(`firms_active') ///
        employmentrate(`employment_rate') peu(`realized_eu') ///
        pue(`realized_ue') pee(`realized_ee') ///
        reporting(`resolved_reporting')
    return add
end
