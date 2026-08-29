*! fesim common realized moments 0.0.0-dev 29aug2026
program define _fesim_moments, rclass
    version 16.0
    syntax , FIRMS(integer) [ TRUTHMOMENTS(name) TARGETS(name) ]

    if `firms' < 1 {
        di as error "firms() must be a positive integer"
        exit 198
    }
    foreach variable in workerid time firmid employed lnwage newjob ///
        from_unemp to_unemp jobtojob ntransitions {
        capture confirm variable `variable'
        if _rc {
            di as error "required fesim moment variable is missing: `variable'"
            exit 111
        }
    }
    capture isid workerid time
    if _rc {
        di as error "fesim moments require a unique workerid time key"
        exit 459
    }
    capture assert inlist(employed, 0, 1)
    if _rc {
        di as error "employed must contain only zero and one"
        exit 459
    }
    capture assert workerid >= 1 & workerid == floor(workerid)
    if _rc {
        di as error "workerid must contain positive integers"
        exit 459
    }
    capture assert inrange(firmid, 1, `firms') & ///
        firmid == floor(firmid) if employed
    if _rc {
        di as error "employed firm identifiers must be integers in firms()"
        exit 459
    }
    capture assert missing(firmid) == !employed
    if _rc {
        di as error "firmid missingness must match employment"
        exit 459
    }
    capture assert missing(lnwage) == !employed
    if _rc {
        di as error "lnwage missingness must match employment"
        exit 459
    }

    preserve
    sort workerid time

    quietly count
    local N = r(N)
    tempvar worker_tag time_tag firm_tag origin_employed ///
        observed_firm_tag firms_observed worker_first
    quietly by workerid: generate byte `worker_tag' = _n == 1
    quietly count if `worker_tag'
    local N_workers = r(N)
    quietly egen byte `time_tag' = tag(time)
    quietly count if `time_tag'
    local periods = r(N)
    capture by workerid: assert _N == `periods'
    if _rc | `N' != `N_workers' * `periods' {
        restore
        di as error "fesim moments require a balanced worker-period panel"
        exit 459
    }
    quietly sort time workerid
    capture by time: assert _N == `N_workers'
    if _rc {
        restore
        di as error "fesim moments require a common period grid"
        exit 459
    }

    quietly sort workerid time
    capture by workerid: assert missing(newjob) & missing(from_unemp) & ///
        missing(jobtojob) & missing(ntransitions) if _n == 1
    if _rc {
        restore
        di as error "backward flow variables must be missing initially"
        exit 459
    }
    capture by workerid: assert inlist(newjob, 0, 1) & ///
        inlist(from_unemp, 0, 1) & inlist(jobtojob, 0, 1) & ///
        ntransitions >= 0 & ntransitions == floor(ntransitions) if _n > 1
    if _rc {
        restore
        di as error "backward flow variables violate the common schema"
        exit 459
    }
    capture by workerid: assert missing(to_unemp) if _n == _N
    if _rc {
        restore
        di as error "to_unemp must be missing in the final worker-period"
        exit 459
    }
    capture by workerid: assert inlist(to_unemp, 0, 1) if _n < _N
    if _rc {
        restore
        di as error "to_unemp violates the common forward-flow schema"
        exit 459
    }
    capture by workerid: assert from_unemp == ///
        (!employed[_n - 1] & employed) & jobtojob == ///
        (employed[_n - 1] & employed & firmid != firmid[_n - 1]) ///
        if _n > 1
    if _rc {
        restore
        di as error "backward flow indicators disagree with observed states"
        exit 459
    }
    capture by workerid: assert to_unemp == ///
        (employed & !employed[_n + 1]) if _n < _N
    if _rc {
        restore
        di as error "to_unemp disagrees with observed states"
        exit 459
    }

    quietly sort firmid
    quietly by firmid: generate byte `firm_tag' = _n == 1 if employed
    quietly count if `firm_tag' == 1
    local N_firms_active = r(N)
    if `N_firms_active' > `firms' {
        restore
        di as error "active firms exceed firms()"
        exit 459
    }

    quietly summarize employed, meanonly
    local employment_rate = r(mean)

    quietly sort workerid time
    quietly by workerid: generate byte `origin_employed' = employed[_n - 1] ///
        if _n > 1
    quietly summarize to_unemp if employed == 1 & !missing(to_unemp), meanonly
    local p_eu_observed = cond(r(N), r(mean), .)
    quietly summarize from_unemp if `origin_employed' == 0, meanonly
    local p_ue_observed = cond(r(N), r(mean), .)
    quietly summarize jobtojob if `origin_employed' == 1, meanonly
    local p_ee_observed = cond(r(N), r(mean), .)
    quietly summarize ntransitions if !missing(ntransitions), meanonly
    local mean_ntransitions = cond(r(N), r(mean), .)

    quietly summarize lnwage if employed
    local lnwage_mean = cond(r(N), r(mean), .)
    local lnwage_sd = cond(r(N) > 1, r(sd), .)
    local lnwage_p10 .
    local lnwage_p50 .
    local lnwage_p90 .
    quietly count if employed
    if r(N) {
        quietly _pctile lnwage if employed, percentiles(10 50 90)
        local lnwage_p10 = r(r1)
        local lnwage_p50 = r(r2)
        local lnwage_p90 = r(r3)
    }

    quietly sort workerid firmid
    quietly by workerid firmid: generate byte `observed_firm_tag' = ///
        _n == 1 if employed
    quietly by workerid: egen long `firms_observed' = total(`observed_firm_tag')
    quietly by workerid: generate byte `worker_first' = _n == 1
    quietly count if `worker_first' & `firms_observed' >= 2
    local N_movers = r(N)
    quietly count if `worker_first' & `firms_observed' == 1
    local N_stayers = r(N)
    quietly count if `worker_first' & `firms_observed' == 0
    local N_never_employed = r(N)
    local N_ever_employed = `N_movers' + `N_stayers'
    local mover_share = cond(`N_ever_employed', ///
        `N_movers' / `N_ever_employed', .)
    local stayer_share = cond(`N_ever_employed', ///
        `N_stayers' / `N_ever_employed', .)

    local N_active_firm_periods 0
    local firm_size_mean .
    local firm_size_sd .
    local firm_size_p10 .
    local firm_size_p50 .
    local firm_size_p90 .
    local firm_size_p99 .
    local firm_hhi_mean .
    quietly count if employed
    if r(N) {
        quietly sort time firmid
        tempvar firm_period_tag firm_size period_employment ///
            squared_share period_hhi hhi_tag
        quietly by time firmid: generate byte `firm_period_tag' = ///
            _n == 1 if employed
        quietly by time firmid: generate long `firm_size' = _N if employed
        quietly count if `firm_period_tag' == 1
        local N_active_firm_periods = r(N)
        quietly summarize `firm_size' if `firm_period_tag' == 1
        local firm_size_mean = r(mean)
        local firm_size_sd = cond(r(N) > 1, r(sd), .)
        quietly _pctile `firm_size' if `firm_period_tag' == 1, ///
            percentiles(10 50 90 99)
        local firm_size_p10 = r(r1)
        local firm_size_p50 = r(r2)
        local firm_size_p90 = r(r3)
        local firm_size_p99 = r(r4)
        quietly by time: egen double `period_employment' = total(employed)
        quietly generate double `squared_share' = ///
            (`firm_size' / `period_employment') ^ 2 ///
            if `firm_period_tag' == 1
        quietly by time: egen double `period_hhi' = total(`squared_share')
        quietly by time: generate byte `hhi_tag' = _n == 1
        quietly summarize `period_hhi' if `hhi_tag' & ///
            `period_employment' > 0, meanonly
        local firm_hhi_mean = r(mean)
    }

    local moment_names ///
        "N N_workers N_firms N_firms_active periods employment_rate p_eu_observed p_ue_observed p_ee_observed mean_ntransitions lnwage_mean lnwage_sd lnwage_p10 lnwage_p50 lnwage_p90 N_active_firm_periods firm_size_mean firm_size_sd firm_size_p10 firm_size_p50 firm_size_p90 firm_size_p99 firm_hhi_mean N_movers N_stayers N_never_employed mover_share stayer_share"
    local moment_values ///
        "`N' `N_workers' `firms' `N_firms_active' `periods' `employment_rate' `p_eu_observed' `p_ue_observed' `p_ee_observed' `mean_ntransitions' `lnwage_mean' `lnwage_sd' `lnwage_p10' `lnwage_p50' `lnwage_p90' `N_active_firm_periods' `firm_size_mean' `firm_size_sd' `firm_size_p10' `firm_size_p50' `firm_size_p90' `firm_size_p99' `firm_hhi_mean' `N_movers' `N_stayers' `N_never_employed' `mover_share' `stayer_share'"

    tempname moment_matrix
    local n_moments : word count `moment_names'
    matrix `moment_matrix' = J(`n_moments', 1, .)
    forvalues row = 1/`n_moments' {
        local value : word `row' of `moment_values'
        matrix `moment_matrix'[`row', 1] = `value'
    }
    matrix rownames `moment_matrix' = `moment_names'
    matrix colnames `moment_matrix' = realized

    if `"`truthmoments'"' != "" {
        capture confirm matrix `truthmoments'
        if _rc | colsof(`truthmoments') != 1 {
            restore
            di as error "truthmoments() must name a one-column matrix"
            exit 198
        }
        local truth_names : rownames `truthmoments'
        local expected_truth_names ///
            "alpha_true_mean alpha_true_sd alpha_true_var psi_true_mean psi_true_sd psi_true_var epsilon_true_mean epsilon_true_sd epsilon_true_var cov_alpha_psi_true"
        if `"`truth_names'"' != `"`expected_truth_names'"' {
            restore
            di as error "truthmoments() has an unsupported row schema"
            exit 198
        }
        matrix `moment_matrix' = (`moment_matrix' \ `truthmoments')
        local moment_names `"`moment_names' `truth_names'"'
        matrix rownames `moment_matrix' = `moment_names'
        matrix colnames `moment_matrix' = realized
    }

    if `"`targets'"' != "" {
        capture confirm matrix `targets'
        if _rc | colsof(`targets') != 1 {
            restore
            di as error "targets() must name a one-column matrix"
            exit 198
        }
        local target_names : rownames `targets'
        local n_targets : word count `target_names'
        tempname target_table
        matrix `target_table' = J(`n_targets', 4, .)
        forvalues row = 1/`n_targets' {
            local target_name : word `row' of `target_names'
            local moment_position : list posof `"`target_name'"' in moment_names
            if !`moment_position' {
                restore
                di as error "target has no realized common moment: `target_name'"
                exit 198
            }
            local target_value = `targets'[`row', 1]
            if missing(`target_value') {
                restore
                di as error "target values must be nonmissing"
                exit 198
            }
            local realized_value = `moment_matrix'[`moment_position', 1]
            local difference = `realized_value' - `target_value'
            matrix `target_table'[`row', 1] = `target_value'
            matrix `target_table'[`row', 2] = `realized_value'
            matrix `target_table'[`row', 3] = `difference'
            if `target_value' != 0 {
                matrix `target_table'[`row', 4] = ///
                    `difference' / abs(`target_value')
            }
        }
        matrix rownames `target_table' = `target_names'
        matrix colnames `target_table' = ///
            target realized difference relative_difference
    }

    restore
    return scalar N = `N'
    return scalar N_workers = `N_workers'
    return scalar N_firms = `firms'
    return scalar N_firms_active = `N_firms_active'
    return scalar periods = `periods'
    return scalar employment_rate = `employment_rate'
    return scalar p_eu_realized = `p_eu_observed'
    return scalar p_ue_realized = `p_ue_observed'
    return scalar p_ee_realized = `p_ee_observed'
    return scalar N_movers = `N_movers'
    return scalar N_stayers = `N_stayers'
    return scalar N_never_employed = `N_never_employed'
    return matrix moments = `moment_matrix'
    if `"`targets'"' != "" return matrix targets = `target_table'
end
