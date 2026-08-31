version 16.0
clear all
set more off
set varabbrev off

fesim, dgp(akm) preset(germany_chk_2002_2009) workers(1000) firms(100) ///
    periods(8) seed(24680) truth(full) noreport clear

assert `"`r(calibration_class)'"' == "targeted"
assert r(targets)["alpha_true_sd", "target"] == .357
assert r(targets)["psi_true_sd", "target"] == .230
assert r(targets)["epsilon_true_sd", "target"] == .135
assert r(targets)["cov_alpha_psi_true", "target"] == .0205
matrix list r(targets)
matrix list r(durations)

di as result "fesim akm/germany_chk_2002_2009 example completed"
