*! fesim configuration registry 0.0.0-dev 28aug2026
program define fesim_registry, rclass
    version 16.0
    syntax , ACTION(string) [ DGP(string) PRESet(string) PARAmeter(string) ]

    local action = lower(strtrim(`"`action'"'))

    if `"`action'"' == "list" {
        if strtrim(`"`dgp'`preset'`parameter'"') != "" {
            di as error "dgp(), preset(), and parameter() are not allowed with registry action list"
            exit 198
        }
        return local dgps "akm akmpaygap bm"
        return local aliases "akmsimple akmempirical bmsimple"
        return local qualified "akm/simple"
        return local status "partial"
        return scalar n_dgps = 3
        exit
    }

    if !inlist(`"`action'"', "resolve", "parameters", "parameter") {
        di as error "unknown fesim registry action: `action'"
        exit 198
    }

    quietly fesim_registry__resolve, dgp(`dgp') preset(`preset')
    if `"`action'"' == "resolve" {
        return add
        exit
    }

    local canonical `"`r(dgp)'"'
    local resolved_preset `"`r(preset)'"'
    if `"`canonical'/`resolved_preset'"' != "akm/simple" {
        if `"`action'"' == "parameters" {
            return local common_options ""
            return local scalar_parameters ""
            return local model_parameters ""
            return local config_schema ""
            return local dgp `"`canonical'"'
            return local preset `"`resolved_preset'"'
            exit
        }
        di as error "parameter metadata is not yet registered for dgp(`canonical') preset(`resolved_preset')"
        exit 498
    }

    if `"`action'"' == "parameters" {
        return local common_options "workers firms periods frequency start seed initial burnin jobrule truth connectivity report"
        return local scalar_parameters "workers firms periods burnin mu sd_worker sd_firm sd_error firm_size_sd p_eu p_ee p_ue wage_trend"
        return local model_parameters "mu sd_worker sd_firm sd_error firm_size_sd p_eu p_ee p_ue wage_trend"
        return local config_schema "akm_simple_v1"
        return local dgp "akm"
        return local preset "simple"
        exit
    }

    local name = lower(strtrim(`"`parameter'"'))
    if `"`name'"' == "" {
        di as error "parameter() is required with registry action parameter"
        exit 198
    }

    local all "workers firms periods frequency start seed initial burnin jobrule truth connectivity report mu sd_worker sd_firm sd_error firm_size_sd p_eu p_ee p_ue wage_trend"
    if !`: list name in all' {
        di as error "unknown fesim parameter: `name'"
        exit 198
    }

    local type "real"
    local unit "level"
    local default ""
    local lower "."
    local upper "."
    local lower_closed "no"
    local upper_closed "no"
    local scope "model"
    local default_source "preset"
    local named_option "no"
    local parameters_allowed "yes"
    local description ""
    local applicability "akm/simple"

    if inlist(`"`name'"', "workers", "firms", "periods", "burnin") {
        local type "integer"
        local unit "count"
        local lower "0"
        local upper "2147483647"
        local lower_closed "yes"
        local upper_closed "yes"
        local scope "common"
        local named_option "yes"
        if `"`name'"' != "burnin" local lower "1"
        if `"`name'"' == "workers" {
            local default "10000"
            local description "Number of workers"
        }
        else if `"`name'"' == "firms" {
            local default "500"
            local description "Number of firms"
        }
        else if `"`name'"' == "periods" {
            local default "10"
            local description "Number of retained periods"
        }
        else {
            local default "0"
            local default_source "package"
            local description "Pre-sample periods discarded after initialization"
        }
    }
    else if inlist(`"`name'"', "frequency", "start", "initial", "jobrule", "truth", "connectivity", "report") {
        local type "string"
        local unit "category"
        local scope "common"
        local default_source "package"
        local named_option "yes"
        local parameters_allowed "no"
        if `"`name'"' == "frequency" {
            local default "year"
            local description "Panel time frequency"
        }
        else if `"`name'"' == "start" {
            local default "frequency-specific"
            local description "First retained period"
        }
        else if `"`name'"' == "initial" {
            local default "stationary"
            local description "Initial worker-state rule"
        }
        else if `"`name'"' == "jobrule" {
            local default "end"
            local description "Within-period employer assignment rule"
        }
        else if `"`name'"' == "truth" {
            local default "basic"
            local description "Truth-data output level"
        }
        else if `"`name'"' == "connectivity" {
            local default "keep"
            local description "Connected-set handling rule"
        }
        else {
            local default "report"
            local description "Configuration-reporting mode"
        }
    }
    else if `"`name'"' == "seed" {
        local type "integer-or-current"
        local unit "RNG seed"
        local default "current"
        local lower "0"
        local upper "2147483647"
        local lower_closed "yes"
        local upper_closed "yes"
        local scope "common"
        local default_source "package"
        local named_option "yes"
        local parameters_allowed "no"
        local description "Requested simulation seed; current leaves RNG selection to execution"
    }
    else {
        local named_option "no"
        if `"`name'"' == "mu" {
            local default "3"
            local description "Mean log wage"
        }
        else if `"`name'"' == "sd_worker" {
            local default ".4"
            local lower "0"
            local lower_closed "yes"
            local unit "standard deviation"
            local description "Worker-effect standard deviation"
        }
        else if `"`name'"' == "sd_firm" {
            local default ".15"
            local lower "0"
            local lower_closed "yes"
            local unit "standard deviation"
            local description "Firm-effect standard deviation"
        }
        else if `"`name'"' == "sd_error" {
            local default ".2"
            local lower "0"
            local lower_closed "yes"
            local unit "standard deviation"
            local description "Idiosyncratic-error standard deviation"
        }
        else if `"`name'"' == "firm_size_sd" {
            local default "1"
            local lower "0"
            local lower_closed "yes"
            local unit "standard deviation"
            local description "Firm-size log-weight standard deviation"
        }
        else if inlist(`"`name'"', "p_eu", "p_ee") {
            if `"`name'"' == "p_eu" local default ".08"
            else local default ".12"
            local lower "0"
            local upper "1"
            local lower_closed "yes"
            local upper_closed "no"
            local unit "probability"
            local description "Annual employment transition probability"
        }
        else if `"`name'"' == "p_ue" {
            local default ".6"
            local lower "0"
            local upper "1"
            local lower_closed "yes"
            local upper_closed "yes"
            local unit "probability"
            local description "Annual job-finding probability"
        }
        else if `"`name'"' == "wage_trend" {
            local default "0"
            local description "Linear log-wage time trend"
        }
    }

    return local parameter `"`name'"'
    return local type `"`type'"'
    return local unit `"`unit'"'
    return local default `"`default'"'
    return local lower `"`lower'"'
    return local upper `"`upper'"'
    return local lower_closed `"`lower_closed'"'
    return local upper_closed `"`upper_closed'"'
    return local scope `"`scope'"'
    return local default_source `"`default_source'"'
    return local named_option `"`named_option'"'
    return local parameters_allowed `"`parameters_allowed'"'
    return local description `"`description'"'
    return local applicability `"`applicability'"'
    if `"`type'"' != "string" & `"`default'"' != "current" {
        return scalar default_value = real(`"`default'"')
    }
    return scalar lower_value = real(`"`lower'"')
    return scalar upper_value = real(`"`upper'"')
end

program define fesim_registry__resolve, rclass
    version 16.0
    syntax , DGP(string) [ PRESet(string) ]

    local requested = lower(strtrim(`"`dgp'"'))
    local requested_preset = lower(strtrim(`"`preset'"'))
    if `"`requested'"' == "" {
        di as error "a DGP name is required"
        exit 198
    }

    local canonical ""
    local alias_preset ""
    if `"`requested'"' == "akm" local canonical "akm"
    else if `"`requested'"' == "akmsimple" {
        local canonical "akm"
        local alias_preset "simple"
    }
    else if `"`requested'"' == "akmempirical" {
        local canonical "akm"
        local alias_preset "empirical"
    }
    else if `"`requested'"' == "akmpaygap" local canonical "akmpaygap"
    else if `"`requested'"' == "bm" local canonical "bm"
    else if `"`requested'"' == "bmsimple" {
        local canonical "bm"
        local alias_preset "simple"
    }
    else {
        di as error "unknown fesim DGP: `requested'"
        di as error "run {cmd:fesim list} to see registered names"
        exit 198
    }

    if `"`alias_preset'"' != "" & `"`requested_preset'"' != "" & ///
        `"`requested_preset'"' != `"`alias_preset'"' {
        di as error "DGP alias `requested' fixes preset(`alias_preset')"
        exit 198
    }

    local resolved_preset `"`requested_preset'"'
    if `"`resolved_preset'"' == "" local resolved_preset `"`alias_preset'"'
    if `"`resolved_preset'"' == "" local resolved_preset "simple"

    local presets ""
    local aliases ""
    local title ""
    local calibration_class ""
    local config_schema ""
    local configurable "no"
    if `"`canonical'"' == "akm" {
        local presets "simple empirical"
        local aliases "akmsimple akmempirical"
        if !inlist(`"`resolved_preset'"', "simple", "empirical") {
            di as error "unknown preset for dgp(akm): `resolved_preset'"
            di as error "registered presets are simple and empirical"
            exit 198
        }
        if `"`resolved_preset'"' == "simple" {
            local title "Simple additive AKM with exogenous random mobility"
            local calibration_class "stylized"
            local config_schema "akm_simple_v1"
            local configurable "yes"
        }
        else {
            local title "Reduced-form AKM with empirical mobility"
            local calibration_class "stylized or targeted; not yet selected"
        }
    }
    else if `"`canonical'"' == "akmpaygap" {
        local presets "simple cck2016"
        if !inlist(`"`resolved_preset'"', "simple", "cck2016") {
            di as error "unknown preset for dgp(akmpaygap): `resolved_preset'"
            di as error "registered presets are simple and cck2016"
            exit 198
        }
        local title "Two-group AKM pay-gap design"
        if `"`resolved_preset'"' == "simple" local calibration_class "stylized"
        else local calibration_class "targeted; planned and unaudited"
    }
    else {
        local presets "simple"
        local aliases "bmsimple"
        if `"`resolved_preset'"' != "simple" {
            di as error "unknown preset for dgp(bm): `resolved_preset'"
            di as error "the registered preset is simple"
            exit 198
        }
        local title "Canonical Burdett-Mortensen wage-posting model"
        local calibration_class "exact model with stylized calibration; planned"
    }

    return local dgp `"`canonical'"'
    return local dgp_alias `"`requested'"'
    return local preset `"`resolved_preset'"'
    return local presets `"`presets'"'
    return local aliases `"`aliases'"'
    return local title `"`title'"'
    return local calibration_class `"`calibration_class'"'
    if `"`canonical'/`resolved_preset'"' == "akm/simple" {
        return local status "qualified"
        return local implemented "yes"
    }
    else {
        return local status "planned"
        return local implemented "no"
    }
    return local configurable `"`configurable'"'
    return local config_schema `"`config_schema'"'
    return local frequencies "year quarter month"
    return local jobrules "end"
end
