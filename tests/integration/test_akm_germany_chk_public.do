version 16.0
clear all
set more off
set varabbrev off

set rng mt64
set seed 27182818
local rng_before `"`c(rngstate)'"'

quietly fesim, dgp(akm) preset(germany_chk_2002_2009) workers(600) ///
    firms(60) periods(8) seed(24680) truth(full) connectivity(keep) ///
    noreport clear

local returned_class `"`r(calibration_class)'"'
local returned_preset `"`r(preset)'"'
local returned_clock `"`r(internal_clock)'"'
matrix germany_parameters = r(parameters)
matrix germany_moments = r(moments)
matrix germany_targets = r(targets)
matrix germany_durations = r(durations)

assert _N == 4800
isid workerid time
assert `"`returned_preset'"' == "germany_chk_2002_2009"
assert `"`returned_class'"' == "targeted"
assert `"`returned_clock'"' == "month"
assert `"`c(rngstate)'"' == `"`rng_before'"'
quietly summarize time, meanonly
assert r(min) == yearly("2002", "Y")
assert rowsof(germany_parameters) == 34
assert rowsof(germany_moments) == 38
assert rowsof(germany_targets) == 10
assert rowsof(germany_durations) == 12
assert reldif(germany_parameters["sd_worker", "value"], .357) < 1e-12
assert reldif(germany_parameters["sd_firm", "value"], .230) < 1e-12
assert reldif(germany_parameters["sd_error", "value"], .135) < 1e-12
assert reldif(germany_parameters["theta_sort", "value"], 2.2) < 1e-12
assert germany_targets["alpha_true_sd", "target"] == .357
assert germany_targets["psi_true_sd", "target"] == .230
assert germany_targets["epsilon_true_sd", "target"] == .135
assert germany_targets["cov_alpha_psi_true", "target"] == .0205
assert !missing(germany_moments["cov_alpha_psi_true", "realized"])

local metadata_preset : char _dta[fesim_preset]
local metadata_class : char _dta[fesim_calibration_class]
assert `"`metadata_preset'"' == "germany_chk_2002_2009"
assert `"`metadata_class'"' == "targeted"

quietly fesim, dgp(akm) preset(germany_chk_2002_2009) workers(80) ///
    firms(10) periods(2) seed(13579) parameters(theta_sort 2.1) ///
    truth(none) noreport clear
assert `"`r(calibration_class)'"' == "targeted_modified"
assert rowsof(r(targets)) == 10

di as result "FESIM PUBLIC GERMANY CHK INTEGRATION TESTS PASS"
