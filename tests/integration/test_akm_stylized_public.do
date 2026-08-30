version 16.0
clear all
set more off
set varabbrev off

set rng mt64
set seed 11235813
local rng_before `"`c(rngstate)'"'

local options workers(400) firms(25) periods(4) frequency(year) ///
    start(2000) seed(24680) truth(full) connectivity(keep) ///
    noreport clear
quietly fesim, dgp(akm) preset(stylized) `options'

local returned_dgp `"`r(dgp)'"'
local returned_preset `"`r(preset)'"'
local returned_class `"`r(calibration_class)'"'
local returned_clock `"`r(internal_clock)'"'
local returned_frequency `"`r(frequency)'"'
local returned_seed `"`r(seed)'"'
scalar returned_N = r(N)
scalar returned_workers = r(N_workers)
scalar returned_periods = r(periods)
matrix stylized_parameters = r(parameters)
matrix stylized_moments = r(moments)
matrix stylized_targets = r(targets)
matrix stylized_durations = r(durations)
matrix stylized_network = r(network)

assert _N == 1600
isid workerid time
assert `"`returned_dgp'"' == "akm"
assert `"`returned_preset'"' == "stylized"
assert `"`returned_class'"' == "stylized"
assert `"`returned_clock'"' == "month"
assert `"`returned_frequency'"' == "year"
assert `"`returned_seed'"' == "24680"
assert `"`c(rngstate)'"' == `"`rng_before'"'
assert returned_N == 1600
assert returned_workers == 400
assert returned_periods == 4

foreach variable in workerid time firmid employed lnwage spellid tenure ///
    newjob from_unemp to_unemp jobtojob ntransitions unemp_duration ///
    alpha_true psi_true time_true xb_true match_true epsilon_true ///
    lnwage_true worker_type_true firm_quality_true {
    confirm variable `variable'
}
assert missing(tenure) == !employed
assert missing(unemp_duration) == employed
assert missing(firm_quality_true) == !employed
assert tenure >= 0 if employed
assert unemp_duration >= 0 if !employed
assert abs(tenure * 12 - round(tenure * 12)) < 1e-8 if employed
assert abs(unemp_duration * 12 - round(unemp_duration * 12)) < 1e-8 ///
    if !employed
by workerid (time): assert missing(ntransitions) if _n == 1
by workerid (time): assert ntransitions >= 0 & ///
    ntransitions == floor(ntransitions) if _n > 1
by workerid (time): assert worker_type_true == worker_type_true[1]
bysort firmid (workerid time): assert ///
    firm_quality_true == firm_quality_true[1] if employed

assert rowsof(stylized_parameters) == 30
assert rowsof(stylized_moments) == 38
assert rowsof(stylized_targets) == 9
assert colsof(stylized_targets) == 4
assert rowsof(stylized_durations) == 12
assert colsof(stylized_durations) == 1
assert rowsof(stylized_network) == 21
assert colsof(stylized_network) == 2
assert inrange(stylized_network["firms_no_movers", "generated"], 0, ///
    stylized_network["firms", "generated"])
assert stylized_network["firm_links", "generated"] >= 0
assert inrange(stylized_network["articulation_firms", "generated"], 0, ///
    stylized_network["firms", "generated"])
assert inrange(stylized_network["graph_bridge_links", "generated"], 0, ///
    stylized_network["firm_links", "generated"])
if stylized_network["firm_links", "generated"] > 0 {
    assert stylized_network["edge_weight_p10", "generated"] >= 1
    assert stylized_network["edge_weight_p10", "generated"] <= ///
        stylized_network["edge_weight_p50", "generated"]
    assert stylized_network["edge_weight_p50", "generated"] <= ///
        stylized_network["edge_weight_p90", "generated"]
    assert stylized_network["edge_weight_p90", "generated"] <= ///
        stylized_network["edge_weight_p99", "generated"]
}
assert stylized_parameters["burnin", "value"] == 5
assert reldif(stylized_parameters["rho_z_alpha", "value"], .3) < 1e-12
assert reldif(stylized_parameters["theta_sort", "value"], .25) < 1e-12
assert stylized_durations["tenure_years_N", "realized"] == ///
    stylized_moments["employment_rate", "realized"] * _N
assert stylized_durations["unemployment_duration_years_N", "realized"] == ///
    _N - stylized_durations["tenure_years_N", "realized"]

quietly summarize tenure if employed
assert reldif(stylized_durations["tenure_years_mean", "realized"], ///
    r(mean)) < 1e-12
quietly summarize unemp_duration if !employed
assert reldif( ///
    stylized_durations["unemployment_duration_years_mean", "realized"], ///
    r(mean)) < 1e-12

local metadata_preset : char _dta[fesim_preset]
local metadata_class : char _dta[fesim_calibration_class]
local metadata_clock : char _dta[fesim_internal_clock]
assert `"`metadata_preset'"' == "stylized"
assert `"`metadata_class'"' == "stylized"
assert `"`metadata_clock'"' == "month"

quietly datasignature
local canonical_signature `"`r(datasignature)'"'
quietly fesim, dgp(akmempirical) `options'
matrix alias_parameters = r(parameters)
matrix alias_moments = r(moments)
matrix alias_targets = r(targets)
matrix alias_durations = r(durations)
quietly datasignature
assert `"`r(datasignature)'"' == `"`canonical_signature'"'
mata: assert(mreldif(st_matrix("stylized_parameters"), ///
    st_matrix("alias_parameters")) == 0)
mata: assert(mreldif(st_matrix("stylized_moments"), ///
    st_matrix("alias_moments")) == 0)
mata: assert(mreldif(st_matrix("stylized_targets"), ///
    st_matrix("alias_targets")) == 0)
mata: assert(mreldif(st_matrix("stylized_durations"), ///
    st_matrix("alias_durations")) == 0)

quietly fesim, dgp(akmempirical) workers(120) firms(12) periods(5) ///
    frequency(quarter) seed(13579) truth(none) noreport clear
matrix quarterly_durations = r(durations)
local quarterly_clock `"`r(internal_clock)'"'
local quarterly_frequency `"`r(frequency)'"'
assert `"`quarterly_clock'"' == "month"
assert `"`quarterly_frequency'"' == "quarter"
assert _N == 600
confirm variable unemp_duration
foreach variable in alpha_true psi_true time_true xb_true match_true ///
    epsilon_true lnwage_true worker_type_true firm_quality_true {
    capture confirm variable `variable'
    assert _rc == 111
}
assert abs(tenure * 3 - round(tenure * 3)) < 1e-8 if employed
assert abs(unemp_duration * 3 - round(unemp_duration * 3)) < 1e-8 ///
    if !employed
quietly summarize tenure if employed
assert reldif(quarterly_durations["tenure_years_mean", "realized"], ///
    r(mean) * .25) < 1e-12

quietly fesim, dgp(akmempirical) workers(80) firms(10) periods(3) ///
    frequency(month) seed(97531) initial(allunemployed) burnin(0) ///
    parameters(sd_worker 0 rho_z_alpha 0 sd_firm 0 rho_q_psi 0) ///
    noreport clear
local zero_class `"`r(calibration_class)'"'
local zero_clock `"`r(internal_clock)'"'
assert `"`zero_class'"' == "stylized_modified"
assert `"`zero_clock'"' == "month"

di as result "FESIM PUBLIC STYLIZED-AKM INTEGRATION TESTS PASS"
