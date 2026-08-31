version 16.0
clear all
set more off
set varabbrev off

fesim, dgp(akmpaygap) preset(cck2016) workers(1000) firms(100) ///
    periods(8) burnin(5) seed(24680) truth(full) noreport clear

assert `"`r(calibration_class)'"' == "targeted"
assert `"`r(group_coding)'"' == "0_men_1_women"
assert `"`r(gap_direction)'"' == "men_minus_women"
matrix group_moments = r(group_moments)
matrix group_targets = r(group_targets)
matrix decomposition = r(decomposition)
matrix decomposition_targets = r(decomposition_targets)
assert group_targets["lnwage_sd", "men"] == .554
assert decomposition_targets["total_gap", "male_reference"] == .234
assert abs(decomposition["adding_up_error", "symmetric"]) < 1e-10

matrix list group_moments
matrix list group_targets
matrix list decomposition

di as result "fesim akmpaygap/cck2016 example completed"
