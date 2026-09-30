*! fesim common configuration resolver 1.2.0-rc.1 06sep2026
program define fesim__blm_config, rclass
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
    local matrix_parameters `"`r(matrix_parameters)'"'
    local matrix_results `"`r(matrix_results)'"'

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
        if !`: list name in scalar_parameters' & !`: list name in matrix_parameters' {
            di as error "unknown BLM parameter in parameters(): `name'"
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

    local network = lower(strtrim(`"`network'"'))
    local source_network "option"
    if "`network'"=="" {
        local network "random"
        local source_network "package"
    }
    if "`network'"!="random" {
        di as error "BLM requires network(random)"
        exit 198
    }
    foreach name of local scalar_parameters {
        local value `"`value_`name''"'
        capture confirm number `value'
        if _rc | missing(real(`"`value'"')) {
            di as error "`name' must be a finite numeric scalar"
            exit 198
        }
        quietly fesim_registry, action(parameter) dgp(blm) preset(`resolved_preset') parameter(`name')
        if "`r(type)'"=="integer" & real("`value'")!=floor(real("`value'")) {
            di as error "`name' must be an integer"
            exit 198
        }
        if (real("`r(lower)'")<. & real("`value'")<real("`r(lower)'")) | ///
            (real("`r(upper)'")<. & (real("`value'")>real("`r(upper)'") | ///
            ("`r(upper_closed)'"=="no" & real("`value'")==real("`r(upper)'")))) {
            di as error "`name' is outside its registered bounds"
            exit 198
        }
        local formatted : display %24.17g real("`value'")
        local value_`name' = strtrim("`formatted'")
    }
    if real("`value_firms'")<real("`value_firm_types'") {
        di as error "BLM firms() must be at least firm_types"
        exit 198
    }
    if real("`value_workers'")*real("`value_periods'")>2147483647 {
        di as error "BLM requested observation count exceeds supported range"
        exit 198
    }
    if abs(12*real("`value_burnin'")-round(12*real("`value_burnin'")))>1e-8 {
        di as error "BLM burnin() must be aligned to whole months"
        exit 198
    }
    local matrix_inputs ""
    foreach name of local matrix_parameters {
        if "`source_`name''"=="parameters" {
            capture confirm name `value_`name''
            if _rc {
                di as error "BLM `name' requires a Stata matrix name"
                exit 198
            }
            capture confirm matrix `value_`name''
            if _rc {
                di as error "BLM matrix does not exist: `value_`name''"
                exit 198
            }
            local recipes ""
            if "`name'"=="mean_matrix" local recipes "mu sd_worker sd_firm interaction"
            if "`name'"=="sd_matrix" local recipes "sd_error"
            if "`name'"=="move_rate_matrix" local recipes "lambda_move"
            if "`name'"=="rho_matrix" local recipes "rho"
            if "`name'"=="mobility_wage_matrix" local recipes "mobility_wage"
            if "`name'"=="destination_matrix" local recipes "sorting"
            if "`name'"=="move_shift_matrix" local recipes "origin_dependence"
            foreach recipe of local recipes {
                if "`source_`recipe''"=="parameters" {
                    di as error "BLM `name' conflicts with explicit scalar recipe `recipe'"
                    exit 198
                }
            }
            local matrix_inputs "`matrix_inputs' `value_`name''"
        }
        else local matrix_inputs "`matrix_inputs' -"
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

    if "`initial'"=="" {
        local initial "random"
        local source_initial "preset"
    }
    if "`initial'"!="random" {
        di as error "BLM supports initial(random) only; burn-in is not an exact stationary initialization"
        exit 198
    }
    if real("`value_workers'")*(round(12*real("`value_burnin'"))+ ///
        real("`value_periods'")*12*`delta_years')>1000000000 {
        di as error "BLM internal simulation exceeds one billion worker-months"
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


    quietly fesim__load
    tempname primitives
    matrix `primitives' = J(1,12,.)
    local col 0
    foreach name of local model_parameters {
        local ++col
        matrix `primitives'[1,`col'] = real("`value_`name''")
    }
    local matrix_outputs ""
    foreach result of local matrix_results {
        tempname tmp_`result'
        local matrix_outputs "`matrix_outputs' `tmp_`result''"
    }
    quietly mata: fesim_blm_resolve_to_stata(strtoreal(st_local("value_firms")), ///
        st_matrix("`primitives'"),tokens(st_local("matrix_inputs")), ///
        "`resolved_preset'",tokens(st_local("matrix_outputs")))
    local model_overrides ""
    foreach name of local model_parameters {
        if `"`source_`name''"' == "parameters" {
            local model_overrides `"`model_overrides' `name'=`value_`name''"'
        }
    }

    foreach name of local matrix_parameters {
        if "`source_`name''"=="parameters" {
            local model_overrides "`model_overrides' `name'=resolved_table"
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


    local config "`config' blm_tables_v1=`blm_fingerprint'"
    local config_sources "`config_sources' blm_tables=resolved_values"
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

    return local matrix_parameters "`matrix_parameters'"
    return local matrix_results "`matrix_results'"
    return local blm_model `"`blm_model'"'
    return local blm_fingerprint "`blm_fingerprint'"
    foreach result of local matrix_results {
        return matrix `result' = `tmp_`result''
    }
    return matrix parameters = `parameter_matrix'
end
