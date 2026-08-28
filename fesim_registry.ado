*! fesim minimal discovery registry 0.0.0-dev 28aug2026
program define fesim_registry, rclass
    version 16.0
    syntax , ACTION(string) [ DGP(string) PRESet(string) ]

    local action = lower(strtrim(`"`action'"'))

    if `"`action'"' == "list" {
        if `"`dgp'`preset'"' != "" {
            di as error "dgp() and preset() are not allowed with registry action list"
            exit 198
        }
        return local dgps "akm akmpaygap bm"
        return local aliases "akmsimple akmempirical bmsimple"
        return local qualified ""
        return local status "planned"
        return scalar n_dgps = 3
        exit
    }

    if `"`action'"' != "resolve" {
        di as error "unknown fesim registry action: `action'"
        exit 198
    }

    local requested = lower(strtrim(`"`dgp'"'))
    local requested_preset = lower(strtrim(`"`preset'"'))
    if `"`requested'"' == "" {
        di as error "a DGP name is required"
        exit 198
    }

    local canonical ""
    local alias_preset ""
    if `"`requested'"' == "akm" {
        local canonical "akm"
    }
    else if `"`requested'"' == "akmsimple" {
        local canonical "akm"
        local alias_preset "simple"
    }
    else if `"`requested'"' == "akmempirical" {
        local canonical "akm"
        local alias_preset "empirical"
    }
    else if `"`requested'"' == "akmpaygap" {
        local canonical "akmpaygap"
    }
    else if `"`requested'"' == "bm" {
        local canonical "bm"
    }
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
        }
        else {
            local title "Reduced-form AKM with empirical mobility"
            local calibration_class "stylized or targeted; not yet selected"
        }
    }
    else if `"`canonical'"' == "akmpaygap" {
        local presets "simple cck2016"
        local aliases ""
        if !inlist(`"`resolved_preset'"', "simple", "cck2016") {
            di as error "unknown preset for dgp(akmpaygap): `resolved_preset'"
            di as error "registered presets are simple and cck2016"
            exit 198
        }
        local title "Two-group AKM pay-gap design"
        if `"`resolved_preset'"' == "simple" local calibration_class "stylized"
        else local calibration_class "targeted; planned and unaudited"
    }
    else if `"`canonical'"' == "bm" {
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
    return local status "planned"
    return local implemented "no"
    return local frequencies "year quarter month"
    return local jobrules "end"
end
