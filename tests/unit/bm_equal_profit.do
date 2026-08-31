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
assert(fesim_mata_api_version() == 27)
assert(fesim_bm_schema_version() == 1)

p = 1
b = .4
lambda_u = 1
lambda_e = .5
delta = .2
discount = .05
solution = fesim_bm_solve(
    b, p, lambda_u, lambda_e, delta, discount, 401, 4000, 1e-10)
repeat_solution = fesim_bm_solve(
    b, p, lambda_u, lambda_e, delta, discount, 401, 4000, 1e-10)
assert(solution.validated == 1)
assert(solution.status == "converged_analytic")
assert(abs(solution.surplus_coefficient - .928429825374297) < 5e-15)
assert(abs(solution.reservation_wage - .590224088826639) < 5e-15)
assert(abs(solution.upper_wage - .966548905210338) < 5e-15)
assert(abs(solution.unemployment_rate - 1 / 6) < 5e-15)
assert(abs(solution.employment_rate - 5 / 6) < 5e-15)
assert(abs(solution.equilibrium_profit - .0975656931365146) < 5e-15)
assert(abs(solution.reservation_residual) < 1e-12)
assert(solution.equal_profit_residual < 1e-14)
assert(solution.monotonicity_violation == 0)
assert(solution.cdf_violation == 0)
assert(rows(solution.support_grid) == 401)
assert(solution.support_grid[1] == solution.reservation_wage)
assert(solution.support_grid[401] == solution.upper_wage)
assert(solution.offer_cdf[1] == 0 & solution.offer_cdf[401] == 1)
assert(solution.worker_cdf[1] == 0 & solution.worker_cdf[401] == 1)
assert(min(solution.firm_employment) > 0)
assert(max(abs(solution.firm_profit :- solution.equilibrium_profit)) < 1e-14)
assert(mreldif(solution.support_grid, repeat_solution.support_grid) == 0)
assert(mreldif(solution.offer_cdf, repeat_solution.offer_cdf) == 0)
assert(solution.reservation_residual == repeat_solution.reservation_residual)

low = b
high = p - 1e-8
assert(fesim_bm_reservation_residual(
    low, b, p, lambda_u, lambda_e, delta, discount, 4000) < 0)
assert(fesim_bm_reservation_residual(
    high, b, p, lambda_u, lambda_e, delta, discount, 4000) > 0)
for (iteration = 1; iteration <= 60; iteration++) {
    middle = (low + high) / 2
    if (fesim_bm_reservation_residual(
        middle, b, p, lambda_u, lambda_e, delta, discount, 4000) > 0) {
        high = middle
    }
    else low = middle
}
numeric_reservation = (low + high) / 2
assert(abs(numeric_reservation - solution.reservation_wage) < 2e-12)

outside_wage = (solution.reservation_wage - .1 \
    solution.reservation_wage \
    solution.upper_wage \
    solution.upper_wage + .1)
outside_cdf = fesim_bm_offer_cdf(
    outside_wage, p, solution.reservation_wage, lambda_e, delta)
assert(outside_cdf == (0 \ 0 \ 1 \ 1))

equal_solution = fesim_bm_solve(
    b, p, .5, .5, delta, discount, 101, 1000, 1e-10)
assert(equal_solution.reservation_wage == b)
assert(equal_solution.reservation_residual == 0)

lower_arrival_solution = fesim_bm_solve(
    .8, p, .3, .5, delta, discount, 101, 1000, 1e-10)
assert(lower_arrival_solution.reservation_wage < .8)
assert(lower_arrival_solution.reservation_wage > 0)
assert(lower_arrival_solution.validated == 1)

assert(abs(fesim_bm_log1p(1e-12) / 1e-12 - 1) < 1e-12)
small_lambda = 1e-8
small_coefficient = fesim_bm_surplus_coefficient(
    small_lambda, delta, discount)
assert(abs(small_coefficient / ///
    (small_lambda / (delta * (discount + delta))) - 1) < 1e-7)
small_ee = fesim_bm_job_to_job_rate(small_lambda, delta)
assert(abs(small_ee / (small_lambda / 2) - 1) < 1e-7)

scenario_solution_1 = fesim_bm_solve(
    1, 3, .1, .03, .4, .02, 151, 2000, 1e-9)
assert(scenario_solution_1.validated == 1)
assert(abs(scenario_solution_1.reservation_residual) < 1e-8)
scenario_solution_2 = fesim_bm_solve(
    .5, 5, 2, .1, .01, .1, 151, 2000, 1e-9)
assert(scenario_solution_2.validated == 1)
assert(abs(scenario_solution_2.reservation_residual) < 1e-8)
scenario_solution_3 = fesim_bm_solve(
    1.2, 2, .2, .8, .5, .04, 151, 2000, 1e-9)
assert(scenario_solution_3.validated == 1)
assert(abs(scenario_solution_3.reservation_residual) < 1e-8)
scenario_solution_4 = fesim_bm_solve(
    4, 10, .7, .6, .15, .03, 151, 2000, 1e-9)
assert(scenario_solution_4.validated == 1)
assert(abs(scenario_solution_4.reservation_residual) < 1e-8)

bad_solution = fesim_bm_solve(
    b, p, lambda_u, lambda_e, delta, discount, 101, 1000, 1e-10)
bad_solution.firm_profit[1] = -1
end

capture mata: fesim_bm_solution_validate(bad_solution, 1e-10)
assert _rc == 430
capture mata: fesim_bm_solve(.4, 1, 0, .5, .2, .05, 101, 1000, 1e-10)
assert _rc == 3300
capture mata: fesim_bm_solve(.4, .4, 1, .5, .2, .05, 101, 1000, 1e-10)
assert _rc == 3300
capture mata: fesim_bm_solve(-.1, 1, .5, .5, .2, .05, 101, 1000, 1e-10)
assert _rc == 3300
capture mata: fesim_bm_solve(.4, 1, 1, .5, .2, .05, 2, 1000, 1e-10)
assert _rc == 3300
capture mata: fesim_bm_solve(.4, 1, 1, .5, .2, .05, 101, 999, 1e-10)
assert _rc == 3300
capture mata: fesim_bm_solve(.4, 1, 1, .5, .2, .05, 101, 1000, 1e-3)
assert _rc == 3300
capture mata: fesim_bm_reservation_residual( ///
    .5, .4, 1, 1, .5, .2, .05, 99)
assert _rc == 3300
capture mata: fesim_bm_solve(.4, 1, 1, .5, .2, .05, 101, 100, 1e-20)
assert _rc == 430

quietly datasignature confirm
assert `"`c(rngstate)'"' == `"`rng_before'"'

di as result "FESIM BM SOLVER AND EQUAL-PROFIT TESTS PASS"
