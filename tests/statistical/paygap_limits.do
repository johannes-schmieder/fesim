version 16.0
clear all
set more off
set varabbrev off

quietly fesim, dgp(akmpaygap) preset(simple) workers(20000) firms(400) ///
    periods(8) burnin(5) seed(314159) truth(none) noreport clear ///
    parameters(mu_m 3 mu_f 3 sd_worker_m .4 sd_worker_f .4 ///
        premium_intercept_m .1 premium_intercept_f .1 ///
        premium_loading_m .2 premium_loading_f .2 ///
        premium_deviation_sd_m 0 premium_deviation_sd_f 0 ///
        sd_error_m .15 sd_error_f .15 ///
        group_sort_m 0 group_sort_f 0 ///
        worker_sort_m 0 worker_sort_f 0 ///
        wage_trend_m 0 wage_trend_f 0)
matrix equal_decomposition = r(decomposition)
assert abs(equal_decomposition["total_gap", "male_reference"]) < .04
assert abs(equal_decomposition["worker_composition", "male_reference"]) < .025
assert abs(equal_decomposition["sorting", "male_reference"]) < .015
assert abs(equal_decomposition["premium_schedule", "male_reference"]) < 1e-12
assert abs(equal_decomposition["adding_up_error", "symmetric"]) < 1e-10

quietly fesim, dgp(akmpaygap) preset(simple) workers(40000) firms(500) ///
    periods(10) burnin(5) seed(271828) truth(none) noreport clear ///
    parameters(p_eu_m .05 p_ee_m .10 p_ue_m .70 ///
        p_eu_f .12 p_ee_f .18 p_ue_f .50)
matrix mobility = r(group_moments)
assert abs(mobility["p_eu_realized", "men"] - .05) < .006
assert abs(mobility["p_ee_realized", "men"] - .10) < .008
assert abs(mobility["p_ue_realized", "men"] - .70) < .012
assert abs(mobility["p_eu_realized", "women"] - .12) < .009
assert abs(mobility["p_ee_realized", "women"] - .18) < .011
assert abs(mobility["p_ue_realized", "women"] - .50) < .014

di as result "FESIM PAY-GAP LIMITING-CASE TESTS PASS"
