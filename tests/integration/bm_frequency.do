version 16.0
clear all
set more off
set varabbrev off

set rng mt64
set seed 97531
local rng_before `"`c(rngstate)'"'

mata:
void fesim_test_bm_frequency()
{
    struct fesim_bm_solution scalar solution
    struct fesim_bm_firms scalar universe
    struct fesim_bm_state scalar state
    struct fesim_bm_history scalar history
    struct fesim_bm_panel scalar annual, quarterly, monthly
    struct fesim_rng_state scalar rng_state
    real scalar worker, year, annual_row, quarterly_row, monthly_row

    solution = fesim_bm_solve(
        .4, 1, 1, .5, .2, .05, 401, 4000, 1e-10)
    rng_state = fesim_rng_init(13579, 1)
    universe = fesim_bm_construct_firms(
        solution, 20, "quantile", rng_state, 1e-10)
    state = fesim_bm_initialize_state(
        solution, universe, 500, "stationary", rng_state, 1e-10)
    history = fesim_bm_simulate_events(
        solution, universe, state.employed, state.firm_id, ///
        state.spell_id, state.tenure, state.unemployment_duration, ///
        2, 1, 100000, rng_state, 1e-10)
    annual = fesim_bm_aggregate_history(
        solution, universe, history, "year", 2, 1e-10)
    quarterly = fesim_bm_aggregate_history(
        solution, universe, history, "quarter", 8, 1e-10)
    monthly = fesim_bm_aggregate_history(
        solution, universe, history, "month", 24, 1e-10)

    assert(sum(annual.n_events) == history.total_events)
    assert(sum(quarterly.n_events) == history.total_events)
    assert(sum(monthly.n_events) == history.total_events)
    assert(sum(annual.ntransitions) == history.total_transitions)
    assert(sum(quarterly.ntransitions) == history.total_transitions)
    assert(sum(monthly.ntransitions) == history.total_transitions)
    assert(abs(sum(annual.employment_exposure) - ///
        sum(quarterly.employment_exposure)) < 5e-10)
    assert(abs(sum(annual.employment_exposure) - ///
        sum(monthly.employment_exposure)) < 5e-10)
    assert(abs(sum(annual.unemployment_exposure) - ///
        sum(monthly.unemployment_exposure)) < 5e-10)

    for (worker = 1; worker <= 500; worker++) {
        for (year = 1; year <= 2; year++) {
            annual_row = (worker - 1) * 2 + year
            quarterly_row = (worker - 1) * 8 + 4 * year
            monthly_row = (worker - 1) * 24 + 12 * year
            assert(annual.employed[annual_row] == ///
                quarterly.employed[quarterly_row])
            assert(annual.employed[annual_row] == ///
                monthly.employed[monthly_row])
            assert(annual.firm_id[annual_row] == ///
                quarterly.firm_id[quarterly_row])
            assert(annual.firm_id[annual_row] == ///
                monthly.firm_id[monthly_row])
            assert(annual.spell_id[annual_row] == ///
                quarterly.spell_id[quarterly_row])
            assert(annual.spell_id[annual_row] == ///
                monthly.spell_id[monthly_row])
            assert(mreldif(annual.tenure[annual_row], ///
                quarterly.tenure[quarterly_row]) < 1e-12)
            assert(mreldif(annual.tenure[annual_row], ///
                monthly.tenure[monthly_row]) < 1e-12)
            assert(mreldif(annual.unemployment_duration[annual_row], ///
                quarterly.unemployment_duration[quarterly_row]) < 1e-12)
            assert(mreldif(annual.unemployment_duration[annual_row], ///
                monthly.unemployment_duration[monthly_row]) < 1e-12)
        }
    }
}

fesim_test_bm_frequency()
end

assert `"`c(rngstate)'"' == `"`rng_before'"'

di as result "FESIM BM FREQUENCY AGGREGATION TESTS PASS"
