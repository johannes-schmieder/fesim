version 16.0
clear all
set more off
set varabbrev off

set rng mt64
set seed 24680
local rng_before `"`c(rngstate)'"'

mata:
real colvector fesim_test_bm_empirical_state(
    struct fesim_bm_state scalar state)
{
    real scalar firm
    real colvector probability

    probability = J(state.firms + 1, 1, .)
    probability[1] = mean(state.employed :== 0)
    for (firm = 1; firm <= state.firms; firm++) {
        probability[firm + 1] = mean(state.firm_id :== firm)
    }
    return(probability)
}

void fesim_test_bm_burnin_convergence()
{
    struct fesim_bm_solution scalar solution
    struct fesim_bm_firms scalar universe
    struct fesim_bm_state scalar state, all_20, all_40, random_20
    struct fesim_rng_state scalar rng_20, rng_40, rng_random
    real colvector target, empirical_20, empirical_40, empirical_random

    solution = fesim_bm_solve(
        .4, 1, 1, .5, .2, .05, 401, 4000, 1e-10)
    rng_20 = fesim_rng_init(13579, 1)
    universe = fesim_bm_construct_firms(
        solution, 20, "quantile", rng_20, 1e-10)
    target = fesim_bm_stationary_probs(solution, universe)
    state = fesim_bm_initialize_state(
        solution, universe, 20000, "allunemployed", rng_20, 1e-10)
    all_20 = fesim_bm_burn_in(
        solution, universe, state, 20, 2000000, rng_20, 1e-10)
    empirical_20 = fesim_test_bm_empirical_state(all_20)

    rng_40 = fesim_rng_init(13579, 1)
    universe = fesim_bm_construct_firms(
        solution, 20, "quantile", rng_40, 1e-10)
    state = fesim_bm_initialize_state(
        solution, universe, 20000, "allunemployed", rng_40, 1e-10)
    all_40 = fesim_bm_burn_in(
        solution, universe, state, 40, 2000000, rng_40, 1e-10)
    empirical_40 = fesim_test_bm_empirical_state(all_40)

    rng_random = fesim_rng_init(97531, 1)
    universe = fesim_bm_construct_firms(
        solution, 20, "quantile", rng_random, 1e-10)
    state = fesim_bm_initialize_state(
        solution, universe, 20000, "random", rng_random, 1e-10)
    random_20 = fesim_bm_burn_in(
        solution, universe, state, 20, 2000000, rng_random, 1e-10)
    empirical_random = fesim_test_bm_empirical_state(random_20)

    assert(abs(empirical_20[1] - solution.unemployment_rate) < .012)
    assert(abs(empirical_40[1] - solution.unemployment_rate) < .012)
    assert(abs(empirical_random[1] - solution.unemployment_rate) < .012)
    assert(max(abs(empirical_20 :- target)) < .012)
    assert(max(abs(empirical_40 :- target)) < .012)
    assert(max(abs(empirical_random :- target)) < .012)
    assert(max(abs(empirical_20 :- empirical_40)) < .018)
    assert(all_20.elapsed_time == 20 & all_40.elapsed_time == 40)
    assert(random_20.elapsed_time == 20)
    assert(all_20.ntransitions == J(20000, 1, 0))
    assert(random_20.ntransitions == J(20000, 1, 0))
}

fesim_test_bm_burnin_convergence()
end

assert `"`c(rngstate)'"' == `"`rng_before'"'

di as result "FESIM BM BURN-IN CONVERGENCE TESTS PASS"
