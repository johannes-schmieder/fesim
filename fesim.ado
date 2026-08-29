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
    di as txt _newline "Configuration is available for akm/simple; simulation is not yet implemented."

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
    di as txt "Simulation is not available in this development checkpoint."

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
    local resolved_config `"`r(config)'"'
    if `"`clear'"' == "" & (_N > 0 | c(k) > 0) {
        di as error "data are in memory; specify clear to permit replacement"
        exit 4
    }

    quietly fesim_version_info
    di as error "fesim simulation is not implemented in version `r(version)'"
    di as error "The current development checkpoint resolves configuration but does not simulate; data and RNG state were not changed."
    di as txt "resolved configuration: `resolved_config'"
    exit 498
end
