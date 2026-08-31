version 16.0
clear all
set more off
set varabbrev off

quietly fesim, dgp(akmpaygap) preset(simple) workers(500) firms(60) ///
    periods(5) burnin(2) seed(20260831) truth(full) clear noreport
local returned_dgp `"`r(dgp)'"'
local returned_preset `"`r(preset)'"'
local returned_reference `"`r(reference)'"'
local returned_group_coding `"`r(group_coding)'"'
local returned_gap_direction `"`r(gap_direction)'"'
local returned_surplus_normalization `"`r(surplus_normalization)'"'
matrix GM = r(group_moments)
matrix GT = r(group_targets)
matrix D = r(decomposition)
matrix DT = r(decomposition_targets)
assert _N == 2500
isid workerid time
by workerid (time): assert group == group[1]
assert inlist(group, 0, 1)
assert missing(lnwage) == !employed
assert psi_true == psi_male_true if employed & group == 0
assert psi_true == psi_female_true if employed & group == 1
assert missing(firm_surplus_true) == !employed
assert `"`returned_dgp'"' == "akmpaygap"
assert `"`returned_preset'"' == "simple"
assert `"`returned_reference'"' == "male_premium_schedule"
assert `"`returned_group_coding'"' == "0_men_1_women"
assert `"`returned_gap_direction'"' == "men_minus_women"
assert `"`returned_surplus_normalization'"' == ///
    "population_standard_normal_no_sample_restandardization"
assert `"`: char _dta[fesim_group_coding]'"' == "0_men_1_women"
assert `"`: char _dta[fesim_gap_direction]'"' == "men_minus_women"

assert rowsof(GM) == 17 & colsof(GM) == 2
assert rowsof(GT) == 17 & colsof(GT) == 2
assert rowsof(D) == 9 & colsof(D) == 3
assert rowsof(DT) == 9 & colsof(DT) == 3
assert abs(D["firm_total", "male_reference"] - ///
    D["sorting", "male_reference"] - ///
    D["premium_schedule", "male_reference"]) < 1e-12
assert abs(D["firm_total", "female_reference"] - ///
    D["sorting", "female_reference"] - ///
    D["premium_schedule", "female_reference"]) < 1e-12
assert abs(D["adding_up_error", "male_reference"]) < 1e-10
assert abs(D["adding_up_error", "female_reference"]) < 1e-10
assert abs(D["adding_up_error", "symmetric"]) < 1e-10

quietly fesim, dgp(akmpaygap) preset(simple) workers(200) firms(30) ///
    periods(4) burnin(1) seed(1234) truth(basic) clear noreport
confirm variable group
confirm variable alpha_true
capture confirm variable firm_surplus_true
assert _rc == 111

quietly fesim, dgp(akmpaygap) preset(cck2016) workers(500) firms(60) ///
    periods(5) burnin(2) seed(4321) truth(none) clear noreport
matrix GT = r(group_targets)
matrix DT = r(decomposition_targets)
confirm variable group
capture confirm variable alpha_true
assert _rc == 111
assert GT["lnwage_sd", "men"] == .554
assert GT["lnwage_sd", "women"] == .513
assert GT["alpha_sd", "men"] == .420
assert GT["premium_mean", "women"] == .099
assert DT["total_gap", "male_reference"] == .234
assert DT["firm_total", "symmetric"] == .049
assert DT["sorting", "male_reference"] == .035
assert DT["premium_schedule", "male_reference"] == .015
assert missing(DT["sorting", "female_reference"])

quietly fesim, dgp(akmpaygap) preset(simple) workers(600) firms(80) ///
    periods(6) burnin(2) seed(9876) connectivity(largest) ///
    truth(none) clear noreport
matrix GM = r(group_moments)
matrix D = r(decomposition)
local largest_workers = r(N_workers)
isid workerid time
by workerid: assert _N == 6
assert GM["N_workers", "men"] + GM["N_workers", "women"] == ///
    `largest_workers'
assert abs(D["adding_up_error", "symmetric"]) < 1e-10

capture noisily fesim, dgp(akmpaygap) network(blocks) clear
assert _rc == 198
capture noisily fesim, dgp(akmpaygap) connectivity(force) clear
assert _rc == 498

di as result "FESIM PUBLIC PAY-GAP INTEGRATION TESTS PASS"
