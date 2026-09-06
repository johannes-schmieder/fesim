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
void fesim_test_bm_events()
{
    struct fesim_bm_solution scalar solution
    struct fesim_bm_firms scalar universe
    struct fesim_bm_history scalar history, repeat, unrecorded, zero
    struct fesim_rng_state scalar rng_state, repeat_rng, unrecorded_rng
    struct fesim_rng_state scalar zero_rng, isolation_rng, control_rng
    real scalar mobility_stream, destination_stream, threshold
    real colvector employed, firm_id, spell_id, tenure, unemployment
    real colvector wage, worker_after, worker_control
    string scalar zero_mobility_state, zero_destination_state

    assert(fesim_mata_api_version() == 35)
    assert(fesim_bm_history_schema_version() == 1)
    assert(fesim_bm_event_column_names() == ///
        ("worker_id", "event_time", "event_kind", "accepted", ///
        "origin_firm", "offered_firm", "destination_firm", ///
        "spell_id_after", "tenure_after", ///
        "unemployment_duration_after", "waiting_time"))

    assert(fesim_bm_open_uniform(0) > 0)
    assert(fesim_bm_open_uniform(1) < 1)
    assert(fesim_bm_open_uniform(.25) == .25)
    assert(abs(fesim_bm_exponential_wait(1 - exp(-.7 * 2), .7) - 2) < 1e-14)
    assert(fesim_bm_exponential_wait(0, 1) > 0)
    threshold = .2 / (.2 + .5)
    assert(fesim_bm_event_kind(0, .9, .5, .2) == 1)
    assert(fesim_bm_event_kind(1, 0, .5, .2) == 3)
    assert(fesim_bm_event_kind(1, threshold, .5, .2) == 2)
    assert(fesim_bm_event_kind(1, 1, .5, .2) == 2)
    wage = (1 \ 1 \ 2)
    assert(fesim_bm_offer_accept(0, 0, 1, wage) == 1)
    assert(fesim_bm_offer_accept(1, 1, 1, wage) == 0)
    assert(fesim_bm_offer_accept(1, 1, 2, wage) == 0)
    assert(fesim_bm_offer_accept(1, 2, 1, wage) == 0)
    assert(fesim_bm_offer_accept(1, 1, 3, wage) == 1)

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
    assert(history.validated == 1)
    assert((history.total_events, history.unemployment_offers, ///
        history.employed_offers, history.destructions, ///
        history.accepted_entries, history.accepted_moves, ///
        history.rejected_offers, history.total_transitions) == ///
        (6, 2, 3, 1, 2, 1, 2, 4))
    assert(history.events[, (1, 3, 4, 5, 6, 7, 8)] == ///
        (1, 1, 1, 0, 4, 4, 1 \
         2, 2, 1, 1, 5, 5, 2 \
         2, 3, 0, 5, 0, 0, 2 \
         2, 1, 1, 0, 5, 5, 3 \
         3, 2, 0, 5, 1, 5, 2 \
         3, 2, 0, 5, 1, 5, 2))
    assert(max(abs(history.events[, 2] :- ///
        (.7977236270 \ .1805879215 \ 1.341861245 \ ///
         1.624667860 \ .3403776210 \ 1.977398078))) < 5e-10)
    assert(history.final_employed == (1 \ 1 \ 1))
    assert(history.final_firm_id == (4 \ 5 \ 5))
    assert(history.final_spell_id == (1 \ 3 \ 2))
    assert(history.final_transitions == (1 \ 3 \ 0))
    assert(max(abs(history.final_tenure :- ///
        (1.202276373 \ .3753321401 \ 3))) < 5e-10)
    assert(all(missing(history.final_unemployment_duration)))

    repeat_rng = fesim_rng_init(24680, 1)
    universe = fesim_bm_construct_firms(
        solution, 5, "quantile", repeat_rng, 1e-10)
    repeat = fesim_bm_simulate_events(solution, universe, employed, ///
        firm_id, spell_id, tenure, unemployment, 2, 1, 1000, ///
        repeat_rng, 1e-10)
    assert(history.events == repeat.events)
    assert(history.final_employed == repeat.final_employed)
    assert(history.final_firm_id == repeat.final_firm_id)
    assert(history.final_spell_id == repeat.final_spell_id)
    assert(history.final_tenure == repeat.final_tenure)

    unrecorded_rng = fesim_rng_init(24680, 1)
    universe = fesim_bm_construct_firms(
        solution, 5, "quantile", unrecorded_rng, 1e-10)
    unrecorded = fesim_bm_simulate_events(solution, universe, employed, ///
        firm_id, spell_id, tenure, unemployment, 2, 0, 1000, ///
        unrecorded_rng, 1e-10)
    assert(rows(unrecorded.events) == 0 & cols(unrecorded.events) == 11)
    assert(history.final_employed == unrecorded.final_employed)
    assert(history.final_firm_id == unrecorded.final_firm_id)
    assert(history.final_spell_id == unrecorded.final_spell_id)
    assert(history.final_tenure == unrecorded.final_tenure)
    assert(history.total_events == unrecorded.total_events)
    assert(rng_state.component_states == unrecorded_rng.component_states)

    zero_rng = fesim_rng_init(13579, 1)
    universe = fesim_bm_construct_firms(
        solution, 5, "quantile", zero_rng, 1e-10)
    mobility_stream = fesim_rng_component_index(zero_rng, "mobility_events")
    destination_stream = fesim_rng_component_index(
        zero_rng, "destination_draws")
    zero_mobility_state = zero_rng.component_states[mobility_stream]
    zero_destination_state = zero_rng.component_states[destination_stream]
    zero = fesim_bm_simulate_events(solution, universe, employed, ///
        firm_id, spell_id, tenure, unemployment, 0, 1, 1000, ///
        zero_rng, 1e-10)
    assert(zero.total_events == 0)
    assert(zero.final_employed == employed)
    assert(zero.final_firm_id == firm_id)
    assert(zero.final_spell_id == spell_id)
    assert(zero.final_tenure == tenure)
    assert(zero.final_unemployment_duration == unemployment)
    assert(zero_rng.component_states[mobility_stream] == zero_mobility_state)
    assert(zero_rng.component_states[destination_stream] == ///
        zero_destination_state)

    isolation_rng = fesim_rng_init(112233, 1)
    control_rng = fesim_rng_init(112233, 1)
    universe = fesim_bm_construct_firms(
        solution, 5, "quantile", isolation_rng, 1e-10)
    unrecorded = fesim_bm_simulate_events(solution, universe, employed, ///
        firm_id, spell_id, tenure, unemployment, 5, 0, 1000, ///
        isolation_rng, 1e-10)
    worker_after = fesim_rng_runiform(
        isolation_rng, "worker_primitives", 20, 1)
    worker_control = fesim_rng_runiform(
        control_rng, "worker_primitives", 20, 1)
    assert(worker_after == worker_control)
}

void fesim_test_bm_event_bad_state()
{
    struct fesim_bm_solution scalar solution
    struct fesim_bm_firms scalar universe
    struct fesim_bm_history scalar history
    struct fesim_rng_state scalar rng_state

    solution = fesim_bm_solve(
        .4, 1, 1, .5, .2, .05, 101, 1000, 1e-10)
    rng_state = fesim_rng_init(1, 1)
    universe = fesim_bm_construct_firms(
        solution, 3, "quantile", rng_state, 1e-10)
    history = fesim_bm_simulate_events(solution, universe, (1), (0), ///
        (1), (0), (.), 1, 1, 100, rng_state, 1e-10)
}

void fesim_test_bm_event_limit()
{
    struct fesim_bm_solution scalar solution
    struct fesim_bm_firms scalar universe
    struct fesim_bm_history scalar history
    struct fesim_rng_state scalar rng_state

    solution = fesim_bm_solve(
        .4, 1, 1, .5, .2, .05, 101, 1000, 1e-10)
    rng_state = fesim_rng_init(1, 1)
    universe = fesim_bm_construct_firms(
        solution, 3, "quantile", rng_state, 1e-10)
    history = fesim_bm_simulate_events(solution, universe, (0 \ 0 \ 0), ///
        (0 \ 0 \ 0), (0 \ 0 \ 0), (. \ . \ .), ///
        (0 \ 0 \ 0), 100, 1, 1, rng_state, 1e-10)
}

void fesim_test_bm_event_corruption()
{
    struct fesim_bm_solution scalar solution
    struct fesim_bm_firms scalar universe
    struct fesim_bm_history scalar history
    struct fesim_rng_state scalar rng_state

    solution = fesim_bm_solve(
        .4, 1, 1, .5, .2, .05, 101, 1000, 1e-10)
    rng_state = fesim_rng_init(24680, 1)
    universe = fesim_bm_construct_firms(
        solution, 5, "quantile", rng_state, 1e-10)
    history = fesim_bm_simulate_events(solution, universe, (0), (0), ///
        (0), (.), (0), 5, 1, 100, rng_state, 1e-10)
    history.events[1, 7] = universe.firms + 1
    fesim_bm_history_validate(solution, universe, history, 1e-10)
}

fesim_test_bm_events()
end

capture mata: fesim_bm_open_uniform(-.1)
assert _rc == 3300
capture mata: fesim_bm_exponential_wait(.5, 0)
assert _rc == 3300
capture mata: fesim_test_bm_event_bad_state()
assert _rc == 3300
capture mata: fesim_test_bm_event_limit()
assert _rc == 430
capture mata: fesim_test_bm_event_corruption()
assert _rc == 430

quietly datasignature confirm
assert `"`c(rngstate)'"' == `"`rng_before'"'

di as result "FESIM BM CONTINUOUS-TIME EVENT TESTS PASS"
