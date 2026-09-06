version 16.0
clear all
set more off
set varabbrev off

set rng mt64
set seed 86420
set obs 3
generate double original = _n / 10
quietly datasignature set, reset
local rng_before `"`c(rngstate)'"'

mata:
void fesim_test_bm_aggregation()
{
    struct fesim_bm_solution scalar solution
    struct fesim_bm_firms scalar universe
    struct fesim_bm_history scalar history
    struct fesim_bm_panel scalar panel
    struct fesim_rng_state scalar rng_state
    real colvector employed, firm_id, spell_id, tenure, unemployment
    real matrix report

    assert(fesim_mata_api_version() == 34)
    assert(fesim_bm_panel_schema_version() == 1)
    assert(fesim_bm_flow_row_names() == ///
        ("unemployment_share", "ue", "eu", "ee"))
    assert(fesim_bm_flow_column_names() == ///
        ("theory", "event", "observed", "observed_per_year"))
    assert(fesim_bm_interval_index(.25, .25, 8, 1e-10) == 1)
    assert(fesim_bm_interval_index(.2500001, .25, 8, 1e-10) == 2)
    assert(fesim_bm_interval_index(2, .25, 8, 1e-10) == 8)

    solution = fesim_bm_solve(
        .4, 1, 1, .5, .2, .05, 401, 4000, 1e-10)
    rng_state = fesim_rng_init(24680, 1)
    universe = fesim_bm_construct_firms(
        solution, 5, "quantile", rng_state, 1e-10)
    employed = (0 \ 1 \ 1)
    firm_id = (0 \ 1 \ 5)
    spell_id = (0 \ 1 \ 2)
    tenure = (. \ .25 \ 1)
    unemployment = (.5 \ . \ .)
    history = fesim_bm_simulate_events(solution, universe, employed, ///
        firm_id, spell_id, tenure, unemployment, 2, 1, 1000, ///
        rng_state, 1e-10)
    panel = fesim_bm_aggregate_history(
        solution, universe, history, " YEAR ", 2, 1e-10)

    assert(panel.validated == 1 & panel.status == "aggregated")
    assert(panel.frequency == "year" & panel.period_length == 1)
    assert(panel.workers == 3 & panel.periods == 2 & panel.horizon == 2)
    assert(panel.worker_id == (1 \ 1 \ 2 \ 2 \ 3 \ 3))
    assert(panel.period_index == (1 \ 2 \ 1 \ 2 \ 1 \ 2))
    assert(panel.employed == J(6, 1, 1))
    assert(panel.firm_id == (4 \ 4 \ 5 \ 5 \ 5 \ 5))
    assert(panel.spell_id == (1 \ 1 \ 2 \ 3 \ 2 \ 2))
    assert(max(abs(panel.tenure :- ///
        (.2022763730 \ 1.202276373 \ .8194120785 \ ///
        .3753321401 \ 2 \ 3))) < 5e-10)
    assert(all(missing(panel.unemployment_duration)))
    assert(panel.n_ue == (1 \ 0 \ 0 \ 1 \ 0 \ 0))
    assert(panel.n_ee == (0 \ 0 \ 1 \ 0 \ 0 \ 0))
    assert(panel.n_eu == (0 \ 0 \ 0 \ 1 \ 0 \ 0))
    assert(panel.n_rejected_offers == (0 \ 0 \ 0 \ 0 \ 1 \ 1))
    assert(panel.n_events == (1 \ 0 \ 1 \ 2 \ 1 \ 1))
    assert(panel.ntransitions == (1 \ 0 \ 1 \ 2 \ 0 \ 0))
    assert(max(abs(panel.unemployment_exposure :- ///
        (.7977236270 \ 0 \ 0 \ .2828066150 \ 0 \ 0))) < 5e-10)
    assert(max(abs(panel.employment_exposure :- ///
        (.2022763730 \ 1 \ 1 \ .7171933850 \ 1 \ 1))) < 5e-10)
    assert(missing(panel.newjob[1]) & panel.newjob[2] == 0)
    assert(missing(panel.newjob[3]) & panel.newjob[4] == 1)
    assert(missing(panel.newjob[5]) & panel.newjob[6] == 0)
    assert(panel.from_unemp[(2, 4, 6)] == (0 \ 0 \ 0))
    assert(panel.jobtojob[(2, 4, 6)] == (0 \ 0 \ 0))
    assert(panel.to_unemp[(1, 3, 5)] == (0 \ 0 \ 0))
    assert(all(missing(panel.to_unemp[(2, 4, 6)])))

    report = fesim_bm_flow_report(solution, universe, panel)
    assert(report[1, 1] == solution.unemployment_rate)
    assert(abs(report[1, 2] - ///
        sum(panel.unemployment_exposure) / 6) < 2e-15)
    assert(report[1, 3] == 0 & missing(report[1, 4]))
    assert(abs(report[2, 2] - ///
        2 / sum(panel.unemployment_exposure)) < 2e-15)
    assert(abs(report[3, 2] - ///
        1 / sum(panel.employment_exposure)) < 2e-15)
    assert(abs(report[4, 2] - ///
        1 / sum(panel.employment_exposure)) < 2e-15)
    assert(missing(report[2, 3]) & missing(report[2, 4]))
    assert(report[3, 3] == 0 & report[3, 4] == 0)
    assert(report[4, 3] == 0 & report[4, 4] == 0)
}

void fesim_test_bm_bad_unrecorded()
{
    struct fesim_bm_solution scalar solution
    struct fesim_bm_firms scalar universe
    struct fesim_bm_history scalar history
    struct fesim_bm_panel scalar panel
    struct fesim_rng_state scalar rng_state

    solution = fesim_bm_solve(
        .4, 1, 1, .5, .2, .05, 101, 1000, 1e-10)
    rng_state = fesim_rng_init(1, 1)
    universe = fesim_bm_construct_firms(
        solution, 3, "quantile", rng_state, 1e-10)
    history = fesim_bm_simulate_events(
        solution, universe, (0), (0), (0), (.), (0), ///
        1, 0, 100, rng_state, 1e-10)
    panel = fesim_bm_aggregate_history(
        solution, universe, history, "year", 1, 1e-10)
}

void fesim_test_bm_aggregate_horizon()
{
    struct fesim_bm_solution scalar solution
    struct fesim_bm_firms scalar universe
    struct fesim_bm_history scalar history
    struct fesim_bm_panel scalar panel
    struct fesim_rng_state scalar rng_state

    solution = fesim_bm_solve(
        .4, 1, 1, .5, .2, .05, 101, 1000, 1e-10)
    rng_state = fesim_rng_init(1, 1)
    universe = fesim_bm_construct_firms(
        solution, 3, "quantile", rng_state, 1e-10)
    history = fesim_bm_simulate_events(
        solution, universe, (0), (0), (0), (.), (0), ///
        1, 1, 100, rng_state, 1e-10)
    panel = fesim_bm_aggregate_history(
        solution, universe, history, "quarter", 3, 1e-10)
}

void fesim_test_bm_aggregate_corrupt()
{
    struct fesim_bm_solution scalar solution
    struct fesim_bm_firms scalar universe
    struct fesim_bm_history scalar history
    struct fesim_bm_panel scalar panel
    struct fesim_rng_state scalar rng_state

    solution = fesim_bm_solve(
        .4, 1, 1, .5, .2, .05, 101, 1000, 1e-10)
    rng_state = fesim_rng_init(1, 1)
    universe = fesim_bm_construct_firms(
        solution, 3, "quantile", rng_state, 1e-10)
    history = fesim_bm_simulate_events(
        solution, universe, (0), (0), (0), (.), (0), ///
        1, 1, 100, rng_state, 1e-10)
    panel = fesim_bm_aggregate_history(
        solution, universe, history, "year", 1, 1e-10)
    panel.n_events[1] = panel.n_events[1] + 1
    fesim_bm_panel_validate(solution, universe, history, panel, 1e-10)
}

fesim_test_bm_aggregation()
end

capture mata: fesim_bm_interval_index(0, 1, 2, 1e-10)
assert _rc == 3300
capture mata: fesim_test_bm_bad_unrecorded()
assert _rc == 3300
capture mata: fesim_test_bm_aggregate_horizon()
assert _rc == 3300
capture mata: fesim_test_bm_aggregate_corrupt()
assert _rc == 430

quietly datasignature confirm
assert `"`c(rngstate)'"' == `"`rng_before'"'

di as result "FESIM BM OBSERVATION AGGREGATION TESTS PASS"
