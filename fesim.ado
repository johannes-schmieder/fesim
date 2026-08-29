*! fesim 0.0.0-dev 28aug2026
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
    di as txt _newline "The akm/simple preset is available for simulation."

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
        di as txt _newline "  resolved defaults: " as result `"`config'"'
        di as txt _newline "Scalar parameter metadata (value, default, lower, upper)"
        matrix list `parameters', noheader format(%12.6g)
        return matrix parameters = `parameters'
        return local config `"`config'"'
        return local config_sources `"`config_sources'"'
        return local calibration_class `"`returned_calibration'"'
    }
    else {
        di as txt _newline "Configuration metadata for this preset is planned."
        return local calibration_class `"`calibration'"'
    }
    if `"`dgp'"' == "akm" & `"`resolved_preset'"' == "simple" {
        di as txt "Simulation is available for this preset."
    }
    else {
        di as txt "Simulation is not yet available for this preset."
    }

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
        CONNECTivity(string) PARAMETERS(string asis) noREPORT CLEAR ]

    local noreport ""
    if `"`report'"' == "noreport" {
        local noreport "noreport"
        local report ""
    }
    local config_options ""
    foreach name in dgp preset workers firms periods frequency start seed ///
        initial burnin jobrule truth connectivity {
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
        p_firm_size_sd p_eu p_ee p_ue p_wage_trend
    matrix `resolved_parameters' = r(parameters)
    scalar `p_mu' = `resolved_parameters'["mu", "value"]
    scalar `p_sd_worker' = `resolved_parameters'["sd_worker", "value"]
    scalar `p_sd_firm' = `resolved_parameters'["sd_firm", "value"]
    scalar `p_sd_error' = `resolved_parameters'["sd_error", "value"]
    scalar `p_firm_size_sd' = `resolved_parameters'["firm_size_sd", "value"]
    scalar `p_eu' = `resolved_parameters'["p_eu", "value"]
    scalar `p_ee' = `resolved_parameters'["p_ee", "value"]
    scalar `p_ue' = `resolved_parameters'["p_ue", "value"]
    scalar `p_wage_trend' = `resolved_parameters'["wage_trend", "value"]

    if `"`clear'"' == "" & (_N > 0 | c(k) > 0) {
        di as error "data are in memory; specify clear to permit replacement"
        exit 4
    }
    if `"`resolved_dgp'"' != "akm" | `"`resolved_preset'"' != "simple" {
        di as error "simulation is not yet implemented for dgp(`resolved_dgp') preset(`resolved_preset')"
        exit 498
    }
    if `"`resolved_connectivity'"' != "keep" {
        di as error "connectivity(`resolved_connectivity') is not yet implemented for akm/simple"
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

    tempname master_seed truth_moments truth_targets
    capture noisily mata: st_numscalar("`master_seed'", ///
        fesim_akm_simulate_to_stata( ///
        `resolved_workers', `resolved_firms', `resolved_periods', ///
        `resolved_start', "`resolved_time_format'", `resolved_delta', ///
        `seed_value', `seed_was_requested', "`resolved_initial'", ///
        `resolved_burnin', "`resolved_truth'", st_numscalar("`p_mu'"), ///
        st_numscalar("`p_sd_worker'"), st_numscalar("`p_sd_firm'"), ///
        st_numscalar("`p_sd_error'"), st_numscalar("`p_firm_size_sd'"), ///
        st_numscalar("`p_eu'"), st_numscalar("`p_ee'"), ///
        st_numscalar("`p_ue'"), st_numscalar("`p_wage_trend'"), ///
        "`truth_moments'", "`truth_targets'"))
    local simulation_rc = _rc
    if `simulation_rc' {
        if `had_data' quietly restore
        else clear
        quietly mata: fesim_rng_restore_state( ///
            "`caller_rng'", "`caller_rngstate'")
        exit `simulation_rc'
    }

    matrix rownames `truth_moments' = alpha_true_mean alpha_true_sd ///
        alpha_true_var psi_true_mean psi_true_sd psi_true_var ///
        epsilon_true_mean epsilon_true_sd epsilon_true_var ///
        cov_alpha_psi_true
    matrix colnames `truth_moments' = realized
    matrix rownames `truth_targets' = alpha_true_mean alpha_true_sd ///
        alpha_true_var psi_true_mean psi_true_sd psi_true_var ///
        epsilon_true_mean epsilon_true_sd epsilon_true_var ///
        cov_alpha_psi_true
    matrix colnames `truth_targets' = target
    capture quietly _fesim_moments, firms(`resolved_firms') ///
        truthmoments(`truth_moments') targets(`truth_targets')
    local moments_rc = _rc
    if `moments_rc' {
        if `had_data' quietly restore
        else clear
        quietly mata: fesim_rng_restore_state( ///
            "`caller_rng'", "`caller_rngstate'")
        exit `moments_rc'
    }
    tempname resolved_moments resolved_targets
    matrix `resolved_moments' = r(moments)
    matrix `resolved_targets' = r(targets)
    local firms_active = r(N_firms_active)
    local employment_rate = r(employment_rate)
    local realized_eu = r(p_eu_realized)
    local realized_ue = r(p_ue_realized)
    local realized_ee = r(p_ee_realized)
    if `had_data' quietly restore, not

    local recorded_seed : display %21.0f scalar(`master_seed')
    local recorded_seed = strtrim(`"`recorded_seed'"')
    local scientific_config = subinstr(`"`resolved_config'"', ///
        " report=`resolved_reporting'", "", .)
    local resolved_command `"fesim `scientific_config'"'
    _fesim_finalize, dgp(`resolved_dgp') dgpalias(`resolved_alias') ///
        preset(`resolved_preset') calibrationclass(`calibration_class') ///
        command(`"`resolved_command'"') seed(`recorded_seed') rng(mt64s) ///
        rngmethod(fixed_nonoverlapping_mt64s_component_streams) ///
        frequency(`resolved_frequency') ///
        internalclock(`resolved_internal_clock') jobrule(`resolved_jobrule') ///
        truth(`resolved_truth') burnin(`resolved_burnin') ///
        connectivity(`resolved_connectivity') reference(none) ///
        workers(`resolved_workers') firms(`resolved_firms') ///
        periods(`resolved_periods') parameters(`resolved_parameters') ///
        moments(`resolved_moments') targets(`resolved_targets') ///
        firmsactive(`firms_active') ///
        employmentrate(`employment_rate') peu(`realized_eu') ///
        pue(`realized_ue') pee(`realized_ee') ///
        reporting(`resolved_reporting')
    return add
end
