version 16.0

mata:

real scalar fesim_bm_output_schema_version()
{
    return(1)
}

string rowvector fesim_bm_solver_diagnostic_names()
{
    return(("b", "p", "lambda_u", "lambda_e", "delta", "discount", ///
        "surplus_coefficient", "reservation_wage", "upper_wage", ///
        "unemployment_rate", "employment_rate", "job_to_job_rate", ///
        "finite_job_to_job_rate", "equilibrium_profit", ///
        "unemployment_value", "reservation_residual", ///
        "reservation_scaled_residual", "equal_profit_scaled_residual", ///
        "stationary_residual", "offer_cdf_error", "worker_cdf_error", ///
        "finite_employment_error"))
}

string rowvector fesim_bm_firm_diagnostic_names()
{
    return(("firm_id", "offer_quantile", "posted_wage", ///
        "expected_mass", "expected_workers", "expected_share", ///
        "continuum_employment", "finite_scaled_employment", ///
        "continuum_profit", "finite_scaled_profit"))
}

real scalar fesim_bm_unemployment_value(
    struct fesim_bm_solution scalar solution)
{
    real scalar surplus, value

    if (solution.validated != 1) {
        _error(3300, "BM unemployment value requires a validated solution")
    }
    surplus = solution.surplus_coefficient * ///
        (solution.p - solution.reservation_wage)
    value = (solution.b + solution.lambda_u * surplus) / ///
        solution.discount
    if (missing(value)) _error(430, "BM unemployment value is invalid")
    return(value)
}

real colvector fesim_bm_employment_value(
    struct fesim_bm_solution scalar solution,
    real colvector wage)
{
    real scalar common, i, upper, unemployment_value
    real colvector quantile, log_argument, log_term, value

    if (solution.validated != 1 | cols(wage) != 1 | rows(wage) < 1 | ///
        any(missing(wage)) | any(wage :< solution.reservation_wage) | ///
        any(wage :> solution.upper_wage)) {
        _error(3300, "BM employment-value wages are invalid")
    }
    unemployment_value = fesim_bm_unemployment_value(solution)
    quantile = fesim_bm_offer_cdf(wage, solution.p, ///
        solution.reservation_wage, solution.lambda_e, solution.delta)
    upper = solution.discount + solution.delta + solution.lambda_e
    log_argument = -solution.lambda_e :* quantile / upper
    log_term = J(rows(wage), 1, .)
    for (i = 1; i <= rows(wage); i++) {
        log_term[i] = fesim_bm_log1p(log_argument[i])
    }
    common = 2 * (solution.p - solution.reservation_wage) * ///
        solution.lambda_e / (solution.delta + solution.lambda_e)^2
    value = unemployment_value :+ common :* (quantile :+ ///
        solution.discount / solution.lambda_e :* ///
        log_term)
    if (any(missing(value)) | any(value :< unemployment_value - 1e-10)) {
        _error(430, "BM employment value could not be evaluated")
    }
    return(value)
}

real colvector fesim_bm_solver_diagnostics(
    struct fesim_bm_solution scalar solution,
    struct fesim_bm_firms scalar universe)
{
    real colvector diagnostics

    if (solution.validated != 1 | universe.validated != 1) {
        _error(3300, "BM solver diagnostics require validated inputs")
    }
    diagnostics = (solution.b \ solution.p \ solution.lambda_u \ ///
        solution.lambda_e \ solution.delta \ solution.discount \ ///
        solution.surplus_coefficient \ solution.reservation_wage \ ///
        solution.upper_wage \ solution.unemployment_rate \ ///
        solution.employment_rate \ solution.job_to_job_rate \ ///
        universe.finite_job_to_job_rate \ solution.equilibrium_profit \ ///
        fesim_bm_unemployment_value(solution) \ ///
        solution.reservation_residual \ ///
        solution.reservation_scaled_residual \ ///
        solution.equal_profit_scaled_residual \ ///
        universe.stationary_residual \ universe.offer_cdf_error \ ///
        universe.worker_cdf_error \ universe.finite_employment_error)
    if (rows(diagnostics) != cols(fesim_bm_solver_diagnostic_names()) | ///
        any(missing(diagnostics))) {
        _error(430, "BM solver diagnostic schema is invalid")
    }
    return(diagnostics)
}

real matrix fesim_bm_firm_diagnostics(
    struct fesim_bm_solution scalar solution,
    struct fesim_bm_firms scalar universe,
    real scalar workers)
{
    real matrix diagnostics

    if (solution.validated != 1 | universe.validated != 1 | ///
        missing(workers) | workers < 1 | workers != floor(workers)) {
        _error(3300, "BM firm diagnostics require validated inputs")
    }
    diagnostics = (universe.firm_id, universe.offer_quantile, ///
        universe.posted_wage, universe.expected_employment_mass, ///
        workers :* universe.expected_employment_mass, ///
        universe.expected_employment_share, ///
        universe.continuum_employment, ///
        universe.finite_scaled_employment, ///
        universe.continuum_profit, universe.finite_scaled_profit)
    if (rows(diagnostics) != universe.firms | ///
        cols(diagnostics) != cols(fesim_bm_firm_diagnostic_names()) | ///
        any(missing(diagnostics))) {
        _error(430, "BM firm diagnostic schema is invalid")
    }
    return(diagnostics)
}

real scalar fesim_bm_output_panel(
    struct fesim_bm_solution scalar solution,
    struct fesim_bm_firms scalar universe,
    struct fesim_bm_panel scalar panel,
    real scalar start_value,
    string scalar time_format,
    string scalar truth)
{
    real scalar N, unemployment_value
    real rowvector variable_indices
    real colvector employed_rows, firm_id, spell_id, lnwage
    real colvector posted_wage, productivity, employment_value
    real colvector offer_quantile, expected_mass, expected_share
    real colvector continuum_employment, finite_scaled_employment
    real colvector continuum_profit, finite_scaled_profit, ntransitions
    real colvector time_value, tenure, unemployment_duration

    truth = strlower(strtrim(truth))
    if (solution.validated != 1 | universe.validated != 1 | ///
        panel.validated != 1 | panel.firms != universe.firms | ///
        (truth != "none" & truth != "basic" & truth != "full") | ///
        missing(start_value) | ///
        (time_format != "%ty" & time_format != "%tq" & ///
            time_format != "%tm")) {
        _error(3300, "BM output controls are invalid")
    }
    if (st_nobs() != 0 | st_nvar() != 0) {
        _error(3300, "BM output writer requires an empty Stata dataset")
    }
    N = fesim_output_checked_rows(panel.workers, panel.periods)
    if (rows(panel.worker_id) != N) {
        _error(3300, "BM panel does not match its declared dimensions")
    }

    /* Build and validate all output arrays before mutating caller data. */
    firm_id = panel.firm_id
    spell_id = panel.spell_id
    lnwage = J(N, 1, .)
    posted_wage = J(N, 1, .)
    productivity = J(N, 1, .)
    employment_value = J(N, 1, .)
    offer_quantile = J(N, 1, .)
    expected_mass = J(N, 1, .)
    expected_share = J(N, 1, .)
    continuum_employment = J(N, 1, .)
    finite_scaled_employment = J(N, 1, .)
    continuum_profit = J(N, 1, .)
    finite_scaled_profit = J(N, 1, .)
    employed_rows = selectindex(panel.employed :== 1)
    if (length(employed_rows)) {
        posted_wage[employed_rows] = ///
            universe.posted_wage[firm_id[employed_rows]]
        productivity[employed_rows] = ///
            universe.firm_productivity[firm_id[employed_rows]]
        lnwage[employed_rows] = ln(posted_wage[employed_rows])
        employment_value[employed_rows] = fesim_bm_employment_value(
            solution, posted_wage[employed_rows])
        offer_quantile[employed_rows] = ///
            universe.offer_quantile[firm_id[employed_rows]]
        expected_mass[employed_rows] = ///
            universe.expected_employment_mass[firm_id[employed_rows]]
        expected_share[employed_rows] = ///
            universe.expected_employment_share[firm_id[employed_rows]]
        continuum_employment[employed_rows] = ///
            universe.continuum_employment[firm_id[employed_rows]]
        finite_scaled_employment[employed_rows] = ///
            universe.finite_scaled_employment[firm_id[employed_rows]]
        continuum_profit[employed_rows] = ///
            universe.continuum_profit[firm_id[employed_rows]]
        finite_scaled_profit[employed_rows] = ///
            universe.finite_scaled_profit[firm_id[employed_rows]]
    }
    if (any(panel.employed :== 0)) {
        firm_id[selectindex(panel.employed :== 0)] = ///
            J(sum(panel.employed :== 0), 1, .)
        spell_id[selectindex(panel.employed :== 0)] = ///
            J(sum(panel.employed :== 0), 1, .)
    }
    time_value = start_value :+ panel.period_index :- 1
    tenure = panel.tenure / panel.period_length
    unemployment_duration = panel.unemployment_duration / panel.period_length
    ntransitions = panel.ntransitions
    ntransitions[selectindex(panel.period_index :== 1)] = ///
        J(panel.workers, 1, .)
    unemployment_value = fesim_bm_unemployment_value(solution)
    if (any(missing(panel.worker_id)) | any(missing(time_value)) | ///
        any(missing(panel.employed)) | ///
        any(panel.employed :!= floor(panel.employed)) | ///
        any(panel.employed :< 0) | any(panel.employed :> 1) | ///
        any(missing(lnwage[employed_rows])) | ///
        any(missing(posted_wage[employed_rows])) | ///
        missing(unemployment_value)) {
        _error(430, "BM output arrays are invalid")
    }

    st_addobs(N)
    variable_indices = st_addvar(("long", "long", "long", "byte", ///
        "double", "long", "double", "double", "byte", "byte", ///
        "byte", "byte", "long"), ("workerid", "time", "firmid", ///
        "employed", "lnwage", "spellid", "tenure", ///
        "unemp_duration", "newjob", "from_unemp", "to_unemp", ///
        "jobtojob", "ntransitions"))
    if (truth != "none") {
        variable_indices = st_addvar(J(1, 3, "double"), ///
            ("lnwage_true", "posted_wage_true", "productivity_true"))
    }
    if (truth == "full") {
        variable_indices = st_addvar(J(1, 18, "double"), ///
            ("reservation_wage_true", "unemployment_value_true", ///
            "employment_value_true", "offer_quantile_true", ///
            "expected_firm_mass_true", "expected_firm_share_true", ///
            "continuum_employment_true", ///
            "finite_scaled_employment_true", "continuum_profit_true", ///
            "finite_scaled_profit_true", "n_eu_true", "n_ee_true", ///
            "n_ue_true", "n_unemployment_offers_true", ///
            "n_employed_offers_true", "n_rejected_offers_true", ///
            "n_events_true", "ntransitions_true"))
        variable_indices = st_addvar(J(1, 2, "double"), ///
            ("employment_exposure_true", "unemployment_exposure_true"))
    }

    st_store(., "workerid", panel.worker_id)
    st_store(., "time", time_value)
    st_store(., "firmid", firm_id)
    st_store(., "employed", panel.employed)
    st_store(., "lnwage", lnwage)
    st_store(., "spellid", spell_id)
    st_store(., "tenure", tenure)
    st_store(., "unemp_duration", unemployment_duration)
    st_store(., "newjob", panel.newjob)
    st_store(., "from_unemp", panel.from_unemp)
    st_store(., "to_unemp", panel.to_unemp)
    st_store(., "jobtojob", panel.jobtojob)
    st_store(., "ntransitions", ntransitions)
    if (truth != "none") {
        st_store(., "lnwage_true", lnwage)
        st_store(., "posted_wage_true", posted_wage)
        st_store(., "productivity_true", productivity)
    }
    if (truth == "full") {
        st_store(., "reservation_wage_true", ///
            J(N, 1, solution.reservation_wage))
        st_store(., "unemployment_value_true", ///
            J(N, 1, unemployment_value))
        st_store(., "employment_value_true", employment_value)
        st_store(., "offer_quantile_true", offer_quantile)
        st_store(., "expected_firm_mass_true", expected_mass)
        st_store(., "expected_firm_share_true", expected_share)
        st_store(., "continuum_employment_true", continuum_employment)
        st_store(., "finite_scaled_employment_true", ///
            finite_scaled_employment)
        st_store(., "continuum_profit_true", continuum_profit)
        st_store(., "finite_scaled_profit_true", finite_scaled_profit)
        st_store(., "n_eu_true", panel.n_eu)
        st_store(., "n_ee_true", panel.n_ee)
        st_store(., "n_ue_true", panel.n_ue)
        st_store(., "n_unemployment_offers_true", ///
            panel.n_unemployment_offers)
        st_store(., "n_employed_offers_true", panel.n_employed_offers)
        st_store(., "n_rejected_offers_true", panel.n_rejected_offers)
        st_store(., "n_events_true", panel.n_events)
        st_store(., "ntransitions_true", panel.ntransitions)
        st_store(., "employment_exposure_true", panel.employment_exposure)
        st_store(., "unemployment_exposure_true", ///
            panel.unemployment_exposure)
    }

    st_varformat("time", time_format)
    st_varlabel("workerid", "Worker identifier")
    st_varlabel("time", "Output period")
    st_varlabel("firmid", "Observed employer identifier")
    st_varlabel("employed", "Employed at observation time")
    st_varlabel("lnwage", "Observed log accepted wage")
    st_varlabel("spellid", "Worker-specific job-spell identifier")
    st_varlabel("tenure", "Tenure in output-period units")
    st_varlabel("unemp_duration", ///
        "Unemployment duration in output-period units")
    st_varlabel("newjob", "New observed job")
    st_varlabel("from_unemp", ///
        "Observed nonemployment-to-employment transition")
    st_varlabel("to_unemp", ///
        "Observed employment-to-nonemployment transition")
    st_varlabel("jobtojob", ///
        "Observed direct employer-to-employer transition")
    st_varlabel("ntransitions", ///
        "Latent transitions since prior observation")
    if (truth != "none") {
        st_varlabel("lnwage_true", "True log accepted wage")
        st_varlabel("posted_wage_true", "True posted wage level")
        st_varlabel("productivity_true", "True firm productivity level")
    }
    if (truth == "full") {
        st_varlabel("reservation_wage_true", ///
            "Equilibrium reservation wage level")
        st_varlabel("unemployment_value_true", ///
            "Equilibrium value of unemployment")
        st_varlabel("employment_value_true", ///
            "Equilibrium value of observed employment")
        st_varlabel("offer_quantile_true", ///
            "Firm offer-distribution quantile")
        st_varlabel("expected_firm_mass_true", ///
            "Exact finite stationary firm mass")
        st_varlabel("expected_firm_share_true", ///
            "Exact finite conditional employment share")
        st_varlabel("continuum_employment_true", ///
            "Continuum firm employment scale")
        st_varlabel("finite_scaled_employment_true", ///
            "Finite firm employment scaled by firm count")
        st_varlabel("continuum_profit_true", ///
            "Continuum equilibrium flow profit")
        st_varlabel("finite_scaled_profit_true", ///
            "Finite-grid scaled flow profit diagnostic")
        st_varlabel("n_eu_true", "Exact destructions in output interval")
        st_varlabel("n_ee_true", ///
            "Exact accepted direct moves in output interval")
        st_varlabel("n_ue_true", ///
            "Exact accepted entries in output interval")
        st_varlabel("n_unemployment_offers_true", ///
            "Exact unemployment offers in output interval")
        st_varlabel("n_employed_offers_true", ///
            "Exact employed offers in output interval")
        st_varlabel("n_rejected_offers_true", ///
            "Exact rejected offers in output interval")
        st_varlabel("n_events_true", ///
            "Exact primitive events in output interval")
        st_varlabel("ntransitions_true", ///
            "Exact accepted transitions in output interval")
        st_varlabel("employment_exposure_true", ///
            "Exact employment exposure in years")
        st_varlabel("unemployment_exposure_true", ///
            "Exact unemployment exposure in years")
    }
    st_global("_dta[fesim_bm_output_schema]", ///
        strofreal(fesim_bm_output_schema_version(), "%9.0g"))
    st_global("_dta[fesim_bm_reservation_wage]", ///
        strofreal(solution.reservation_wage, "%21.17g"))
    st_global("_dta[fesim_bm_upper_wage]", ///
        strofreal(solution.upper_wage, "%21.17g"))
    st_global("_dta[fesim_bm_productivity]", ///
        strofreal(solution.p, "%21.17g"))
    st_global("_dta[fesim_bm_firm_mode]", universe.mode)
    stata("sort workerid time", 1)
    stata("isid workerid time", 1)
    return(N)
}

end
