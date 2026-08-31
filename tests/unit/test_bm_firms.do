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
void fesim_test_bm_firms()
{
    struct fesim_bm_solution scalar solution
    struct fesim_bm_firms scalar one, ten, hundred, thousand
    struct fesim_bm_firms scalar random_a, random_b, random_other
    struct fesim_rng_state scalar quantile_rng, random_rng_a
    struct fesim_rng_state scalar random_rng_b, random_rng_other
    struct fesim_rng_state scalar isolation_rng, control_rng
    real scalar firm_stream
    real colvector tie_wage, tie_mass, worker_after, worker_control
    string scalar quantile_firm_state, caller_state

    assert(fesim_mata_api_version() == 31)
    assert(fesim_bm_firms_schema_version() == 1)
    solution = fesim_bm_solve(
        .4, 1, 1, .5, .2, .05, 401, 4000, 1e-10)

    caller_state = rngstate()
    quantile_rng = fesim_rng_init(24680, 1)
    firm_stream = fesim_rng_component_index(quantile_rng, "firm_primitives")
    quantile_firm_state = quantile_rng.component_states[firm_stream]
    one = fesim_bm_construct_firms(
        solution, 1, "quantile", quantile_rng, 1e-10)
    ten = fesim_bm_construct_firms(
        solution, 10, " QUANTILE ", quantile_rng, 1e-10)
    hundred = fesim_bm_construct_firms(
        solution, 100, "quantile", quantile_rng, 1e-10)
    thousand = fesim_bm_construct_firms(
        solution, 1000, "quantile", quantile_rng, 1e-10)
    assert(rngstate() == caller_state)
    assert(quantile_rng.component_states[firm_stream] == quantile_firm_state)

    assert(one.validated == 1 & one.mode == "quantile")
    assert(one.firm_id == 1)
    assert(one.offer_quantile == .5)
    assert(one.minimum_wage_gap == .)
    assert(one.wage_ties == 0)
    assert(abs(one.finite_aggregate_employment - ///
        solution.employment_rate) < 2e-15)
    assert(one.finite_job_to_job_rate == 0)

    assert(ten.firm_id == (1::10))
    assert(ten.offer_quantile == (((1::10) :- .5) / 10))
    assert(min(ten.posted_wage[2..10] :- ten.posted_wage[1..9]) > 0)
    assert(min(ten.expected_employment_mass[2..10] :- ///
        ten.expected_employment_mass[1..9]) > 0)
    assert(all(ten.firm_productivity :== solution.p))
    assert(max(abs(ten.continuum_profit :- ///
        solution.equilibrium_profit)) < 2e-15)
    assert(abs(sum(ten.expected_employment_share) - 1) < 2e-15)
    assert(abs(ten.offer_cdf_error - .05) < 2e-15)
    assert(ten.stationary_residual < 2e-16)
    assert(abs(ten.finite_employment_error) < 2e-15)

    assert(abs(hundred.offer_cdf_error - .005) < 2e-15)
    assert(abs(thousand.offer_cdf_error - .0005) < 2e-15)
    assert(abs(ten.continuum_employment_error) > ///
        abs(hundred.continuum_employment_error))
    assert(abs(hundred.continuum_employment_error) > ///
        abs(thousand.continuum_employment_error))
    assert(ten.worker_cdf_error > hundred.worker_cdf_error)
    assert(hundred.worker_cdf_error > thousand.worker_cdf_error)
    assert(abs(ten.finite_job_to_job_rate - solution.job_to_job_rate) > ///
        abs(hundred.finite_job_to_job_rate - solution.job_to_job_rate))
    assert(abs(hundred.finite_job_to_job_rate - solution.job_to_job_rate) > ///
        abs(thousand.finite_job_to_job_rate - solution.job_to_job_rate))

    random_rng_a = fesim_rng_init(13579, 1)
    random_rng_b = fesim_rng_init(13579, 1)
    random_rng_other = fesim_rng_init(97531, 1)
    random_a = fesim_bm_construct_firms(
        solution, 100, "random", random_rng_a, 1e-10)
    random_b = fesim_bm_construct_firms(
        solution, 100, "random", random_rng_b, 1e-10)
    random_other = fesim_bm_construct_firms(
        solution, 100, "random", random_rng_other, 1e-10)
    assert(random_a.validated == 1 & random_a.mode == "random")
    assert(random_a.offer_quantile == random_b.offer_quantile)
    assert(random_a.posted_wage == random_b.posted_wage)
    assert(random_a.expected_employment_mass == ///
        random_b.expected_employment_mass)
    assert(mreldif(random_a.offer_quantile, ///
        random_other.offer_quantile) > 0)
    assert(min(random_a.offer_quantile[2..100] :- ///
        random_a.offer_quantile[1..99]) >= 0)
    assert(random_a.offer_cdf_error < .2)
    assert(abs(random_a.finite_employment_error) < 2e-15)

    isolation_rng = fesim_rng_init(112233, 1)
    control_rng = fesim_rng_init(112233, 1)
    random_a = fesim_bm_construct_firms(
        solution, 1000, "random", isolation_rng, 1e-10)
    worker_after = fesim_rng_runiform(
        isolation_rng, "worker_primitives", 20, 1)
    worker_control = fesim_rng_runiform(
        control_rng, "worker_primitives", 20, 1)
    assert(worker_after == worker_control)

    tie_wage = fesim_bm_inverse_offer_cdf((.25 \ .25 \ .75), ///
        solution.p, solution.reservation_wage, solution.lambda_e, ///
        solution.delta)
    tie_mass = fesim_bm_expected_mass(solution, tie_wage)
    assert(tie_mass[1] == tie_mass[2])
    assert(tie_mass[3] > tie_mass[2])
    assert(abs(sum(tie_mass) - solution.employment_rate) < 2e-15)
    assert(fesim_bm_stationary_residual(
        solution, tie_wage, tie_mass) < 2e-16)
}

void fesim_test_bm_bad_mode()
{
    struct fesim_bm_solution scalar solution
    struct fesim_bm_firms scalar universe
    struct fesim_rng_state scalar rng_state

    solution = fesim_bm_solve(
        .4, 1, 1, .5, .2, .05, 101, 1000, 1e-10)
    rng_state = fesim_rng_init(1, 1)
    universe = fesim_bm_construct_firms(
        solution, 10, "endpoints", rng_state, 1e-10)
}

void fesim_test_bm_bad_count()
{
    struct fesim_bm_solution scalar solution
    struct fesim_bm_firms scalar universe
    struct fesim_rng_state scalar rng_state

    solution = fesim_bm_solve(
        .4, 1, 1, .5, .2, .05, 101, 1000, 1e-10)
    rng_state = fesim_rng_init(1, 1)
    universe = fesim_bm_construct_firms(
        solution, 0, "quantile", rng_state, 1e-10)
}

void fesim_test_bm_unsorted_wages()
{
    struct fesim_bm_solution scalar solution
    real colvector wage, mass

    solution = fesim_bm_solve(
        .4, 1, 1, .5, .2, .05, 101, 1000, 1e-10)
    wage = fesim_bm_inverse_offer_cdf((.75 \ .25), solution.p, ///
        solution.reservation_wage, solution.lambda_e, solution.delta)
    mass = fesim_bm_expected_mass(solution, wage)
}

fesim_test_bm_firms()
end

capture mata: fesim_test_bm_bad_mode()
assert _rc == 3300
capture mata: fesim_test_bm_bad_count()
assert _rc == 3300
capture mata: fesim_test_bm_unsorted_wages()
assert _rc == 3300

quietly datasignature confirm
assert `"`c(rngstate)'"' == `"`rng_before'"'

di as result "FESIM BM FINITE-FIRM TESTS PASS"
