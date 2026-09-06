*! fesim common metadata/result finalizer 1.1.0-dev 05sep2026
program define _fesim_finalize, rclass
    version 16.0
    syntax , DGP(string) DGPALIAS(string) PRESET(string) ///
        CALIBRATIONCLASS(string) COMMAND(string) SEED(string) ///
        RNG(string) RNGMETHOD(string) FREQUENCY(string) ///
        INTERNALCLOCK(string) JOBRULE(string) TRUTH(string) ///
        BURNIN(real) CONNECTIVITY(string) NETWORKDESIGN(string) ///
        REFERENCE(string) ///
        WORKERS(integer) FIRMS(integer) PERIODS(integer) ///
        PARAMETERS(name) MOMENTS(name) ///
        [ TARGETS(name) NETWORK(name) LEAVEOUT(name) SOLVER(name) ///
        DURATIONS(name) BRIDGES(name) ///
        GROUPMOMENTS(name) GROUPTARGETS(name) DECOMPOSITION(name) ///
        DECOMPOSITIONTARGETS(name) GROUPCODING(string) ///
        GAPDIRECTION(string) SURPLUSNORMALIZATION(string) ///
        FIRMSACTIVE(real -1) EMPLOYMENTRATE(real -1) ///
        PEU(real -1) PUE(real -1) PEE(real -1) COMPONENTS(real -1) ///
        LARGESTCOMPONENTOBSSHARE(real -1) ///
        LARGESTCOMPONENTWORKERSHARE(real -1) ///
        LARGESTCOMPONENTFIRMSHARE(real -1) ///
        RUNTIMETOTAL(real 0) RUNTIMESOLVE(real 0) ///
        RUNTIMESIMULATE(real 0) RUNTIMEOUTPUT(real 0) ///
        REPORTING(string) ]

    foreach name in dgp dgpalias preset calibrationclass command seed rng ///
        rngmethod frequency internalclock jobrule truth connectivity ///
        networkdesign reference {
        if strtrim(`"``name''"') == "" {
            di as error "`name'() must be nonempty"
            exit 198
        }
    }
    if `workers' < 1 | `firms' < 1 | `periods' < 1 | `burnin' < 0 {
        di as error "workers(), firms(), periods(), and burnin() are invalid"
        exit 198
    }
    if _N != `workers' * `periods' {
        di as error "current data do not match workers() times periods()"
        exit 459
    }
    foreach variable in workerid time firmid employed {
        capture confirm variable `variable'
        if _rc {
            di as error "required fesim output variable is missing: `variable'"
            exit 111
        }
    }
    capture isid workerid time
    if _rc {
        di as error "fesim output is not uniquely identified by workerid time"
        exit 459
    }

    foreach matrix_name in parameters moments {
        capture confirm matrix ``matrix_name''
        if _rc {
            di as error "`matrix_name'() does not name an existing matrix"
            exit 111
        }
        local row_names : rownames ``matrix_name''
        local column_names : colnames ``matrix_name''
        if strtrim(`"`row_names'`column_names'"') == "" {
            di as error "`matrix_name'() must have stable row or column names"
            exit 198
        }
    }
    foreach matrix_name in targets network leaveout solver durations bridges ///
        groupmoments grouptargets decomposition decompositiontargets {
        if `"``matrix_name''"' != "" {
            capture confirm matrix ``matrix_name''
            if _rc {
                di as error "`matrix_name'() does not name an existing matrix"
                exit 111
            }
            local row_names : rownames ``matrix_name''
            local column_names : colnames ``matrix_name''
            if strtrim(`"`row_names'`column_names'"') == "" {
                di as error "`matrix_name'() must have stable row or column names"
                exit 198
            }
        }
    }
    if `"`dgp'"' == "akmpaygap" {
        foreach name in groupmoments grouptargets decomposition ///
            decompositiontargets {
            if `"``name''"' == "" {
                di as error "akmpaygap requires `name'()"
                exit 198
            }
        }
        foreach name in groupcoding gapdirection surplusnormalization {
            if strtrim(`"``name''"') == "" {
                di as error "akmpaygap requires `name'()"
                exit 198
            }
        }
    }
    if (`"`networkdesign'"' == "bridges") != (`"`bridges'"' != "") {
        di as error "network(bridges) requires exactly one bridge ledger"
        exit 198
    }
    if (`"`network'"' != "") != (`"`leaveout'"' != "") {
        di as error "network and leaveout diagnostics must be returned together"
        exit 198
    }
    if `"`leaveout'"' != "" {
        if rowsof(`leaveout') != 19 | colsof(`leaveout') != 1 {
            di as error "leaveout() must be the stable 19-row diagnostic matrix"
            exit 198
        }
    }
    if `"`bridges'"' != "" {
        if rowsof(`bridges') < 1 | colsof(`bridges') != 8 | ///
            rowsof(`bridges') != `bridges'[rowsof(`bridges'), 1] {
            di as error "bridges() is not a complete ordered bridge ledger"
            exit 198
        }
    }

    foreach value in firmsactive employmentrate peu pue pee components ///
        largestcomponentobsshare largestcomponentworkershare ///
        largestcomponentfirmshare {
        if ``value'' == -1 local `value' .
    }

    foreach value in employmentrate peu pue pee ///
        largestcomponentobsshare largestcomponentworkershare ///
        largestcomponentfirmshare {
        if !missing(``value'') & (``value'' < 0 | ``value'' > 1) {
            di as error "`value'() must be missing or lie in [0,1]"
            exit 198
        }
    }
    if !missing(`firmsactive') & ///
        (`firmsactive' < 0 | `firmsactive' > `firms' | ///
        `firmsactive' != floor(`firmsactive')) {
        di as error "firmsactive() is invalid"
        exit 198
    }
    if !missing(`components') & ///
        (`components' < 0 | `components' != floor(`components')) {
        di as error "components() is invalid"
        exit 198
    }
    foreach value in runtimetotal runtimesolve runtimesimulate runtimeoutput {
        if missing(``value'') | ``value'' < 0 {
            di as error "`value'() must be nonnegative"
            exit 198
        }
    }

    local reporting = lower(strtrim(`"`reporting'"'))
    if `"`reporting'"' == "" local reporting "report"
    if !inlist(`"`reporting'"', "report", "noreport") {
        di as error "reporting() must be report or noreport"
        exit 198
    }

    quietly fesim_version_info
    local version `"`r(version)'"'

    char _dta[fesim_version] `"`version'"'
    char _dta[fesim_dgp] `"`dgp'"'
    char _dta[fesim_dgp_alias] `"`dgpalias'"'
    char _dta[fesim_preset] `"`preset'"'
    char _dta[fesim_calibration_class] `"`calibrationclass'"'
    char _dta[fesim_command] `"`command'"'
    char _dta[fesim_seed] `"`seed'"'
    char _dta[fesim_rng] `"`rng'"'
    char _dta[fesim_frequency] `"`frequency'"'
    char _dta[fesim_internal_clock] `"`internalclock'"'
    char _dta[fesim_jobrule] `"`jobrule'"'
    char _dta[fesim_burnin] `"`burnin'"'
    char _dta[fesim_connectivity] `"`connectivity'"'
    char _dta[fesim_network_design] `"`networkdesign'"'
    if `"`bridges'"' != "" {
        char _dta[fesim_bridges_imposed] `"`=rowsof(`bridges')'"'
    }
    char _dta[fesim_reference] `"`reference'"'
    char _dta[fesim_rng_method] `"`rngmethod'"'
    char _dta[fesim_stata_version] `"`c(stata_version)'"'
    char _dta[fesim_truth] `"`truth'"'
    if `"`groupcoding'"' != "" ///
        char _dta[fesim_group_coding] `"`groupcoding'"'
    if `"`gapdirection'"' != "" ///
        char _dta[fesim_gap_direction] `"`gapdirection'"'
    if `"`surplusnormalization'"' != "" ///
        char _dta[fesim_surplus_normalization] `"`surplusnormalization'"'

    tempname parameters_copy moments_copy
    matrix `parameters_copy' = `parameters'
    matrix `moments_copy' = `moments'
    if `"`targets'"' != "" {
        tempname targets_copy
        matrix `targets_copy' = `targets'
    }
    if `"`network'"' != "" {
        tempname network_copy
        matrix `network_copy' = `network'
    }
    if `"`leaveout'"' != "" {
        tempname leaveout_copy
        matrix `leaveout_copy' = `leaveout'
    }
    if `"`solver'"' != "" {
        tempname solver_copy
        matrix `solver_copy' = `solver'
    }
    if `"`durations'"' != "" {
        tempname durations_copy
        matrix `durations_copy' = `durations'
    }
    if `"`bridges'"' != "" {
        tempname bridges_copy
        matrix `bridges_copy' = `bridges'
    }
    foreach matrix_name in groupmoments grouptargets decomposition ///
        decompositiontargets {
        if `"``matrix_name''"' != "" {
            tempname `matrix_name'_copy
            matrix ``matrix_name'_copy' = ``matrix_name''
        }
    }

    return scalar N = _N
    return scalar N_workers = `workers'
    return scalar N_firms = `firms'
    return scalar N_firms_active = `firmsactive'
    return scalar periods = `periods'
    return scalar employment_rate = `employmentrate'
    return scalar p_eu_realized = `peu'
    return scalar p_ue_realized = `pue'
    return scalar p_ee_realized = `pee'
    if `"`bridges'"' == "" return scalar bridges_imposed = 0
    else return scalar bridges_imposed = rowsof(`bridges')
    return scalar components = `components'
    return scalar largest_component_obs_share = `largestcomponentobsshare'
    return scalar largest_component_worker_share = `largestcomponentworkershare'
    return scalar largest_component_firm_share = `largestcomponentfirmshare'
    return scalar runtime_total = `runtimetotal'
    return scalar runtime_solve = `runtimesolve'
    return scalar runtime_simulate = `runtimesimulate'
    return scalar runtime_output = `runtimeoutput'
    return local dgp `"`dgp'"'
    return local dgp_alias `"`dgpalias'"'
    return local preset `"`preset'"'
    return local calibration_class `"`calibrationclass'"'
    return local frequency `"`frequency'"'
    return local internal_clock `"`internalclock'"'
    return local jobrule `"`jobrule'"'
    return local network_design `"`networkdesign'"'
    return local seed `"`seed'"'
    return local rng `"`rng'"'
    return local command `"`command'"'
    return local version `"`version'"'
    return local reference `"`reference'"'
    if `"`groupcoding'"' != "" ///
        return local group_coding `"`groupcoding'"'
    if `"`gapdirection'"' != "" ///
        return local gap_direction `"`gapdirection'"'
    if `"`surplusnormalization'"' != "" ///
        return local surplus_normalization `"`surplusnormalization'"'
    return matrix parameters = `parameters_copy'
    return matrix moments = `moments_copy'
    if `"`targets'"' != "" return matrix targets = `targets_copy'
    if `"`network'"' != "" return matrix network = `network_copy'
    if `"`leaveout'"' != "" return matrix leaveout = `leaveout_copy'
    if `"`solver'"' != "" return matrix solver = `solver_copy'
    if `"`durations'"' != "" return matrix durations = `durations_copy'
    if `"`bridges'"' != "" return matrix bridges = `bridges_copy'
    if `"`groupmoments'"' != "" ///
        return matrix group_moments = `groupmoments_copy'
    if `"`grouptargets'"' != "" ///
        return matrix group_targets = `grouptargets_copy'
    if `"`decomposition'"' != "" ///
        return matrix decomposition = `decomposition_copy'
    if `"`decompositiontargets'"' != "" ///
        return matrix decomposition_targets = `decompositiontargets_copy'

    if `"`reporting'"' == "report" {
        di as txt _newline "fesim simulation summary"
        di as txt "  Design: " as result `"`dgp'/`preset'"' ///
            as txt " (" `"`calibrationclass'"' ")"
        di as txt "  Sample: " as result %12.0fc _N ///
            as txt " observations; " as result %10.0fc `workers' ///
            as txt " workers; " as result %10.0fc `firms' as txt " firms"
        di as txt "  Timing: " as result `"`periods' `frequency' periods"' ///
            as txt "; internal clock " as result `"`internalclock'"'
        if !missing(`employmentrate') {
            di as txt "  Employment rate: " as result %9.4f `employmentrate'
        }
        if missing(`components') {
            di as txt "  Network diagnostics: " as result "not computed"
        }
        else {
            di as txt "  Network components: " as result %9.0f `components'
        }
        di as txt "  Detailed parameters and moments are available in r()."
    }
end
