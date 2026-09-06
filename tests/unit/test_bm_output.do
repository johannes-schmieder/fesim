version 16.0
clear all
set more off
set varabbrev off

set rng mt64
set seed 24680
set obs 4
generate double original = _n / 7
quietly datasignature set, reset
local rng_before `"`c(rngstate)'"'

mata:
void fesim_test_bm_output_truth()
{
    struct fesim_bm_solution scalar solution
    struct fesim_bm_solution scalar small_solution
    struct fesim_bm_firms scalar universe
    struct fesim_rng_state scalar rng_state
    real scalar surplus, unemployment_value
    real colvector wage, employment_value, solver
    real matrix firms

    assert(fesim_mata_api_version() == 36)
    assert(fesim_bm_output_schema_version() == 1)
    assert(cols(fesim_bm_solver_diagnostic_names()) == 22)
    assert(cols(fesim_bm_firm_diagnostic_names()) == 10)
    assert(fesim_bm_firm_diagnostic_names() == ///
        ("firm_id", "offer_quantile", "posted_wage", ///
        "expected_mass", "expected_workers", "expected_share", ///
        "continuum_employment", "finite_scaled_employment", ///
        "continuum_profit", "finite_scaled_profit"))

    solution = fesim_bm_solve(
        .4, 1, 1, .5, .2, .05, 401, 4000, 1e-10)
    rng_state = fesim_rng_init(13579, 1)
    universe = fesim_bm_construct_firms(
        solution, 5, "quantile", rng_state, 1e-10)
    surplus = solution.surplus_coefficient * ///
        (solution.p - solution.reservation_wage)
    unemployment_value = fesim_bm_unemployment_value(solution)
    assert(abs(solution.discount * unemployment_value - ///
        (solution.b + solution.lambda_u * surplus)) < 5e-14)
    assert(abs(solution.discount * unemployment_value - ///
        (solution.reservation_wage + solution.lambda_e * surplus)) < 5e-14)

    wage = (solution.reservation_wage \ universe.posted_wage \ ///
        solution.upper_wage)
    employment_value = fesim_bm_employment_value(solution, wage)
    assert(abs(employment_value[1] - unemployment_value) < 5e-14)
    assert(min(employment_value[2..rows(employment_value)] :- ///
        employment_value[1..(rows(employment_value) - 1)]) > 0)
    small_solution = fesim_bm_solve(
        .4, 1, 1, 1e-8, .2, .05, 101, 1000, 1e-10)
    employment_value = fesim_bm_employment_value(small_solution, ///
        (small_solution.reservation_wage \ small_solution.upper_wage))
    assert(!any(missing(employment_value)))
    assert(abs(employment_value[1] - ///
        fesim_bm_unemployment_value(small_solution)) < 5e-14)
    assert(employment_value[2] > employment_value[1])

    solver = fesim_bm_solver_diagnostics(solution, universe)
    assert(rows(solver) == 22 & cols(solver) == 1)
    assert(solver[8] == solution.reservation_wage)
    assert(solver[13] == universe.finite_job_to_job_rate)
    assert(solver[15] == unemployment_value)
    assert(solver[19] == universe.stationary_residual)

    firms = fesim_bm_firm_diagnostics(solution, universe, 1000)
    assert(rows(firms) == 5 & cols(firms) == 10)
    assert(firms[, 1] == universe.firm_id)
    assert(firms[, 4] == universe.expected_employment_mass)
    assert(firms[, 5] == 1000 :* universe.expected_employment_mass)
    assert(firms[, 6] == universe.expected_employment_share)
    assert(firms[, 9] == universe.continuum_profit)
    assert(max(abs(firms[, 9] :- solution.equilibrium_profit)) < 5e-14)
    assert(firms[, 10] == universe.finite_scaled_profit)
}

void fesim_test_bm_output_bad_wage()
{
    struct fesim_bm_solution scalar solution
    real colvector value

    solution = fesim_bm_solve(
        .4, 1, 1, .5, .2, .05, 101, 1000, 1e-10)
    value = fesim_bm_employment_value(
        solution, solution.reservation_wage - .01)
}

void fesim_test_bm_output_bad_workers()
{
    struct fesim_bm_solution scalar solution
    struct fesim_bm_firms scalar universe
    struct fesim_rng_state scalar rng_state
    real matrix firms

    solution = fesim_bm_solve(
        .4, 1, 1, .5, .2, .05, 101, 1000, 1e-10)
    rng_state = fesim_rng_init(1, 1)
    universe = fesim_bm_construct_firms(
        solution, 3, "quantile", rng_state, 1e-10)
    firms = fesim_bm_firm_diagnostics(solution, universe, 1.5)
}

fesim_test_bm_output_truth()
end

capture mata: fesim_test_bm_output_bad_wage()
assert _rc == 3300
capture mata: fesim_test_bm_output_bad_workers()
assert _rc == 3300
quietly datasignature confirm
assert `"`c(rngstate)'"' == `"`rng_before'"'

di as result "FESIM BM OUTPUT TRUTH TESTS PASS"
