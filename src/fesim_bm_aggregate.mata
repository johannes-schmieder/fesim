version 16.0

mata:

real scalar fesim_bm_panel_schema_version()
{
    return(1)
}

real scalar fesim_bm_interval_index(
    real scalar event_time,
    real scalar period_length,
    real scalar periods,
    real scalar tolerance)
{
    real scalar horizon, index

    if (missing(event_time) | missing(period_length) | period_length <= 0 | ///
        missing(periods) | periods < 1 | periods != floor(periods) | ///
        missing(tolerance) | tolerance <= 0 | tolerance > 1e-4) {
        _error(3300, "BM event-period inputs are invalid")
    }
    horizon = periods * period_length
    if (event_time <= 0 | event_time > horizon + tolerance * max((1, horizon))) {
        _error(3300, "BM event time lies outside the output horizon")
    }
    index = ceil(event_time / period_length)
    if (index < 1 | index > periods) {
        _error(430, "BM event-period mapping failed")
    }
    return(index)
}

string rowvector fesim_bm_flow_row_names()
{
    return(("unemployment_share", "ue", "eu", "ee"))
}

string rowvector fesim_bm_flow_column_names()
{
    return(("theory", "event", "observed", "observed_per_year"))
}

void fesim_bm_panel_validate(
    struct fesim_bm_solution scalar solution,
    struct fesim_bm_firms scalar universe,
    struct fesim_bm_history scalar history,
    struct fesim_bm_panel scalar panel,
    real scalar tolerance)
{
    real scalar N, worker, period, row, previous, following
    real scalar expected_newjob, expected_from, expected_to, expected_jtj
    real colvector expected_worker, expected_period, last_rows
    real matrix counts

    N = panel.workers * panel.periods
    if (solution.validated != 1 | universe.validated != 1 | ///
        history.validated != 1 | ///
        panel.schema_version != fesim_bm_panel_schema_version() | ///
        panel.status != "aggregated" | ///
        (panel.frequency != "year" & panel.frequency != "quarter" & ///
            panel.frequency != "month") | ///
        missing(panel.workers) | panel.workers < 1 | ///
        panel.workers != floor(panel.workers) | ///
        panel.workers != history.workers | panel.firms != universe.firms | ///
        missing(panel.periods) | panel.periods < 1 | ///
        panel.periods != floor(panel.periods) | ///
        panel.period_length != fesim_time_delta_years(panel.frequency) | ///
        abs(panel.horizon - panel.periods * panel.period_length) > ///
            tolerance * max((1, panel.horizon)) | ///
        abs(panel.horizon - history.horizon) > ///
            tolerance * max((1, history.horizon)) | ///
        missing(tolerance) | tolerance <= 0 | tolerance > 1e-4) {
        _error(3300, "BM aggregated panel structure is invalid")
    }
    expected_worker = 1 :+ floor((0::(N - 1)) / panel.periods)
    expected_period = 1 :+ mod((0::(N - 1)), panel.periods)
    if (rows(panel.worker_id) != N | rows(panel.period_index) != N | ///
        rows(panel.employed) != N | rows(panel.firm_id) != N | ///
        rows(panel.spell_id) != N | rows(panel.tenure) != N | ///
        rows(panel.unemployment_duration) != N | rows(panel.n_eu) != N | ///
        rows(panel.n_ee) != N | rows(panel.n_ue) != N | ///
        rows(panel.n_unemployment_offers) != N | ///
        rows(panel.n_employed_offers) != N | ///
        rows(panel.n_rejected_offers) != N | rows(panel.n_events) != N | ///
        rows(panel.ntransitions) != N | ///
        rows(panel.employment_exposure) != N | ///
        rows(panel.unemployment_exposure) != N | rows(panel.newjob) != N | ///
        rows(panel.from_unemp) != N | rows(panel.to_unemp) != N | ///
        rows(panel.jobtojob) != N | ///
        any(panel.worker_id :!= expected_worker) | ///
        any(panel.period_index :!= expected_period)) {
        _error(3300, "BM aggregated panel arrays are invalid")
    }
    fesim_bm_initial_state_validate(universe, panel.employed, ///
        panel.firm_id, panel.spell_id, panel.tenure, ///
        panel.unemployment_duration)
    counts = (panel.n_eu, panel.n_ee, panel.n_ue, ///
        panel.n_unemployment_offers, panel.n_employed_offers, ///
        panel.n_rejected_offers, panel.n_events, panel.ntransitions)
    if (any(missing(counts)) | any(counts :< 0) | ///
        any(counts :!= floor(counts)) | ///
        any(panel.n_unemployment_offers :!= panel.n_ue) | ///
        any(panel.n_employed_offers :!= ///
            panel.n_ee + panel.n_rejected_offers) | ///
        any(panel.n_events :!= panel.n_unemployment_offers + ///
            panel.n_employed_offers + panel.n_eu) | ///
        any(panel.ntransitions :!= panel.n_eu + panel.n_ee + panel.n_ue) | ///
        sum(panel.n_eu) != history.destructions | ///
        sum(panel.n_ee) != history.accepted_moves | ///
        sum(panel.n_ue) != history.accepted_entries | ///
        sum(panel.n_rejected_offers) != history.rejected_offers | ///
        sum(panel.n_events) != history.total_events | ///
        sum(panel.ntransitions) != history.total_transitions) {
        _error(430, "BM aggregated event counts are inconsistent")
    }
    if (any(missing(panel.employment_exposure)) | ///
        any(missing(panel.unemployment_exposure)) | ///
        any(panel.employment_exposure :< 0) | ///
        any(panel.unemployment_exposure :< 0) | ///
        max(abs(panel.employment_exposure + panel.unemployment_exposure :- ///
            panel.period_length)) > tolerance | ///
        abs(sum(panel.employment_exposure + panel.unemployment_exposure) - ///
            panel.workers * panel.horizon) > ///
            tolerance * max((1, panel.workers * panel.horizon))) {
        _error(430, "BM aggregated exposure is inconsistent")
    }
    for (worker = 1; worker <= panel.workers; worker++) {
        for (period = 1; period <= panel.periods; period++) {
            row = (worker - 1) * panel.periods + period
            if (period == 1) {
                if (!missing(panel.newjob[row]) | ///
                    !missing(panel.from_unemp[row]) | ///
                    !missing(panel.jobtojob[row])) {
                    _error(430, "BM first observed-flow boundary is invalid")
                }
            }
            else {
                previous = row - 1
                expected_newjob = panel.employed[row] & ///
                    (!panel.employed[previous] | ///
                    panel.firm_id[row] != panel.firm_id[previous] | ///
                    panel.spell_id[row] != panel.spell_id[previous])
                expected_from = !panel.employed[previous] & panel.employed[row]
                expected_jtj = panel.employed[previous] & panel.employed[row] & ///
                    panel.firm_id[row] != panel.firm_id[previous]
                if (panel.newjob[row] != expected_newjob | ///
                    panel.from_unemp[row] != expected_from | ///
                    panel.jobtojob[row] != expected_jtj) {
                    _error(430, "BM backward observed flows are invalid")
                }
            }
            if (period == panel.periods) {
                if (!missing(panel.to_unemp[row])) {
                    _error(430, "BM last observed-flow boundary is invalid")
                }
            }
            else {
                following = row + 1
                expected_to = panel.employed[row] & !panel.employed[following]
                if (panel.to_unemp[row] != expected_to) {
                    _error(430, "BM forward observed flows are invalid")
                }
            }
        }
    }
    last_rows = (1::panel.workers) :* panel.periods
    if (panel.employed[last_rows] != history.final_employed | ///
        panel.firm_id[last_rows] != history.final_firm_id | ///
        panel.spell_id[last_rows] != history.final_spell_id | ///
        mreldif(panel.tenure[last_rows], history.final_tenure) > tolerance | ///
        mreldif(panel.unemployment_duration[last_rows], ///
            history.final_unemployment_duration) > tolerance) {
        _error(430, "BM final aggregated state is inconsistent")
    }
}

struct fesim_bm_panel scalar fesim_bm_aggregate_history(
    struct fesim_bm_solution scalar solution,
    struct fesim_bm_firms scalar universe,
    struct fesim_bm_history scalar history,
    string scalar frequency,
    real scalar periods,
    real scalar tolerance)
{
    struct fesim_bm_panel scalar panel
    real scalar N, worker, period, row, event_row, event_time, event_kind
    real scalar accepted, endpoint, segment, current_time
    real scalar current_employed, current_firm, current_spell
    real scalar current_tenure, current_unemployment

    frequency = strlower(strtrim(frequency))
    if (solution.validated != 1 | universe.validated != 1 | ///
        history.validated != 1 | history.record_events != 1 | ///
        missing(periods) | periods < 1 | periods != floor(periods) | ///
        missing(tolerance) | tolerance <= 0 | ///
        tolerance > 1e-4) {
        _error(3300, "BM aggregation controls are invalid")
    }
    panel.period_length = fesim_time_delta_years(frequency)
    if (abs(history.horizon - periods * panel.period_length) > ///
        tolerance * max((1, history.horizon))) {
        _error(3300, "BM event horizon does not match output periods")
    }
    fesim_bm_firms_validate(solution, universe, tolerance)
    fesim_bm_history_validate(solution, universe, history, tolerance)
    N = fesim_output_checked_rows(history.workers, periods)
    panel.schema_version = fesim_bm_panel_schema_version()
    panel.status = "aggregated"
    panel.frequency = frequency
    panel.workers = history.workers
    panel.firms = universe.firms
    panel.periods = periods
    panel.horizon = history.horizon
    panel.worker_id = 1 :+ floor((0::(N - 1)) / periods)
    panel.period_index = 1 :+ mod((0::(N - 1)), periods)
    panel.employed = J(N, 1, .)
    panel.firm_id = J(N, 1, .)
    panel.spell_id = J(N, 1, .)
    panel.tenure = J(N, 1, .)
    panel.unemployment_duration = J(N, 1, .)
    panel.n_eu = J(N, 1, 0)
    panel.n_ee = J(N, 1, 0)
    panel.n_ue = J(N, 1, 0)
    panel.n_unemployment_offers = J(N, 1, 0)
    panel.n_employed_offers = J(N, 1, 0)
    panel.n_rejected_offers = J(N, 1, 0)
    panel.n_events = J(N, 1, 0)
    panel.ntransitions = J(N, 1, 0)
    panel.employment_exposure = J(N, 1, 0)
    panel.unemployment_exposure = J(N, 1, 0)
    panel.newjob = J(N, 1, .)
    panel.from_unemp = J(N, 1, .)
    panel.to_unemp = J(N, 1, .)
    panel.jobtojob = J(N, 1, .)

    event_row = 1
    for (worker = 1; worker <= panel.workers; worker++) {
        current_time = 0
        current_employed = history.initial_employed[worker]
        current_firm = history.initial_firm_id[worker]
        current_spell = history.initial_spell_id[worker]
        current_tenure = history.initial_tenure[worker]
        current_unemployment = history.initial_unemployment_duration[worker]
        for (period = 1; period <= periods; period++) {
            row = (worker - 1) * periods + period
            endpoint = period * panel.period_length
            while (event_row <= history.total_events) {
                if (history.events[event_row, 1] != worker) break
                if (fesim_bm_interval_index(history.events[event_row, 2], ///
                    panel.period_length, periods, tolerance) > period) break
                event_time = history.events[event_row, 2]
                segment = event_time - current_time
                if (current_employed) {
                    panel.employment_exposure[row] = ///
                        panel.employment_exposure[row] + segment
                }
                else {
                    panel.unemployment_exposure[row] = ///
                        panel.unemployment_exposure[row] + segment
                }
                event_kind = history.events[event_row, 3]
                accepted = history.events[event_row, 4]
                panel.n_events[row] = panel.n_events[row] + 1
                if (event_kind == 1) {
                    panel.n_unemployment_offers[row] = ///
                        panel.n_unemployment_offers[row] + 1
                    panel.n_ue[row] = panel.n_ue[row] + 1
                }
                else if (event_kind == 2) {
                    panel.n_employed_offers[row] = ///
                        panel.n_employed_offers[row] + 1
                    if (accepted) panel.n_ee[row] = panel.n_ee[row] + 1
                    else panel.n_rejected_offers[row] = ///
                        panel.n_rejected_offers[row] + 1
                }
                else panel.n_eu[row] = panel.n_eu[row] + 1
                current_employed = event_kind != 3
                current_firm = history.events[event_row, 7]
                current_spell = history.events[event_row, 8]
                current_tenure = history.events[event_row, 9]
                current_unemployment = history.events[event_row, 10]
                current_time = event_time
                event_row = event_row + 1
            }
            segment = endpoint - current_time
            if (current_employed) {
                panel.employment_exposure[row] = ///
                    panel.employment_exposure[row] + segment
                current_tenure = current_tenure + segment
            }
            else {
                panel.unemployment_exposure[row] = ///
                    panel.unemployment_exposure[row] + segment
                current_unemployment = current_unemployment + segment
            }
            current_time = endpoint
            panel.employed[row] = current_employed
            panel.firm_id[row] = current_firm
            panel.spell_id[row] = current_spell
            panel.tenure[row] = current_tenure
            panel.unemployment_duration[row] = current_unemployment
        }
    }
    if (event_row != history.total_events + 1) {
        _error(430, "BM aggregation did not consume the event ledger")
    }
    panel.ntransitions = panel.n_eu + panel.n_ee + panel.n_ue
    for (worker = 1; worker <= panel.workers; worker++) {
        for (period = 2; period <= periods; period++) {
            row = (worker - 1) * periods + period
            panel.newjob[row] = panel.employed[row] & ///
                (!panel.employed[row - 1] | ///
                panel.firm_id[row] != panel.firm_id[row - 1] | ///
                panel.spell_id[row] != panel.spell_id[row - 1])
            panel.from_unemp[row] = ///
                !panel.employed[row - 1] & panel.employed[row]
            panel.jobtojob[row] = panel.employed[row - 1] & ///
                panel.employed[row] & panel.firm_id[row] != panel.firm_id[row - 1]
        }
        for (period = 1; period < periods; period++) {
            row = (worker - 1) * periods + period
            panel.to_unemp[row] = ///
                panel.employed[row] & !panel.employed[row + 1]
        }
    }
    panel.validated = 0
    fesim_bm_panel_validate(solution, universe, history, panel, tolerance)
    panel.validated = 1
    return(panel)
}

real matrix fesim_bm_flow_report(
    struct fesim_bm_solution scalar solution,
    struct fesim_bm_firms scalar universe,
    struct fesim_bm_panel scalar panel)
{
    real scalar N, row, origin_u, origin_e, observed_ue, observed_eu
    real scalar observed_ee, employed_exposure, unemployed_exposure
    real matrix report

    if (solution.validated != 1 | universe.validated != 1 | ///
        panel.validated != 1) {
        _error(3300, "BM flow report inputs are invalid")
    }
    N = panel.workers * panel.periods
    employed_exposure = sum(panel.employment_exposure)
    unemployed_exposure = sum(panel.unemployment_exposure)
    report = J(4, 4, .)
    report[1, 1] = solution.unemployment_rate
    report[1, 2] = unemployed_exposure / (panel.workers * panel.horizon)
    report[1, 3] = mean(panel.employed :== 0)
    report[2, 1] = solution.lambda_u
    report[3, 1] = solution.delta
    report[4, 1] = universe.finite_job_to_job_rate
    if (unemployed_exposure > 0) {
        report[2, 2] = sum(panel.n_ue) / unemployed_exposure
    }
    if (employed_exposure > 0) {
        report[3, 2] = sum(panel.n_eu) / employed_exposure
        report[4, 2] = sum(panel.n_ee) / employed_exposure
    }
    origin_u = 0
    origin_e = 0
    observed_ue = 0
    observed_eu = 0
    observed_ee = 0
    for (row = 1; row <= N; row++) {
        if (panel.period_index[row] == 1) continue
        if (panel.employed[row - 1]) {
            origin_e = origin_e + 1
            observed_eu = observed_eu + (!panel.employed[row])
            observed_ee = observed_ee + (panel.employed[row] & ///
                panel.firm_id[row] != panel.firm_id[row - 1])
        }
        else {
            origin_u = origin_u + 1
            observed_ue = observed_ue + panel.employed[row]
        }
    }
    if (origin_u > 0) report[2, 3] = observed_ue / origin_u
    if (origin_e > 0) {
        report[3, 3] = observed_eu / origin_e
        report[4, 3] = observed_ee / origin_e
    }
    report[2..4, 4] = report[2..4, 3] / panel.period_length
    return(report)
}

end
