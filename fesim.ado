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
    di as error "available discovery commands are version, list, and describe"
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
    di as txt "fesim " as result `"`version'"' ///
        as txt " (" `"`status'"' ")"
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
    di as txt _newline "No DGP is simulation-qualified in version 0.0.0-dev."

    return local command "list"
    return local dgps `"`dgps'"'
    return local aliases `"`all_aliases'"'
    return local qualified `"`qualified'"'
    return local status `"`status'"'
    return scalar n_dgps = `n_dgps'
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
    local frequencies `"`r(frequencies)'"'
    local jobrules `"`r(jobrules)'"'
    return add
    return local command "describe"

    di as txt _newline `"`title'"'
    di as txt "  requested name:      " as result `"`alias'"'
    di as txt "  canonical DGP:       " as result `"`dgp'"'
    di as txt "  preset:              " as result `"`resolved_preset'"'
    di as txt "  calibration class:   " as result `"`calibration'"'
    di as txt "  implementation:      " as result `"`status'"'
    di as txt "  output frequencies:  " as result `"`frequencies'"'
    di as txt "  employer rule:       " as result `"`jobrules'"'
    di as txt _newline "Simulation is not available in this development checkpoint."
end

program define fesim__simulate, rclass
    version 16.0
    syntax [ , DGP(string) PRESet(string) WORKers(integer 10000) ///
        FIRMs(integer 500) PERIODs(integer 10) FREQuency(string) ///
        START(string) SEED(string) INITIAL(string) BURNIN(integer 0) ///
        JOBRULE(string) TRUTH(string) CONNECTivity(string) ///
        PARAMETERS(string asis) REPORT NOREPORT CLEAR ]

    if `"`report'"' != "" & `"`noreport'"' != "" {
        di as error "report and noreport may not be specified together"
        exit 198
    }
    if `workers' < 1 {
        di as error "workers() must be a positive integer"
        exit 198
    }
    if `firms' < 1 {
        di as error "firms() must be a positive integer"
        exit 198
    }
    if `periods' < 1 {
        di as error "periods() must be a positive integer"
        exit 198
    }
    if `burnin' < 0 {
        di as error "burnin() must be a nonnegative integer"
        exit 198
    }

    local dgp = lower(strtrim(`"`dgp'"'))
    if `"`dgp'"' == "" local dgp "akm"
    local preset = lower(strtrim(`"`preset'"'))
    local registry_options `"action(resolve) dgp(`dgp')"'
    if `"`preset'"' != "" {
        local registry_options `"`registry_options' preset(`preset')"'
    }
    quietly fesim_registry, `registry_options'

    local frequency = lower(strtrim(`"`frequency'"'))
    if `"`frequency'"' == "" local frequency "year"
    if !inlist(`"`frequency'"', "year", "quarter", "month") {
        di as error "frequency() must be year, quarter, or month"
        exit 198
    }

    local initial = lower(strtrim(`"`initial'"'))
    if `"`initial'"' == "" local initial "stationary"
    if !inlist(`"`initial'"', "stationary", "random", "allunemployed") {
        di as error "initial() must be stationary, random, or allunemployed"
        exit 198
    }

    local jobrule = lower(strtrim(`"`jobrule'"'))
    if `"`jobrule'"' == "" local jobrule "end"
    if `"`jobrule'"' != "end" {
        di as error "only jobrule(end) is registered for the initial release"
        exit 198
    }

    local truth = lower(strtrim(`"`truth'"'))
    if `"`truth'"' == "" local truth "basic"
    if !inlist(`"`truth'"', "none", "basic", "full") {
        di as error "truth() must be none, basic, or full"
        exit 198
    }

    local connectivity = lower(strtrim(`"`connectivity'"'))
    if `"`connectivity'"' == "" local connectivity "keep"
    if !inlist(`"`connectivity'"', "keep", "largest", "force") {
        di as error "connectivity() must be keep, largest, or force"
        exit 198
    }

    local start = strtrim(`"`start'"')
    if `"`start'"' == "" {
        if `"`frequency'"' == "year" local start "2000"
        else if `"`frequency'"' == "quarter" local start "2000q1"
        else local start "2000m1"
    }
    if `"`frequency'"' == "year" & !regexm(`"`start'"', "^[0-9]+$") {
        di as error "start() must have form YYYY with frequency(year)"
        exit 198
    }
    if `"`frequency'"' == "quarter" & ///
        !regexm(lower(`"`start'"'), "^[0-9]+q[1-4]$") {
        di as error "start() must have form YYYYqQ with frequency(quarter)"
        exit 198
    }
    if `"`frequency'"' == "month" & ///
        !regexm(lower(`"`start'"'), "^[0-9]+m([1-9]|1[0-2])$") {
        di as error "start() must have form YYYYmM with frequency(month)"
        exit 198
    }
    if `"`frequency'"' == "year" local start_value = yearly(`"`start'"', "Y")
    else if `"`frequency'"' == "quarter" local start_value = quarterly(`"`start'"', "YQ")
    else local start_value = monthly(`"`start'"', "YM")
    if missing(`start_value') {
        di as error "start() is invalid for frequency(`frequency')"
        exit 198
    }

    if strtrim(`"`seed'"') != "" {
        capture confirm integer number `seed'
        local seed_rc = _rc
        if `seed_rc' {
            di as error "seed() must be an integer from 0 through 2147483647"
            exit 198
        }
        if `seed' < 0 | `seed' > 2147483647 {
            di as error "seed() must be an integer from 0 through 2147483647"
            exit 198
        }
    }

    if `"`clear'"' == "" & (_N > 0 | c(k) > 0) {
        di as error "data are in memory; specify clear to permit replacement"
        exit 4
    }

    quietly fesim_version_info
    di as error "fesim simulation is not implemented in version `r(version)'"
    di as error "Checkpoint 1 provides version, list, and describe only; data and RNG state were not changed."
    exit 498
end
