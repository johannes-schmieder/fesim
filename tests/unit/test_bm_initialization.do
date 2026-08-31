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
void fesim_test_bm_initialization()
{
    struct fesim_bm_solution scalar solution
    struct fesim_bm_firms scalar universe
    struct fesim_bm_state scalar stationary, repeat, random, all_u
    struct fesim_bm_state scalar burned, burned_repeat, advanced
    struct fesim_bm_history scalar history
    struct fesim_rng_state scalar rng_state, repeat_rng, random_rng
    struct fesim_rng_state scalar all_u_rng, burn_rng, burn_repeat_rng
    struct fesim_rng_state scalar isolation_rng, control_rng
    real scalar firm, initial_stream, worker
    real colvector probability, exit_rate, empirical, scaled_age
    real colvector worker_after, worker_control
    string scalar initial_state_before

    assert(fesim_mata_api_version() == 30)
    assert(fesim_bm_state_schema_version() == 1)
    solution = fesim_bm_solve(
        .4, 1, 1, .5, .2, .05, 401, 4000, 1e-10)
    rng_state = fesim_rng_init(24680, 1)
    universe = fesim_bm_construct_firms(
        solution, 5, "quantile", rng_state, 1e-10)

    probability = fesim_bm_stationary_probs(solution, universe)
    exit_rate = fesim_bm_stationary_exit_rates(solution, universe)
    assert(rows(probability) == 6 & rows(exit_rate) == 6)
    assert(abs(sum(probability) - 1) < 2e-15)
    assert(abs(probability[1] - solution.unemployment_rate) < 2e-15)
    assert(max(abs(probability[2..6] :- ///
        universe.expected_employment_mass)) < 2e-15)
    assert(exit_rate[1] == solution.lambda_u)
    assert(max(abs(exit_rate[2..6] :- ///
        (solution.delta :+ solution.lambda_e :* ((4::0) / 5)))) < 2e-15)

    stationary = fesim_bm_initialize_state(
        solution, universe, 100000, " STATIONARY ", rng_state, 1e-10)
    assert(stationary.validated == 1 & stationary.status == "initialized")
    assert(stationary.initial_mode == "stationary")
    assert(stationary.workers == 100000 & stationary.firms == 5)
    assert(stationary.elapsed_time == 0)
    assert(stationary.spell_id == stationary.employed)
    assert(stationary.ntransitions == J(100000, 1, 0))
    empirical = J(6, 1, .)
    empirical[1] = mean(stationary.employed :== 0)
    for (firm = 1; firm <= 5; firm++) {
        empirical[firm + 1] = mean(stationary.firm_id :== firm)
    }
    assert(max(abs(empirical :- probability)) < .006)
    scaled_age = J(stationary.workers, 1, .)
    for (worker = 1; worker <= stationary.workers; worker++) {
        if (stationary.employed[worker]) {
            scaled_age[worker] = stationary.tenure[worker] * ///
                exit_rate[stationary.firm_id[worker] + 1]
            assert(missing(stationary.unemployment_duration[worker]))
        }
        else {
            scaled_age[worker] = ///
                stationary.unemployment_duration[worker] * exit_rate[1]
            assert(missing(stationary.tenure[worker]))
        }
    }
    assert(abs(mean(scaled_age) - 1) < .015)

    repeat_rng = fesim_rng_init(24680, 1)
    universe = fesim_bm_construct_firms(
        solution, 5, "quantile", repeat_rng, 1e-10)
    repeat = fesim_bm_initialize_state(
        solution, universe, 100000, "stationary", repeat_rng, 1e-10)
    assert(stationary.employed == repeat.employed)
    assert(stationary.firm_id == repeat.firm_id)
    assert(stationary.tenure == repeat.tenure)
    assert(stationary.unemployment_duration == ///
        repeat.unemployment_duration)
    assert(rng_state.component_states == repeat_rng.component_states)

    random_rng = fesim_rng_init(97531, 1)
    universe = fesim_bm_construct_firms(
        solution, 5, "quantile", random_rng, 1e-10)
    random = fesim_bm_initialize_state(
        solution, universe, 100000, "random", random_rng, 1e-10)
    assert(abs(mean(random.employed) - .5) < .006)
    for (firm = 1; firm <= 5; firm++) {
        assert(abs(mean(random.firm_id :== firm) - .1) < .006)
    }
    assert(all(select(random.tenure, random.employed) :== 0))
    assert(all(select(random.unemployment_duration, !random.employed) :== 0))

    all_u_rng = fesim_rng_init(13579, 1)
    universe = fesim_bm_construct_firms(
        solution, 5, "quantile", all_u_rng, 1e-10)
    initial_stream = fesim_rng_component_index(all_u_rng, "initial_states")
    initial_state_before = all_u_rng.component_states[initial_stream]
    all_u = fesim_bm_initialize_state(
        solution, universe, 20, "allunemployed", all_u_rng, 1e-10)
    assert(all_u.employed == J(20, 1, 0))
    assert(all_u.firm_id == J(20, 1, 0))
    assert(all_u.spell_id == J(20, 1, 0))
    assert(all(missing(all_u.tenure)))
    assert(all_u.unemployment_duration == J(20, 1, 0))
    assert(all_u_rng.component_states[initial_stream] == initial_state_before)

    burn_rng = fesim_rng_init(112233, 1)
    universe = fesim_bm_construct_firms(
        solution, 5, "quantile", burn_rng, 1e-10)
    random = fesim_bm_initialize_state(
        solution, universe, 200, "random", burn_rng, 1e-10)
    burned = fesim_bm_burn_in(
        solution, universe, random, 2, 10000, burn_rng, 1e-10)
    assert(burned.validated == 1 & burned.status == "burned_in")
    assert(burned.initial_mode == "random" & burned.elapsed_time == 2)
    assert(burned.ntransitions == J(200, 1, 0))

    burn_repeat_rng = fesim_rng_init(112233, 1)
    universe = fesim_bm_construct_firms(
        solution, 5, "quantile", burn_repeat_rng, 1e-10)
    random = fesim_bm_initialize_state(
        solution, universe, 200, "random", burn_repeat_rng, 1e-10)
    burned_repeat = fesim_bm_burn_in(
        solution, universe, random, 2, 10000, burn_repeat_rng, 1e-10)
    assert(burned.employed == burned_repeat.employed)
    assert(burned.firm_id == burned_repeat.firm_id)
    assert(burned.spell_id == burned_repeat.spell_id)
    assert(burned.tenure == burned_repeat.tenure)
    assert(burned.unemployment_duration == ///
        burned_repeat.unemployment_duration)
    assert(burn_rng.component_states == burn_repeat_rng.component_states)

    history = fesim_bm_simulate_events(
        solution, universe, burned.employed, burned.firm_id, ///
        burned.spell_id, burned.tenure, burned.unemployment_duration, ///
        1, 0, 10000, burn_rng, 1e-10)
    advanced = fesim_bm_state_from_history(
        universe, burned, history, "advanced", 0, 1e-10)
    assert(advanced.status == "advanced" & advanced.elapsed_time == 3)
    assert(advanced.ntransitions == history.final_transitions)

    isolation_rng = fesim_rng_init(998877, 1)
    control_rng = fesim_rng_init(998877, 1)
    universe = fesim_bm_construct_firms(
        solution, 5, "quantile", isolation_rng, 1e-10)
    stationary = fesim_bm_initialize_state(
        solution, universe, 1000, "stationary", isolation_rng, 1e-10)
    history = fesim_bm_simulate_events(
        solution, universe, stationary.employed, stationary.firm_id, ///
        stationary.spell_id, stationary.tenure, ///
        stationary.unemployment_duration, 1, 0, 10000, ///
        isolation_rng, 1e-10)
    worker_after = fesim_rng_runiform(
        isolation_rng, "worker_primitives", 20, 1)
    worker_control = fesim_rng_runiform(
        control_rng, "worker_primitives", 20, 1)
    assert(worker_after == worker_control)
}

void fesim_test_bm_initial_bad_mode()
{
    struct fesim_bm_solution scalar solution
    struct fesim_bm_firms scalar universe
    struct fesim_bm_state scalar state
    struct fesim_rng_state scalar rng_state

    solution = fesim_bm_solve(
        .4, 1, 1, .5, .2, .05, 101, 1000, 1e-10)
    rng_state = fesim_rng_init(1, 1)
    universe = fesim_bm_construct_firms(
        solution, 3, "quantile", rng_state, 1e-10)
    state = fesim_bm_initialize_state(
        solution, universe, 10, "empirical", rng_state, 1e-10)
}

void fesim_test_bm_random_zero_burnin()
{
    struct fesim_bm_solution scalar solution
    struct fesim_bm_firms scalar universe
    struct fesim_bm_state scalar state
    struct fesim_rng_state scalar rng_state

    solution = fesim_bm_solve(
        .4, 1, 1, .5, .2, .05, 101, 1000, 1e-10)
    rng_state = fesim_rng_init(1, 1)
    universe = fesim_bm_construct_firms(
        solution, 3, "quantile", rng_state, 1e-10)
    state = fesim_bm_initialize_state(
        solution, universe, 10, "random", rng_state, 1e-10)
    state = fesim_bm_burn_in(
        solution, universe, state, 0, 100, rng_state, 1e-10)
}

void fesim_test_bm_corrupt_state()
{
    struct fesim_bm_solution scalar solution
    struct fesim_bm_firms scalar universe
    struct fesim_bm_state scalar state
    struct fesim_rng_state scalar rng_state

    solution = fesim_bm_solve(
        .4, 1, 1, .5, .2, .05, 101, 1000, 1e-10)
    rng_state = fesim_rng_init(1, 1)
    universe = fesim_bm_construct_firms(
        solution, 3, "quantile", rng_state, 1e-10)
    state = fesim_bm_initialize_state(
        solution, universe, 10, "allunemployed", rng_state, 1e-10)
    state.firm_id[1] = 1
    fesim_bm_state_validate(universe, state)
}

void fesim_test_bm_history_boundary()
{
    struct fesim_bm_solution scalar solution
    struct fesim_bm_firms scalar universe
    struct fesim_bm_state scalar state
    struct fesim_bm_history scalar history
    struct fesim_rng_state scalar rng_state

    solution = fesim_bm_solve(
        .4, 1, 1, .5, .2, .05, 101, 1000, 1e-10)
    rng_state = fesim_rng_init(1, 1)
    universe = fesim_bm_construct_firms(
        solution, 3, "quantile", rng_state, 1e-10)
    state = fesim_bm_initialize_state(
        solution, universe, 10, "allunemployed", rng_state, 1e-10)
    history = fesim_bm_simulate_events(
        solution, universe, state.employed, state.firm_id, state.spell_id, ///
        state.tenure, state.unemployment_duration, 1, 0, 100, ///
        rng_state, 1e-10)
    state.unemployment_duration[1] = 1
    state = fesim_bm_state_from_history(
        universe, state, history, "advanced", 0, 1e-10)
}

void fesim_test_bm_bad_pair()
{
    struct fesim_bm_solution scalar solution, other_solution
    struct fesim_bm_firms scalar universe
    struct fesim_bm_state scalar state
    struct fesim_rng_state scalar rng_state

    solution = fesim_bm_solve(
        .4, 1, 1, .5, .2, .05, 101, 1000, 1e-10)
    other_solution = fesim_bm_solve(
        .4, 1.2, 1, .5, .2, .05, 101, 1000, 1e-10)
    rng_state = fesim_rng_init(1, 1)
    universe = fesim_bm_construct_firms(
        solution, 3, "quantile", rng_state, 1e-10)
    state = fesim_bm_initialize_state(
        other_solution, universe, 10, "stationary", rng_state, 1e-10)
}

fesim_test_bm_initialization()
end

capture mata: fesim_test_bm_initial_bad_mode()
assert _rc == 3300
capture mata: fesim_test_bm_random_zero_burnin()
assert _rc == 3300
capture mata: fesim_test_bm_corrupt_state()
assert _rc == 3300
capture mata: fesim_test_bm_history_boundary()
assert _rc == 3300
capture mata: fesim_test_bm_bad_pair()
assert _rc == 430

quietly datasignature confirm
assert `"`c(rngstate)'"' == `"`rng_before'"'

di as result "FESIM BM INITIALIZATION TESTS PASS"
