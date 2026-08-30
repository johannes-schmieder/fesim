version 16.0
clear all
set more off
set varabbrev off

args repository_root
local common_options workers(40) firms(6) periods(4) ///
    frequency(quarter) start(2000q1) seed(24680) ///
    parameters(mu 3.2 sd_worker .3 sd_firm .1 sd_error .15 ///
    firm_size_sd .5 p_eu .08 p_ee .12 p_ue .6 wage_trend .04) ///
    truth(basic) connectivity(keep) noreport clear

set rng mt64
set seed 11235813
local explicit_rng_before `"`c(rngstate)'"'
quietly fesim, dgp(akm) preset(simple) `common_options'
local public_dgp `"`r(dgp)'"'
local public_alias `"`r(dgp_alias)'"'
local public_preset `"`r(preset)'"'
local public_calibration `"`r(calibration_class)'"'
local public_seed `"`r(seed)'"'
local public_rng `"`r(rng)'"'
local public_N = r(N)
local public_workers = r(N_workers)
local public_firms = r(N_firms)
local public_periods = r(periods)
local public_components = r(components)
local public_largest_obs_share = r(largest_component_obs_share)
local public_largest_worker_share = r(largest_component_worker_share)
local public_largest_firm_share = r(largest_component_firm_share)
matrix public_parameters = r(parameters)
matrix public_moments = r(moments)
matrix public_targets = r(targets)
matrix public_network = r(network)
assert _N == 160
isid workerid time
assert workerid == floor((_n - 1) / 4) + 1
assert time == yq(2000, 1) + mod(_n - 1, 4)
assert missing(firmid) == !employed
assert missing(lnwage) == !employed
assert missing(spellid) == !employed
assert missing(tenure) == !employed
assert !missing(alpha_true)
assert !missing(time_true)
assert missing(psi_true) == !employed
assert missing(xb_true) == !employed
assert missing(match_true) == !employed
assert missing(epsilon_true) == !employed
assert missing(lnwage_true) == !employed
assert lnwage == lnwage_true if employed
assert xb_true == 0 if employed
assert match_true == 0 if employed
by workerid (time): assert missing(newjob) & missing(from_unemp) & ///
    missing(jobtojob) & missing(ntransitions) if _n == 1
by workerid (time): assert missing(to_unemp) if _n == _N
by workerid (time): assert newjob == ///
    (employed & (!employed[_n - 1] | firmid != firmid[_n - 1] | ///
    spellid != spellid[_n - 1])) if _n > 1
by workerid (time): assert from_unemp == ///
    (!employed[_n - 1] & employed) if _n > 1
by workerid (time): assert jobtojob == ///
    (employed[_n - 1] & employed & firmid != firmid[_n - 1]) if _n > 1
by workerid (time): assert to_unemp == ///
    (employed & !employed[_n + 1]) if _n < _N

local time_format : format time
assert `"`time_format'"' == "%tq"
assert `"`public_dgp'"' == "akm"
assert `"`public_alias'"' == "akm"
assert `"`public_preset'"' == "simple"
assert `"`public_calibration'"' == "stylized_modified"
assert `"`public_seed'"' == "24680"
assert `"`public_rng'"' == "mt64s"
assert `public_N' == 160
assert `public_workers' == 40
assert `public_firms' == 6
assert `public_periods' == 4
assert `"`c(rngstate)'"' == `"`explicit_rng_before'"'
assert rowsof(public_parameters) == 13
assert rowsof(public_moments) == 38
assert rowsof(public_targets) == 10
assert colsof(public_targets) == 4
assert rowsof(public_network) == 19
assert colsof(public_network) == 2
assert public_network["components", "generated"] == `public_components'
assert public_network["largest_observation_share", "generated"] == ///
    `public_largest_obs_share'
assert public_network["largest_worker_share", "generated"] == ///
    `public_largest_worker_share'
assert public_network["largest_firm_share", "generated"] == ///
    `public_largest_firm_share'
assert inrange(public_network["firms_no_movers", "generated"], 0, ///
    public_network["firms", "generated"])
assert public_network["firm_links", "generated"] >= 0
if public_network["firm_links", "generated"] > 0 {
    assert public_network["edge_weight_p10", "generated"] >= 1
    assert public_network["edge_weight_p10", "generated"] <= ///
        public_network["edge_weight_p50", "generated"]
    assert public_network["edge_weight_p50", "generated"] <= ///
        public_network["edge_weight_p90", "generated"]
    assert public_network["edge_weight_p90", "generated"] <= ///
        public_network["edge_weight_p99", "generated"]
}
mata: assert(st_matrix("public_network")[, 1] == ///
    st_matrix("public_network")[, 2])
assert public_targets["alpha_true_mean", "target"] == 0
assert public_targets["alpha_true_sd", "target"] == .3
assert public_targets["alpha_true_var", "target"] == .09
assert public_targets["psi_true_sd", "target"] == .1
assert public_targets["epsilon_true_sd", "target"] == .15
assert public_targets["cov_alpha_psi_true", "target"] == 0
preserve
quietly by workerid: keep if _n == 1
quietly summarize alpha_true
assert reldif(public_moments["alpha_true_mean", "realized"], r(mean)) < 1e-12
assert reldif(public_moments["alpha_true_sd", "realized"], r(sd)) < 1e-12
restore
preserve
quietly keep if employed
quietly bysort firmid: keep if _n == 1
quietly summarize psi_true
assert reldif(public_moments["psi_true_mean", "realized"], r(mean)) < 1e-12
assert reldif(public_moments["psi_true_sd", "realized"], r(sd)) < 1e-12
restore
quietly summarize epsilon_true if employed
assert reldif(public_moments["epsilon_true_mean", "realized"], r(mean)) < 1e-12
assert reldif(public_moments["epsilon_true_sd", "realized"], r(sd)) < 1e-12
quietly correlate alpha_true psi_true if employed, covariance
matrix public_covariance = r(C)
assert reldif(public_moments["cov_alpha_psi_true", "realized"], ///
    public_covariance[1, 2]) < 1e-12
foreach characteristic in version dgp dgp_alias preset calibration_class ///
    command seed rng frequency internal_clock jobrule burnin connectivity ///
    reference rng_method stata_version truth {
    local characteristic_value : char _dta[fesim_`characteristic']
    assert strtrim(`"`characteristic_value'"') != ""
}
local metadata_dgp : char _dta[fesim_dgp]
local metadata_alias : char _dta[fesim_dgp_alias]
local metadata_seed : char _dta[fesim_seed]
local canonical_metadata_command : char _dta[fesim_command]
assert `"`metadata_dgp'"' == "akm"
assert `"`metadata_alias'"' == "akm"
assert `"`metadata_seed'"' == "24680"

tempfile canonical
quietly save `canonical'

quietly fesim, dgp(akmsimple) `common_options'
local alias_dgp `"`r(dgp)'"'
local alias_name `"`r(dgp_alias)'"'
matrix alias_moments = r(moments)
matrix alias_targets = r(targets)
assert `"`alias_dgp'"' == "akm"
assert `"`alias_name'"' == "akmsimple"
mata: assert(mreldif(st_matrix("alias_moments"), ///
    st_matrix("public_moments")) == 0)
mata: assert(mreldif(st_matrix("alias_targets"), ///
    st_matrix("public_targets")) == 0)
quietly cf _all using `canonical'

quietly fesim, dgp(akm) preset(simple) workers(40) firms(6) periods(4) ///
    frequency(quarter) start(2000q1) seed(24680) ///
    parameters(mu 3.2 sd_worker .3 sd_firm .1 sd_error .15 ///
    firm_size_sd .5 p_eu .08 p_ee .12 p_ue .6 wage_trend .04) ///
    truth(basic) connectivity(keep) report clear
quietly cf _all using `canonical'
local report_metadata_command : char _dta[fesim_command]
assert `"`report_metadata_command'"' == `"`canonical_metadata_command'"'

quietly fesim, dgp(akm) preset(simple) workers(40) firms(6) periods(4) ///
    frequency(quarter) start(2000q1) seed(24680) ///
    parameters(mu 3.2 sd_worker .3 sd_firm .1 sd_error .15 ///
    firm_size_sd .5 p_eu .08 p_ee .12 p_ue .6 wage_trend .04) ///
    truth(none) connectivity(keep) noreport clear
matrix none_moments = r(moments)
matrix none_targets = r(targets)
foreach truth_name in alpha_true psi_true time_true xb_true match_true ///
    epsilon_true lnwage_true {
    capture confirm variable `truth_name'
    assert _rc == 111
}
quietly cf workerid time firmid employed lnwage spellid tenure newjob ///
    from_unemp to_unemp jobtojob ntransitions using `canonical'
mata: assert(mreldif(st_matrix("none_moments"), ///
    st_matrix("public_moments")) == 0)
mata: assert(mreldif(st_matrix("none_targets"), ///
    st_matrix("public_targets")) == 0)

quietly fesim, workers(8) firms(2) periods(3) seed(13579) ///
    initial(allunemployed) parameters(p_ue 0) truth(none) noreport clear
matrix unemployed_moments = r(moments)
matrix unemployed_targets = r(targets)
assert r(N_firms_active) == 0
assert missing(unemployed_moments["psi_true_mean", "realized"])
assert missing(unemployed_moments["epsilon_true_mean", "realized"])
assert missing(unemployed_moments["cov_alpha_psi_true", "realized"])
assert unemployed_targets["psi_true_sd", "target"] == .15
assert unemployed_targets["epsilon_true_sd", "target"] == .2

clear
set rng mt64
set seed 97531
mata:
public_unseeded_caller = rngstate()
public_expected_seed_matrix = runiformint(1, 1, 0, 2147483647)
public_expected_seed = public_expected_seed_matrix[1, 1]
public_expected_continuation = rngstate()
rngstate(public_unseeded_caller)
end
quietly fesim, workers(12) firms(3) periods(2) truth(none) noreport clear
local unseeded_N = r(N)
local unseeded_record `"`r(seed)'"'
mata: assert(rngstate() == public_expected_continuation)
assert `unseeded_N' == 24
mata: st_local("expected_seed_text", ///
    strtrim(sprintf("%21.0f", public_expected_seed)))
assert `"`unseeded_record'"' == `"`expected_seed_text'"'

local disconnected_options workers(60) firms(6) periods(4) ///
    seed(73195) initial(stationary) ///
    parameters(p_eu 0 p_ee 0 p_ue .6 firm_size_sd 0) noreport clear
quietly fesim, `disconnected_options' truth(none) connectivity(keep)
matrix disconnected_keep_network = r(network)
assert r(components) > 1
assert disconnected_keep_network["workers", "generated"] == 60
assert disconnected_keep_network["employed_observations", "generated"] == 240
matrix disconnected_keep_moments = r(moments)

quietly fesim, `disconnected_options' truth(none) connectivity(largest)
matrix largest_none_network = r(network)
matrix largest_none_moments = r(moments)
local largest_none_workers = r(N_workers)
assert r(components) == 1
assert r(N) == `largest_none_workers' * 4
assert `largest_none_workers' < 60
assert r(N_firms) == 6
assert r(N_firms_active) == 1
assert largest_none_network["components", "generated"] == ///
    disconnected_keep_network["components", "generated"]
assert largest_none_network["workers", "generated"] == 60
assert largest_none_network["workers", "returned"] == `largest_none_workers'
assert largest_none_network["largest_observation_share", "returned"] == 1
assert largest_none_network["largest_worker_share", "returned"] == 1
assert largest_none_network["largest_firm_share", "returned"] == 1
by workerid (time): assert _N == 4
foreach truth_name in alpha_true psi_true time_true xb_true match_true ///
    epsilon_true lnwage_true {
    capture confirm variable `truth_name'
    assert _rc == 111
}
tempfile largest_none
quietly save `largest_none'

quietly fesim, `disconnected_options' truth(basic) connectivity(largest)
matrix largest_basic_moments = r(moments)
assert r(N_workers) == `largest_none_workers'
mata: assert(mreldif(st_matrix("largest_basic_moments"), ///
    st_matrix("largest_none_moments")) == 0)
quietly cf workerid time firmid employed lnwage spellid tenure newjob ///
    from_unemp to_unemp jobtojob ntransitions using `largest_none'
preserve
quietly by workerid: keep if _n == 1
quietly summarize alpha_true
assert reldif(largest_basic_moments["alpha_true_mean", "realized"], ///
    r(mean)) < 1e-12
restore

clear
set obs 3
generate long protected_id = _n
generate double protected_value = _n / 7
quietly datasignature set, reset
set rng mt64
set seed 86420
local failure_rng_before `"`c(rngstate)'"'
capture noisily fesim, workers(12) firms(3) periods(2) seed(1234) ///
    initial(allunemployed) parameters(p_ue 0) truth(none) ///
    connectivity(largest) clear
assert _rc == 459
quietly datasignature confirm
assert `"`c(rngstate)'"' == `"`failure_rng_before'"'

capture noisily fesim, workers(12) firms(3) periods(2) ///
    connectivity(force) clear
assert _rc == 498
quietly datasignature confirm
assert `"`c(rngstate)'"' == `"`failure_rng_before'"'

capture noisily fesim, workers(12) firms(3) periods(2) ///
    parameters(p_eu 0 p_ee 0 p_ue 0) clear
assert _rc == 3300
quietly datasignature confirm
assert `"`c(rngstate)'"' == `"`failure_rng_before'"'

capture noisily fesim, workers(12) firms(3) periods(2)
assert _rc == 4
quietly datasignature confirm
assert `"`c(rngstate)'"' == `"`failure_rng_before'"'

di as result "FESIM PUBLIC SIMPLE-AKM OUTPUT TESTS PASS"
