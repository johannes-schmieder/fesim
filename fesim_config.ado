*! fesim common configuration resolver 0.0.0-dev 28aug2026
program define fesim_config, rclass
    version 16.0
    syntax [ , DGP(string) PRESet(string) WORKers(string) FIRMs(string) ///
        PERIODs(string) FREQuency(string) START(string) SEED(string) ///
        INITIAL(string) BURNIN(string) JOBRULE(string) TRUTH(string) ///
        CONNECTivity(string) PARAMETERS(string asis) noREPORT ]

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

    if real(`"`value_p_eu'"') + real(`"`value_p_ee'"') >= 1 {
        di as error "p_eu + p_ee must be strictly less than 1"
        exit 198
    }
    if real(`"`value_firms'"') < 2 & real(`"`value_p_ee'"') > 0 {
        di as error "firms() must be at least 2 when p_ee is positive"
        exit 198
    }
    if real(`"`value_workers'"') * real(`"`value_periods'"') > 2147483647 {
        di as error "workers() times periods() exceeds the supported observation count"
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
    if `"`start'"' == "" local source_start "package"
    local time_options `"frequency(`frequency') periods(`value_periods')"'
    if `"`start'"' != "" local time_options `"`time_options' start(`start')"'
    quietly fesim_time, `time_options'
    local frequency `"`r(frequency)'"'
    local start `"`r(start)'"'
    local time_format `"`r(format)'"'
    local interval_unit `"`r(interval_unit)'"'
    local internal_clock `"`r(internal_clock)'"'
    local start_value = r(start_value)
    local end_value = r(end_value)
    local periods_per_year = r(periods_per_year)
    local delta_years = r(delta_years)

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
        local initial "stationary"
        local source_initial "package"
    }
    if !inlist(`"`initial'"', "stationary", "random", "allunemployed") {
        di as error "initial() must be stationary, random, or allunemployed"
        exit 198
    }
    if `"`initial'"' == "random" & real(`"`value_burnin'"') < 1 {
        di as error "initial(random) requires burnin() of at least one output period"
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
    if `"`model_overrides'"' != "" local calibration_class "stylized_modified"

    local fields "workers firms periods burnin mu sd_worker sd_firm sd_error firm_size_sd p_eu p_ee p_ue wage_trend"
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
    foreach name in frequency start seed initial jobrule truth connectivity {
        if `"`source_`name''"' == "option" {
            local overrides `"`overrides' `name'=``name''"'
        }
    }
    if `"`source_report'"' == "option" local overrides `"`overrides' report=`reporting'"'
    local overrides = strtrim(`"`overrides'"')
    local parameter_overrides = strtrim(`"`parameter_overrides'"')

    local config `"dgp=`canonical' preset=`resolved_preset' workers=`value_workers' firms=`value_firms' periods=`value_periods' frequency=`frequency' start=`start' seed=`seed' initial=`initial' burnin=`value_burnin' jobrule=`jobrule' truth=`truth' connectivity=`connectivity' report=`reporting' mu=`value_mu' sd_worker=`value_sd_worker' sd_firm=`value_sd_firm' sd_error=`value_sd_error' firm_size_sd=`value_firm_size_sd' p_eu=`value_p_eu' p_ee=`value_p_ee' p_ue=`value_p_ue' wage_trend=`value_wage_trend'"'

    local config_sources `"dgp=registry preset=registry workers=`source_workers' firms=`source_firms' periods=`source_periods' frequency=`source_frequency' start=`source_start' seed=`source_seed' initial=`source_initial' burnin=`source_burnin' jobrule=`source_jobrule' truth=`source_truth' connectivity=`source_connectivity' report=`source_report' mu=`source_mu' sd_worker=`source_sd_worker' sd_firm=`source_sd_firm' sd_error=`source_sd_error' firm_size_sd=`source_firm_size_sd' p_eu=`source_p_eu' p_ee=`source_p_ee' p_ue=`source_p_ue' wage_trend=`source_wage_trend'"'

    local n_parameters : word count `scalar_parameters'
    tempname parameter_matrix
    matrix `parameter_matrix' = J(`n_parameters', 4, .)
    local row 1
    foreach name of local scalar_parameters {
        quietly fesim_registry, action(parameter) dgp(`canonical') ///
            preset(`resolved_preset') parameter(`name')
        matrix `parameter_matrix'[`row', 1] = real(`"`value_`name''"')
        matrix `parameter_matrix'[`row', 2] = real(`"`r(default)'"')
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
