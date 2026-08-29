version 16.0
clear all
set more off
set varabbrev off

set rng mt64
set seed 31415926
local rng_before `"`c(rngstate)'"'

quietly fesim_time, frequency(quarter) start(2000q1) periods(5)
scalar toy_start = r(start_value)
mata: toy_output_result = fesim_dispatch_run("_toy", "deterministic", 7, 3, 5)
mata: toy_transition_raw = toy_output_result.observed[, 8]
mata: assert(fesim_output_lifecycle_panel(toy_output_result, ///
    st_numscalar("toy_start"), "%tq", "none", 2, 0) == 35)

assert _N == 35
isid workerid time
assert workerid == floor((_n - 1) / 5) + 1
assert time == toy_start + mod(_n - 1, 5)
assert missing(firmid) == !employed
assert missing(lnwage) == !employed
assert missing(spellid) == !employed
assert missing(tenure) == !employed
by workerid (time): assert missing(newjob) if _n == 1
by workerid (time): assert missing(from_unemp) if _n == 1
by workerid (time): assert missing(jobtojob) if _n == 1
by workerid (time): assert missing(ntransitions) if _n == 1
by workerid (time): assert newjob == ///
    (employed & (!employed[_n - 1] | firmid != firmid[_n - 1] | ///
    spellid != spellid[_n - 1])) if _n > 1
by workerid (time): assert from_unemp == ///
    (!employed[_n - 1] & employed) if _n > 1
by workerid (time): assert jobtojob == ///
    (employed[_n - 1] & employed & firmid != firmid[_n - 1]) if _n > 1
by workerid (time): assert ntransitions >= 0 & ///
    ntransitions == floor(ntransitions) if _n > 1
by workerid (time): assert to_unemp == ///
    (employed & !employed[_n + 1]) if _n < _N
by workerid (time): assert missing(to_unemp) if _n == _N
mata: toy_transition_expected = toy_transition_raw
mata: for (toy_worker = 1; toy_worker <= 7; toy_worker++) ///
    toy_transition_expected[(toy_worker - 1) * 5 + 1] = .
mata: assert(mreldif(st_data(., "ntransitions"), ///
    toy_transition_expected) == 0)

local worker_type : type workerid
local time_type : type time
local firm_type : type firmid
local employed_type : type employed
local wage_type : type lnwage
local spell_type : type spellid
local tenure_type : type tenure
local flow_type : type newjob
local transition_type : type ntransitions
assert `"`worker_type'"' == "long"
assert `"`time_type'"' == "long"
assert `"`firm_type'"' == "long"
assert `"`employed_type'"' == "byte"
assert `"`wage_type'"' == "double"
assert `"`spell_type'"' == "long"
assert `"`tenure_type'"' == "double"
assert `"`flow_type'"' == "byte"
assert `"`transition_type'"' == "long"
local time_format : format time
local worker_label : variable label workerid
local wage_label : variable label lnwage
assert `"`time_format'"' == "%tq"
assert `"`worker_label'"' == "Worker identifier"
assert `"`wage_label'"' == "Observed log wage"

capture confirm variable alpha_true
assert _rc == 111
mata: toy_core_none = st_data(., ///
    ("workerid", "time", "firmid", "employed", "lnwage", ///
    "spellid", "tenure", "newjob", "from_unemp", "to_unemp", ///
    "jobtojob", "ntransitions"))

clear
mata: assert(fesim_output_lifecycle_panel(toy_output_result, ///
    st_numscalar("toy_start"), "%tq", "basic", 7, 0) == 35)
foreach name in alpha_true psi_true time_true xb_true match_true epsilon_true lnwage_true {
    confirm variable `name'
    local truth_type : type `name'
    assert `"`truth_type'"' == "double"
}
assert !missing(alpha_true)
assert missing(psi_true) == !employed
assert missing(xb_true) == !employed
assert missing(lnwage_true) == !employed
assert lnwage_true == lnwage if employed
local alpha_label : variable label alpha_true
local true_wage_label : variable label lnwage_true
assert `"`alpha_label'"' == "True worker effect"
assert `"`true_wage_label'"' == "True latent log wage"
mata: toy_core_basic = st_data(., ///
    ("workerid", "time", "firmid", "employed", "lnwage", ///
    "spellid", "tenure", "newjob", "from_unemp", "to_unemp", ///
    "jobtojob", "ntransitions"))
mata: toy_truth_basic = st_data(., ///
    ("alpha_true", "psi_true", "time_true", "xb_true", ///
    "match_true", "epsilon_true", "lnwage_true"))
mata: assert(mreldif(toy_core_none, toy_core_basic) == 0)

clear
mata: assert(fesim_output_lifecycle_panel(toy_output_result, ///
    st_numscalar("toy_start"), "%tq", "full", 1, 0) == 35)
mata: toy_core_full = st_data(., ///
    ("workerid", "time", "firmid", "employed", "lnwage", ///
    "spellid", "tenure", "newjob", "from_unemp", "to_unemp", ///
    "jobtojob", "ntransitions"))
mata: toy_truth_full = st_data(., ///
    ("alpha_true", "psi_true", "time_true", "xb_true", ///
    "match_true", "epsilon_true", "lnwage_true"))
mata: assert(mreldif(toy_core_none, toy_core_full) == 0)
mata: assert(mreldif(toy_truth_basic, toy_truth_full) == 0)

clear
mata: single_output_result = fesim_dispatch_run("_toy", "deterministic", 1, 1, 1)
mata: assert(fesim_output_lifecycle_panel(single_output_result, ///
    st_numscalar("toy_start"), "%tq", "basic", 1, 0) == 1)
assert _N == 1
assert workerid == 1
assert employed == 1
assert missing(newjob)
assert missing(from_unemp)
assert missing(to_unemp)
assert missing(jobtojob)
assert missing(ntransitions)
assert !missing(alpha_true)
assert !missing(psi_true)

clear
set obs 2
generate long protected_id = _n
quietly datasignature set, reset
capture mata: fesim_output_lifecycle_panel(toy_output_result, ///
    st_numscalar("toy_start"), "%tq", "none", 2, 0)
assert _rc == 3300
quietly datasignature confirm

clear
capture mata: fesim_output_lifecycle_panel(toy_output_result, ///
    st_numscalar("toy_start"), "%tq", "none", 2, 1)
assert _rc == 3300
assert _N == 0
assert c(k) == 0

capture mata: fesim_output_lifecycle_panel(toy_output_result, ///
    st_numscalar("toy_start"), "%tq", "invalid", 2, 0)
assert _rc == 3300
assert _N == 0
assert c(k) == 0

mata: bad_output_result = fesim_dispatch_run("_toy", "deterministic", 7, 3, 5); bad_output_result.observed[3, 3] = .
capture mata: fesim_output_lifecycle_panel(bad_output_result, ///
    st_numscalar("toy_start"), "%tq", "none", 2, 0)
assert _rc == 3300
assert _N == 0
assert c(k) == 0
assert `"`c(rngstate)'"' == `"`rng_before'"'

di as result "FESIM INTEGRATED PANEL CONTRACT TESTS PASS"
