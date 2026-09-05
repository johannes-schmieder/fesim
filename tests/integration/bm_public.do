version 16.0
clear all
set more off
set varabbrev off

quietly fesim_config, dgp(bm)
assert `"`r(config_schema)'"' == "bm_simple_v1"
assert `"`r(initial)'"' == "stationary"
assert `"`r(internal_clock)'"' == "continuous_time"
assert r(burnin) == 0
matrix P = r(parameters)
assert P["b", "value"] == .4
assert P["r", "value"] == .05
quietly fesim_registry, action(parameter) dgp(bm) parameter(burnin)
assert `"`r(type)'"' == "real"
assert `"`r(unit)'"' == "years"
quietly fesim describe bmsimple
assert `"`r(configurable)'"' == "yes"

set seed 17329
local caller `"`c(rngstate)'"'
quietly fesim, dgp(bm) workers(2000) firms(80) periods(4) ///
    seed(876) truth(full) noreport clear
assert `"`c(rngstate)'"' == `"`caller'"'
assert `"`r(dgp)'"' == "bm"
assert `"`r(calibration_class)'"' == "stylized"
assert `"`r(solver_status)'"' == "converged_analytic"
assert rowsof(r(solver)) == 22
assert rowsof(r(bm_firms)) == 10 & colsof(r(bm_firms)) == 3
assert rowsof(r(bm_flows)) == 4 & colsof(r(bm_flows)) == 4
assert r(runtime_total) >= r(runtime_solve)
matrix S = r(solver)
matrix F = r(bm_flows)
assert abs(S["unemployment_rate",1] - 1/6) < 1e-12
assert F["ee","theory"] == S["finite_job_to_job_rate",1]
assert S["reservation_scaled_residual",1] < 1e-9
assert _N == 8000
assert c(k) == 36
assert lnwage == ln(posted_wage_true) if employed
assert lnwage == lnwage_true
assert employment_exposure_true + unemployment_exposure_true > 1-1e-12
assert n_events_true == n_eu_true + n_employed_offers_true + n_unemployment_offers_true
assert n_employed_offers_true == n_ee_true + n_rejected_offers_true
assert ntransitions_true == n_eu_true + n_ee_true + n_ue_true
assert missing(firmid) == !employed
capture confirm variable alpha_true
assert _rc == 111
tempfile full base annual
quietly save `full'
local basevars workerid time firmid employed lnwage spellid tenure unemp_duration newjob from_unemp to_unemp jobtojob ntransitions
keep `basevars'
quietly save `base'
foreach mode in none basic {
    quietly fesim, dgp(bmsimple) workers(2000) firms(80) periods(4) ///
        seed(876) truth(`mode') noreport clear
    assert `"`r(dgp_alias)'"' == "bmsimple"
    assert `"`c(rngstate)'"' == `"`caller'"'
    assert c(k) == cond("`mode'" == "none", 13, 16)
    matrix F_mode = r(bm_flows)
    assert mreldif(F, F_mode) == 0
    cf `basevars' using `base'
}

* Same continuous history at different output frequencies.
quietly fesim, dgp(bm) workers(500) firms(50) periods(3) start(2000) ///
    seed(12897) truth(full) noreport clear
keep workerid time firmid employed lnwage spellid tenure unemp_duration
quietly save `annual'
foreach frequency in quarter month {
    local scale = cond("`frequency'" == "quarter", 4, 12)
    local start = cond("`frequency'" == "quarter", "2000q1", "2000m1")
    quietly fesim, dgp(bm) workers(500) firms(50) periods(`=3*`scale'') ///
        frequency(`frequency') start(`start') seed(12897) truth(none) noreport clear
    by workerid: keep if mod(_n, `scale') == 0
    by workerid: replace time = 1999 + _n
    replace tenure = tenure / `scale'
    replace unemp_duration = unemp_duration / `scale'
    cf workerid time firmid employed lnwage spellid using `annual'
    rename (tenure unemp_duration) (tenure_f unemp_duration_f)
    merge 1:1 workerid time using `annual', assert(match) nogen
    assert reldif(tenure, tenure_f) < 1e-10 | missing(tenure, tenure_f)
    assert reldif(unemp_duration, unemp_duration_f) < 1e-10 | missing(unemp_duration, unemp_duration_f)
}

* Largest component keeps complete workers and recomputes sample event moments.
quietly fesim, dgp(bm) workers(500) firms(100) periods(2) seed(42) ///
    connectivity(largest) truth(full) noreport clear
matrix F = r(bm_flows)
assert mod(_N,2) == 0
assert `"`r(bm_theory_scope)'"' == "unconditioned_finite_economy"
quietly summarize n_eu_true, meanonly
scalar eu_total = r(sum)
quietly summarize employment_exposure_true, meanonly
assert abs(F["eu","event"] - eu_total/r(sum)) < 1e-12

quietly fesim, dgp(bm) workers(100) firms(1) periods(1) seed(42) ///
    initial(allunemployed) truth(full) noreport clear
assert n_ee_true == 0
quietly fesim, dgp(bm) workers(100) firms(30) periods(3) seed(42) ///
    initial(random) burnin(.25) parameters(random_firms 1) noreport clear
assert `"`: char _dta[fesim_bm_firm_mode]'"' == "random"
assert `"`r(calibration_class)'"' == "stylized_modified"

* A fully unemployed singleton panel is a valid returned sample.
quietly fesim, dgp(bm) workers(1) firms(1) periods(1) seed(42) ///
    initial(allunemployed) parameters(lambda_u .000001 lambda_e .000001) ///
    truth(none) noreport clear
assert _N == 1 & employed == 0
assert r(N_firms_active) == 0

* Unseeded runs consume exactly one caller draw for the master seed.
set seed 9999
mata: expected = runiformint(1,1,0,2147483647)
local continuation `"`c(rngstate)'"'
set seed 9999
quietly fesim, dgp(bm) workers(20) firms(10) periods(2) noreport clear
assert `"`c(rngstate)'"' == `"`continuation'"'

* Preflight and numerical failures preserve caller data, labels, and RNG.
clear
set obs 3
generate sentinel = _n
label variable sentinel "caller data"
local caller `"`c(rngstate)'"'
foreach bad in "parameters(p .3)" "parameters(lambda_e 0)" ///
    "parameters(random_firms 2)" "network(blocks)" "initial(random)" {
    capture noisily fesim, dgp(bm) `bad' clear
    assert _rc == 198
    assert sentinel == _n
    assert `"`c(rngstate)'"' == `"`caller'"'
}
capture noisily fesim, dgp(bm) connectivity(force) clear
assert _rc == 498
capture noisily fesim, dgp(bm)
assert _rc == 4
capture noisily fesim, dgp(bm) parameters(b -100 lambda_u .1) clear
assert _rc != 0
assert sentinel == _n
assert `"`: variable label sentinel'"' == "caller data"
assert `"`c(rngstate)'"' == `"`caller'"'
di as result "FESIM PUBLIC BM TESTS PASS"
