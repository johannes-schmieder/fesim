*! fesim observed bipartite network diagnostics 1.2.0-dev 06sep2026
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
    foreach variable in workerid time firmid employed jobtojob {
        capture confirm numeric variable `variable'
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
    quietly sort workerid time
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
    capture by workerid (time): assert missing(jobtojob) if _n == 1
    if _rc {
        di as error "first worker observations require missing job-to-job indicators"
        exit 459
    }
    capture by workerid (time): assert inlist(jobtojob, 0, 1) & ///
        jobtojob == (employed & employed[_n - 1] & ///
        firmid != firmid[_n - 1]) if _n > 1
    if _rc {
        di as error "job-to-job indicators do not match the observed panel"
        exit 459
    }

    tempname generated returned network generated_leaveout ///
        returned_leaveout leaveout
    tempvar direct_move move_origin
    quietly generate byte `direct_move' = jobtojob == 1
    quietly by workerid (time): generate double `move_origin' = ///
        firmid[_n - 1] if `direct_move'
    local mark_largest = `"`connectivity'"' == "largest"
    local keep_variable ""
    if `mark_largest' {
        tempvar in_largest
        quietly generate byte `in_largest' = 0
        local keep_variable `"`in_largest'"'
    }
    quietly count if employed
    local employed_observations = r(N)
    if `employed_observations' == 0 {
        if `"`connectivity'"' == "largest" {
            di as error "connectivity(largest) is undefined without observed employment"
            exit 459
        }
        matrix `generated' = J(21, 1, .)
        forvalues row = 1/5 {
            matrix `generated'[`row', 1] = 0
        }
        forvalues row = 7/10 {
            matrix `generated'[`row', 1] = 0
        }
        matrix `generated'[14, 1] = 0
        matrix `generated'[15, 1] = 0
        matrix `generated'[20, 1] = 0
        matrix `generated'[21, 1] = 0
        matrix `generated_leaveout' = J(19, 1, .)
        forvalues row = 1/9 {
            matrix `generated_leaveout'[`row', 1] = 0
        }
        matrix `generated_leaveout'[14, 1] = 0
        matrix `generated_leaveout'[16, 1] = 0
    }
    else {
        capture noisily mata: fesim_network_store_panel( ///
            `workers', `firms', "`generated'", "`generated_leaveout'", ///
            "`keep_variable'", `mark_largest', ///
            "`move_origin'", "`direct_move'")
        local graph_rc = _rc
        if `graph_rc' exit `graph_rc'
    }

    local diagnostic_names ///
        "components edges employed_observations workers firms largest_component_id largest_edges largest_observations largest_workers largest_firms largest_observation_share largest_worker_share largest_firm_share firms_no_movers firm_links edge_weight_p10 edge_weight_p50 edge_weight_p90 edge_weight_p99 articulation_firms graph_bridge_links"
    matrix rownames `generated' = `diagnostic_names'
    matrix colnames `generated' = generated
    local leaveout_names ///
        "largest_observations largest_workers largest_firms largest_matches worker_cut_vertices worker_set_observations worker_set_workers worker_set_firms worker_set_matches worker_set_observation_share worker_set_worker_share worker_set_firm_share worker_set_match_share vulnerable_matches_largest vulnerable_match_share_largest vulnerable_matches_worker_set vulnerable_match_share_worker worker_out_connected match_out_connected"
    matrix rownames `generated_leaveout' = `leaveout_names'
    matrix colnames `generated_leaveout' = value
    matrix `returned' = `generated'
    matrix colnames `returned' = returned
    matrix `returned_leaveout' = `generated_leaveout'

    local sample_workers = `workers'
    if `"`connectivity'"' == "largest" {
        quietly keep if `in_largest'
        quietly drop `in_largest'
        quietly sort workerid time
        capture noisily mata: fesim_network_store_panel( ///
            `workers', `firms', "`returned'", "`returned_leaveout'", ///
            "", 0, ///
            "`move_origin'", "`direct_move'")
        local graph_rc = _rc
        if `graph_rc' exit `graph_rc'
        local sample_workers = el(`returned', 4, 1)
    }
    matrix `network' = (`generated', `returned')
    matrix rownames `network' = `diagnostic_names'
    matrix colnames `network' = generated returned
    matrix `leaveout' = `returned_leaveout'
    matrix rownames `leaveout' = `leaveout_names'
    matrix colnames `leaveout' = value

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
    return scalar firms_no_movers = el(`returned', 14, 1)
    return scalar firm_links = el(`returned', 15, 1)
    return scalar edge_weight_p10 = el(`returned', 16, 1)
    return scalar edge_weight_p50 = el(`returned', 17, 1)
    return scalar edge_weight_p90 = el(`returned', 18, 1)
    return scalar edge_weight_p99 = el(`returned', 19, 1)
    return scalar articulation_firms = el(`returned', 20, 1)
    return scalar graph_bridge_links = el(`returned', 21, 1)
    return matrix network = `network'
    return matrix leaveout = `leaveout'
end
