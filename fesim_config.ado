*! fesim common configuration resolver 1.1.0-dev 05sep2026
program define fesim_config, rclass
    version 16.0
    syntax [ , DGP(string) PRESet(string) WORKers(string) FIRMs(string) ///
        PERIODs(string) FREQuency(string) START(string) SEED(string) ///
        INITIAL(string) BURNIN(string) JOBRULE(string) TRUTH(string) ///
        CONNECTivity(string) NETWork(string) PARAMETERS(string asis) noREPORT ]

    local noreport ""
    if `"`report'"' == "noreport" {
        local noreport "noreport"
        local report ""
    }
    if `"`report'"' != "" & `"`noreport'"' != "" {
        di as error "report and noreport may not be specified together"
        exit 198
    }

    local requested_dgp = lower(strtrim(`"`dgp'"'))
    if `"`requested_dgp'"' == "" local requested_dgp "akm"
    local requested_preset = lower(strtrim(`"`preset'"'))
    local registry_options `"action(resolve) dgp(`requested_dgp')"'
    if `"`requested_preset'"' != "" {
        local registry_options `"`registry_options' preset(`requested_preset')"'
    }
    quietly fesim_registry, `registry_options'
    local canonical `"`r(dgp)'"'
    local alias `"`r(dgp_alias)'"'
    local resolved_preset `"`r(preset)'"'
    local calibration_class `"`r(calibration_class)'"'
    local configurable `"`r(configurable)'"'
    local config_schema `"`r(config_schema)'"'
    if `"`configurable'"' != "yes" {
        di as error "configuration is not yet available for dgp(`canonical') preset(`resolved_preset')"
        exit 498
    }

    quietly fesim_registry, action(parameters) dgp(`canonical') preset(`resolved_preset')
    local scalar_parameters `"`r(scalar_parameters)'"'
    local model_parameters `"`r(model_parameters)'"'
    local network_parameters `"`r(network_parameters)'"'

    foreach name of local scalar_parameters {
        quietly fesim_registry, action(parameter) dgp(`canonical') ///
            preset(`resolved_preset') parameter(`name')
        local value_`name' `"`r(default)'"'
        local default_`name' `"`r(default)'"'
        local source_`name' `"`r(default_source)'"'
    }

    local named_scalar_overrides ""
    foreach name in workers firms periods burnin {
        if `"``name''"' != "" {
            local value_`name' `"``name''"'
            local source_`name' "option"
            local named_scalar_overrides `"`named_scalar_overrides' `name'"'
        }
    }
    local named_scalar_overrides = strtrim(`"`named_scalar_overrides'"')

    local parameter_overrides ""
    local parameter_names ""
    local ntokens : word count `parameters'
    if mod(`ntokens', 2) {
        di as error "parameters() requires whitespace-separated name value pairs"
        exit 198
    }
    tokenize `"`parameters'"'
    local i 1
    while `i' <= `ntokens' {
        local name = lower(strtrim(`"``i''"'))
        local j = `i' + 1
        local value `"``j''"'
        if !`: list name in scalar_parameters' {
            di as error "unknown or non-scalar fesim parameter in parameters(): `name'"
            exit 198
        }
        quietly fesim_registry, action(parameter) dgp(`canonical') ///
            preset(`resolved_preset') parameter(`name')
        if `"`r(parameters_allowed)'"' != "yes" {
            di as error "parameter `name' may not be set through parameters()"
            exit 198
        }
        if `: list name in parameter_names' {
            di as error "parameter `name' is specified more than once in parameters()"
            exit 198
        }
        if `: list name in named_scalar_overrides' {
            di as error "parameter `name' is specified both as an option and in parameters()"
            exit 198
        }
        local value_`name' `"`value'"'
        local source_`name' "parameters"
        local parameter_names `"`parameter_names' `name'"'
        local i = `i' + 2
    }
    local parameter_names = strtrim(`"`parameter_names'"')
    local has_block_count : list posof "block_count" in parameter_names
    local has_block_log_bonus : list posof "block_log_bonus" in parameter_names
    local has_bridge_count : list posof "bridge_count" in parameter_names
    local has_ladder_down_share : list posof "ladder_down_share" in parameter_names
    local has_ladder_lateral_share : list posof "ladder_lateral_share" in parameter_names
    local has_ladder_up_share : list posof "ladder_up_share" in parameter_names
    local has_ladder_band : list posof "ladder_band" in parameter_names

    local network = lower(strtrim(`"`network'"'))
    local source_network "option"
    if `"`network'"' == "" {
        local network "random"
        local source_network "package"
    }
    if !inlist(`"`network'"', "random", "blocks", "bridges", "ladder") {
        di as error "network() must be random, blocks, bridges, or ladder"
        exit 198
    }
    if inlist(`"`canonical'"', "akmpaygap", "bm", "cpv") & `"`network'"' != "random" {
        di as error "`canonical' currently requires network(random)"
        exit 198
    }
    if `"`network'"' == "bridges" & `"`source_bridge_count'"' != "parameters" {
        local value_bridge_count = real(`"`value_block_count'"') - 1
        local default_bridge_count `"`value_bridge_count'"'
        local source_bridge_count "derived"
    }
    if `"`network'"' == "bridges" {
        local value_block_log_bonus "0"
        local default_block_log_bonus "0"
        local source_block_log_bonus "design"
    }

    foreach name of local scalar_parameters {
        local value `"`value_`name''"'
        capture confirm number `value'
        if _rc | missing(real(`"`value'"')) {
            di as error "`name' must be a nonmissing numeric scalar"
            exit 198
        }
        quietly fesim_registry, action(parameter) dgp(`canonical') ///
            preset(`resolved_preset') parameter(`name')
        if `"`r(type)'"' == "integer" & real(`"`value'"') != floor(real(`"`value'"')) {
            di as error "`name' must be an integer"
            exit 198
        }
        local lower `"`r(lower)'"'
        local upper `"`r(upper)'"'
        if `"`lower'"' != "." {
            if (`"`r(lower_closed)'"' == "yes" & real(`"`value'"') < real(`"`lower'"')) | ///
                (`"`r(lower_closed)'"' == "no" & real(`"`value'"') <= real(`"`lower'"')) {
                di as error "`name' is below its registered lower bound"
                exit 198
            }
        }
        if `"`upper'"' != "." {
            if (`"`r(upper_closed)'"' == "yes" & real(`"`value'"') > real(`"`upper'"')) | ///
                (`"`r(upper_closed)'"' == "no" & real(`"`value'"') >= real(`"`upper'"')) {
                di as error "`name' is above its registered upper bound"
                exit 198
            }
        }
        local formatted : display %21.15g real(`"`value'"')
        local value_`name' = strtrim(`"`formatted'"')
    }

    if `"`canonical'"' == "cpv" {
        if real(`"`value_p_max'"') < real(`"`value_p_min'"') {
            di as error "CPV p_max must be at least p_min"
            exit 198
        }
    }
    else if `"`canonical'"' == "bm" {
        if real(`"`value_p'"') <= real(`"`value_b'"') {
            di as error "BM productivity p must exceed b"
            exit 198
        }
    }
    else if `"`canonical'"' == "akmpaygap" {
        if real(`"`value_firms'"') < 2 {
            di as error "firms() must be at least 2 for akmpaygap/`resolved_preset'"
            exit 198
        }
        if real(`"`value_p_eu_m'"') + ///
            real(`"`value_p_ee_m'"') >= 1 {
            di as error "p_eu_m + p_ee_m must be strictly less than 1"
            exit 198
        }
        if real(`"`value_p_eu_f'"') + ///
            real(`"`value_p_ee_f'"') >= 1 {
            di as error "p_eu_f + p_ee_f must be strictly less than 1"
            exit 198
        }
    }
    else if `"`resolved_preset'"' == "simple" {
        if real(`"`value_p_eu'"') + real(`"`value_p_ee'"') >= 1 {
            di as error "p_eu + p_ee must be strictly less than 1"
            exit 198
        }
        if real(`"`value_firms'"') < 2 & real(`"`value_p_ee'"') > 0 {
            di as error "firms() must be at least 2 when p_ee is positive"
            exit 198
        }
    }
    else if (`"`resolved_preset'"' != "simple" & `"`canonical'"' != "cpv") {
        if real(`"`value_firms'"') < 2 {
            di as error "firms() must be at least 2 for akm/`resolved_preset'"
            exit 198
        }
        if real(`"`value_sd_worker'"') == 0 & ///
            real(`"`value_rho_z_alpha'"') != 0 {
            di as error "rho_z_alpha must be zero when sd_worker is zero"
            exit 198
        }
        if real(`"`value_sd_firm'"') == 0 & ///
            real(`"`value_rho_q_psi'"') != 0 {
            di as error "rho_q_psi must be zero when sd_firm is zero"
            exit 198
        }
    }
    if !inlist(`"`canonical'"', "bm", "cpv") & abs(real(`"`value_ladder_down_share'"') + ///
        real(`"`value_ladder_lateral_share'"') + ///
        real(`"`value_ladder_up_share'"') - 1) > 1e-12 {
        di as error "ladder direction shares must sum to one"
        exit 198
    }
    if real(`"`value_workers'"') * real(`"`value_periods'"') > 2147483647 {
        di as error "workers() times periods() exceeds the supported observation count"
        exit 198
    }
    if inlist(`"`network'"', "blocks", "bridges") & ///
        real(`"`value_block_count'"') > ///
        min(real(`"`value_workers'"'), real(`"`value_firms'"')) {
        di as error "block_count may not exceed workers() or firms()"
        exit 198
    }
    if `"`network'"' == "bridges" & ///
        real(`"`value_firms'"') < 2 * real(`"`value_block_count'"') {
        di as error "network(bridges) requires at least two firms per block"
        exit 198
    }
    if !inlist(`"`network'"', "blocks", "bridges") & ///
        (`has_block_count' | `has_block_log_bonus' | `has_bridge_count') {
        di as error "network design parameters require network(blocks) or network(bridges)"
        exit 198
    }
    if `"`network'"' != "ladder" & ///
        (`has_ladder_down_share' | `has_ladder_lateral_share' | ///
        `has_ladder_up_share' | `has_ladder_band') {
        di as error "ladder parameters require network(ladder)"
        exit 198
    }
    if `"`network'"' == "blocks" & `has_bridge_count' {
        di as error "bridge_count requires network(bridges)"
        exit 198
    }
    if `"`network'"' == "bridges" & ///
        `has_block_log_bonus' {
        di as error "block_log_bonus is not used by strict network(bridges)"
        exit 198
    }
    if `"`network'"' == "bridges" & ///
        real(`"`value_bridge_count'"') < real(`"`value_block_count'"') - 1 {
        di as error "bridge_count must be at least block_count minus one"
        exit 198
    }
    if `"`network'"' == "bridges" & ///
        real(`"`value_bridge_count'"') > real(`"`value_workers'"') {
        di as error "bridge_count may not exceed workers()"
        exit 198
    }

    local frequency = lower(strtrim(`"`frequency'"'))
    local source_frequency "option"
    if `"`frequency'"' == "" {
        local frequency "year"
        local source_frequency "package"
    }
    local start = lower(strtrim(`"`start'"'))
    local source_start "option"
    if `"`start'"' == "" {
        if inlist(`"`resolved_preset'"', ///
            "germany_chk_2002_2009", "cck2016") {
            if `"`frequency'"' == "year" local start "2002"
            else if `"`frequency'"' == "quarter" local start "2002q1"
            else local start "2002m1"
            local source_start "preset"
        }
        else local source_start "package"
    }
    local time_options `"frequency(`frequency') periods(`value_periods')"'
    if `"`start'"' != "" local time_options `"`time_options' start(`start')"'
    quietly fesim_time, `time_options'
    local frequency `"`r(frequency)'"'
    local start `"`r(start)'"'
    local time_format `"`r(format)'"'
    local interval_unit `"`r(interval_unit)'"'
    local internal_clock `"`r(internal_clock)'"'
    if inlist(`"`canonical'"', "bm", "cpv") local internal_clock "continuous_time"
    else if `"`canonical'"' == "akmpaygap" local internal_clock "output_period"
    else if (`"`resolved_preset'"' != "simple" & `"`canonical'"' != "cpv") local internal_clock "month"
    local start_value = r(start_value)
    local end_value = r(end_value)
    local periods_per_year = r(periods_per_year)
    local delta_years = r(delta_years)

    if inlist(`"`canonical'"', "bm", "cpv") & ///
        real(`"`value_periods'"') * `delta_years' > 100000 {
        di as error "Continuous-time retained horizon may not exceed 100000 years"
        exit 198
    }

    local seed = lower(strtrim(`"`seed'"'))
    local source_seed "option"
    if `"`seed'"' == "" {
        local seed "current"
        local source_seed "package"
    }
    if `"`source_seed'"' == "option" {
        capture confirm integer number `seed'
        if _rc | real(`"`seed'"') < 0 | real(`"`seed'"') > 2147483647 {
            di as error "seed() must be an integer from 0 through 2147483647"
            exit 198
        }
        local formatted : display %21.15g real(`"`seed'"')
        local seed = strtrim(`"`formatted'"')
    }

    foreach name in initial jobrule truth connectivity {
        local `name' = lower(strtrim(`"``name''"'))
        local source_`name' "option"
    }
    if `"`initial'"' == "" {
        if `"`canonical'"' == "akmpaygap" | ///
            (`"`resolved_preset'"' != "simple" & `"`canonical'"' != "cpv") {
            local initial "random"
            local source_initial "preset"
        }
        else {
            local initial "stationary"
            local source_initial "package"
        }
    }
    if !inlist(`"`initial'"', "stationary", "random", "allunemployed") {
        di as error "initial() must be stationary, random, or allunemployed"
        exit 198
    }
    if (`"`canonical'"' == "akmpaygap" | ///
        (`"`resolved_preset'"' != "simple" & `"`canonical'"' != "cpv")) & `"`initial'"' == "stationary" {
        di as error "initial(stationary) is unavailable for `canonical'/`resolved_preset'"
        exit 198
    }
    if inlist(`"`canonical'"', "bm", "cpv") & `"`initial'"' == "random" & ///
        real(`"`value_burnin'"') <= 0 {
        di as error "Continuous-time initial(random) requires positive burnin() in years"
        exit 198
    }
    if !inlist(`"`canonical'"', "bm", "cpv") & ///
        `"`initial'"' == "random" & real(`"`value_burnin'"') < 1 {
        if `"`canonical'"' == "akmpaygap" | ///
            (`"`resolved_preset'"' != "simple" & `"`canonical'"' != "cpv") {
            di as error "initial(random) requires burnin() of at least one year for `canonical'/`resolved_preset'"
        }
        else {
            di as error "initial(random) requires burnin() of at least one output period"
        }
        exit 198
    }
    if `"`jobrule'"' == "" {
        local jobrule "end"
        local source_jobrule "package"
    }
    if `"`jobrule'"' != "end" {
        di as error "only jobrule(end) is registered for the initial release"
        exit 198
    }
    if `"`truth'"' == "" {
        local truth "basic"
        local source_truth "package"
    }
    if !inlist(`"`truth'"', "none", "basic", "full") {
        di as error "truth() must be none, basic, or full"
        exit 198
    }
    if `"`connectivity'"' == "" {
        local connectivity "keep"
        local source_connectivity "package"
    }
    if !inlist(`"`connectivity'"', "keep", "largest", "force") {
        di as error "connectivity() must be keep, largest, or force"
        exit 198
    }

    local reporting "report"
    local source_report "package"
    if `"`report'"' != "" {
        local reporting "report"
        local source_report "option"
    }
    else if `"`noreport'"' != "" {
        local reporting "noreport"
        local source_report "option"
    }

    local model_overrides ""
    foreach name of local model_parameters {
        if `"`source_`name''"' == "parameters" {
            local model_overrides `"`model_overrides' `name'=`value_`name''"'
        }
    }
    local model_overrides = strtrim(`"`model_overrides'"')
    if `"`model_overrides'"' != "" {
        if inlist(`"`resolved_preset'"', ///
            "germany_chk_2002_2009", "cck2016") ///
            local calibration_class "targeted_modified"
        else local calibration_class "stylized_modified"
    }

    local fields `"`scalar_parameters'"'
    local overrides ""
    local parameter_overrides ""
    foreach name of local fields {
        if inlist(`"`source_`name''"', "option", "parameters") {
            local overrides `"`overrides' `name'=`value_`name''"'
        }
        if `"`source_`name''"' == "parameters" {
            local parameter_overrides `"`parameter_overrides' `name'=`value_`name''"'
        }
    }
    foreach name in frequency start seed initial jobrule truth connectivity network {
        if `"`source_`name''"' == "option" {
            local overrides `"`overrides' `name'=``name''"'
        }
    }
    if `"`source_report'"' == "option" local overrides `"`overrides' report=`reporting'"'
    local overrides = strtrim(`"`overrides'"')
    local parameter_overrides = strtrim(`"`parameter_overrides'"')

    local config `"dgp=`canonical' preset=`resolved_preset' workers=`value_workers' firms=`value_firms' periods=`value_periods' frequency=`frequency' start=`start' seed=`seed' initial=`initial' burnin=`value_burnin' jobrule=`jobrule' truth=`truth' connectivity=`connectivity' network=`network' report=`reporting'"'
    local config_sources `"dgp=registry preset=registry workers=`source_workers' firms=`source_firms' periods=`source_periods' frequency=`source_frequency' start=`source_start' seed=`source_seed' initial=`source_initial' burnin=`source_burnin' jobrule=`source_jobrule' truth=`source_truth' connectivity=`source_connectivity' network=`source_network' report=`source_report'"'
    foreach name of local model_parameters {
        local config `"`config' `name'=`value_`name''"'
        local config_sources `"`config_sources' `name'=`source_`name''"'
    }
    foreach name of local network_parameters {
        local config `"`config' `name'=`value_`name''"'
        local config_sources `"`config_sources' `name'=`source_`name''"'
    }

    local n_parameters : word count `scalar_parameters'
    tempname parameter_matrix
    matrix `parameter_matrix' = J(`n_parameters', 4, .)
    local row 1
    foreach name of local scalar_parameters {
        quietly fesim_registry, action(parameter) dgp(`canonical') ///
            preset(`resolved_preset') parameter(`name')
        matrix `parameter_matrix'[`row', 1] = real(`"`value_`name''"')
        matrix `parameter_matrix'[`row', 2] = real(`"`default_`name''"')
        matrix `parameter_matrix'[`row', 3] = real(`"`r(lower)'"')
        matrix `parameter_matrix'[`row', 4] = real(`"`r(upper)'"')
        local ++row
    }
    matrix rownames `parameter_matrix' = `scalar_parameters'
    matrix colnames `parameter_matrix' = value default lower upper

    return local command "config"
    return local dgp `"`canonical'"'
    return local dgp_alias `"`alias'"'
    return local preset `"`resolved_preset'"'
    return local calibration_class `"`calibration_class'"'
    return local config_schema `"`config_schema'"'
    return local frequency `"`frequency'"'
    return local start `"`start'"'
    return local time_format `"`time_format'"'
    return local interval_unit `"`interval_unit'"'
    return local internal_clock `"`internal_clock'"'
    return local seed `"`seed'"'
    return local initial `"`initial'"'
    return local jobrule `"`jobrule'"'
    return local truth `"`truth'"'
    return local connectivity `"`connectivity'"'
    return local network `"`network'"'
    return local report `"`reporting'"'
    return local config `"`config'"'
    return local config_sources `"`config_sources'"'
    return local overrides `"`overrides'"'
    return local parameter_overrides `"`parameter_overrides'"'
    return local model_overrides `"`model_overrides'"'
    return local parameter_names `"`scalar_parameters'"'
    return local parameters_supplied `"`parameter_names'"'
    return scalar workers = real(`"`value_workers'"')
    return scalar firms = real(`"`value_firms'"')
    return scalar periods = real(`"`value_periods'"')
    return scalar burnin = real(`"`value_burnin'"')
    return scalar N_requested = real(`"`value_workers'"') * real(`"`value_periods'"')
    return scalar start_value = `start_value'
    return scalar end_value = `end_value'
    return scalar periods_per_year = `periods_per_year'
    return scalar delta_years = `delta_years'
    return matrix parameters = `parameter_matrix'
end
