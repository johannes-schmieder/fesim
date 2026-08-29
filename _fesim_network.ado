*! fesim observed bipartite network diagnostics 0.0.0-dev 29aug2026
program define _fesim_network, rclass
    version 16.0
    syntax , WORKERS(integer) FIRMS(integer) PERIODS(integer) ///
        CONNECTIVITY(string)

    local connectivity = lower(strtrim(`"`connectivity'"'))
    if !inlist(`"`connectivity'"', "keep", "largest") {
        di as error "connectivity() must be keep or largest"
        exit 198
    }
    if `workers' < 1 | `firms' < 1 | `periods' < 1 | ///
        _N != `workers' * `periods' {
        di as error "network dimensions do not match the current panel"
        exit 459
    }
    foreach variable in workerid time firmid employed {
        capture confirm variable `variable'
        if _rc {
            di as error "required fesim network variable is missing: `variable'"
            exit 111
        }
    }
    capture isid workerid time
    if _rc {
        di as error "fesim network diagnostics require a unique workerid time key"
        exit 459
    }
    capture assert workerid >= 1 & workerid <= `workers' & ///
        workerid == floor(workerid)
    if _rc {
        di as error "workerid does not match workers()"
        exit 459
    }
    capture assert inlist(employed, 0, 1)
    if _rc {
        di as error "employed must contain only zero and one"
        exit 459
    }
    capture assert inrange(firmid, 1, `firms') & ///
        firmid == floor(firmid) if employed
    if _rc {
        di as error "employed firm identifiers do not match firms()"
        exit 459
    }
    capture assert missing(firmid) == !employed
    if _rc {
        di as error "firmid missingness must match employment"
        exit 459
    }

    tempname generated worker_components firm_components returned network
    quietly count if employed
    local employed_observations = r(N)
    if `employed_observations' == 0 {
        if `"`connectivity'"' == "largest" {
            di as error "connectivity(largest) is undefined without observed employment"
            exit 459
        }
        matrix `generated' = J(13, 1, .)
        forvalues row = 1/5 {
            matrix `generated'[`row', 1] = 0
        }
        forvalues row = 7/10 {
            matrix `generated'[`row', 1] = 0
        }
        matrix `worker_components' = J(`workers', 1, .)
        matrix `firm_components' = J(`firms', 1, .)
    }
    else {
        preserve
        quietly keep if employed
        quietly contract workerid firmid, freq(observations)
        quietly sort workerid firmid
        capture noisily mata: fesim_network_store_from_stata( ///
            `workers', `firms', "`generated'", ///
            "`worker_components'", "`firm_components'")
        local graph_rc = _rc
        restore
        if `graph_rc' exit `graph_rc'
    }

    local diagnostic_names ///
        "components edges employed_observations workers firms largest_component_id largest_edges largest_observations largest_workers largest_firms largest_observation_share largest_worker_share largest_firm_share"
    matrix rownames `generated' = `diagnostic_names'
    matrix colnames `generated' = generated
    matrix `returned' = `generated'
    matrix colnames `returned' = returned

    local sample_workers = `workers'
    if `"`connectivity'"' == "largest" {
        local largest_component = el(`generated', 6, 1)
        local sample_workers = el(`generated', 9, 1)
        tempvar in_largest
        quietly generate byte `in_largest' = 0
        capture noisily mata: fesim_network_mark_largest( ///
            "`worker_components'", `largest_component', "`in_largest'")
        local mark_rc = _rc
        if `mark_rc' {
            quietly drop `in_largest'
            exit `mark_rc'
        }
        quietly keep if `in_largest'
        quietly drop `in_largest'
        quietly sort workerid time

        matrix `returned'[1, 1] = 1
        forvalues row = 2/5 {
            local source_row = `row' + 5
            matrix `returned'[`row', 1] = `generated'[`source_row', 1]
        }
        forvalues row = 11/13 {
            matrix `returned'[`row', 1] = 1
        }
    }
    matrix `network' = (`generated', `returned')
    matrix rownames `network' = `diagnostic_names'
    matrix colnames `network' = generated returned

    return scalar N_workers_sample = `sample_workers'
    return scalar components = el(`returned', 1, 1)
    return scalar edges = el(`returned', 2, 1)
    return scalar employed_observations = el(`returned', 3, 1)
    return scalar workers = el(`returned', 4, 1)
    return scalar firms = el(`returned', 5, 1)
    return scalar largest_component_id = el(`returned', 6, 1)
    return scalar largest_edges = el(`returned', 7, 1)
    return scalar largest_observations = el(`returned', 8, 1)
    return scalar largest_workers = el(`returned', 9, 1)
    return scalar largest_firms = el(`returned', 10, 1)
    return scalar largest_component_obs_share = el(`returned', 11, 1)
    return scalar largest_component_worker_share = el(`returned', 12, 1)
    return scalar largest_component_firm_share = el(`returned', 13, 1)
    return matrix network = `network'
end
