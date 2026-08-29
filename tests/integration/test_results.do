version 16.0
clear all
set more off
set varabbrev off

set rng mt64
set seed 27182818
local rng_before `"`c(rngstate)'"'

quietly fesim_config, dgp(akmsimple) workers(7) firms(3) periods(5) ///
    frequency(quarter) start(2000q1) seed(12345) noreport
matrix toy_parameters = r(parameters)
scalar toy_start = r(start_value)

mata: toy_resultset = fesim_dispatch_run("_toy", "deterministic", 7, 3, 5)
mata: assert(fesim_output_lifecycle_panel(toy_resultset, ///
    st_numscalar("toy_start"), "%tq", "basic", 2, 0) == 35)
mata: st_matrix("toy_moments", toy_resultset.moments')
matrix rownames toy_moments = employment_rate mean_lnwage
matrix colnames toy_moments = realized

local finalize_options ///
    dgp(_toy) dgpalias(_toy) preset(deterministic) ///
    calibrationclass(internal_test) ///
    command("fesim internal deterministic workers=7 firms=3 periods=5") ///
    seed(none) rng(none) rngmethod(deterministic_no_rng) ///
    frequency(quarter) internalclock(output_period) jobrule(end) ///
    truth(basic) burnin(0) connectivity(keep) reference(none) ///
    workers(7) firms(3) periods(5) firmsactive(3) ///
    employmentrate(`=toy_moments[1,1]') ///
    runtimetotal(.04) runtimesolve(0) runtimesimulate(.03) ///
    runtimeoutput(.01) parameters(toy_parameters) moments(toy_moments)

_fesim_finalize, `finalize_options' reporting(report)

assert r(N) == 35
assert r(N_workers) == 7
assert r(N_firms) == 3
assert r(N_firms_active) == 3
assert r(periods) == 5
assert reldif(r(employment_rate), toy_moments[1,1]) < 1e-12
assert missing(r(p_eu_realized))
assert missing(r(p_ue_realized))
assert missing(r(p_ee_realized))
assert missing(r(components))
assert r(runtime_total) == .04
assert r(runtime_solve) == 0
assert r(runtime_simulate) == .03
assert r(runtime_output) == .01
assert `"`r(dgp)'"' == "_toy"
assert `"`r(dgp_alias)'"' == "_toy"
assert `"`r(preset)'"' == "deterministic"
assert `"`r(calibration_class)'"' == "internal_test"
assert `"`r(frequency)'"' == "quarter"
assert `"`r(internal_clock)'"' == "output_period"
assert `"`r(jobrule)'"' == "end"
assert `"`r(seed)'"' == "none"
assert `"`r(rng)'"' == "none"
assert `"`r(command)'"' == ///
    "fesim internal deterministic workers=7 firms=3 periods=5"
assert `"`r(version)'"' == "0.0.0-dev"
assert `"`r(reference)'"' == "none"
matrix report_parameters = r(parameters)
matrix report_moments = r(moments)
assert mreldif(report_parameters, toy_parameters) == 0
assert mreldif(report_moments, toy_moments) == 0

foreach characteristic in version dgp dgp_alias preset calibration_class ///
    command seed rng frequency internal_clock jobrule burnin connectivity ///
    reference rng_method stata_version truth {
    local characteristic_value : char _dta[fesim_`characteristic']
    assert strtrim(`"`characteristic_value'"') != ""
}
local metadata_command : char _dta[fesim_command]
assert `"`metadata_command'"' == ///
    "fesim internal deterministic workers=7 firms=3 periods=5"
local metadata_burnin : char _dta[fesim_burnin]
assert `"`metadata_burnin'"' == "0"

local report_command `"`r(command)'"'
scalar report_N = r(N)
scalar report_runtime_total = r(runtime_total)
quietly datasignature set, reset

quietly _fesim_finalize, `finalize_options' reporting(noreport)
assert r(N) == report_N
assert r(runtime_total) == report_runtime_total
assert `"`r(command)'"' == `"`report_command'"'
matrix noreport_parameters = r(parameters)
matrix noreport_moments = r(moments)
mata: assert(mreldif(st_matrix("noreport_parameters"), ///
    st_matrix("report_parameters")) == 0)
mata: assert(mreldif(st_matrix("noreport_moments"), ///
    st_matrix("report_moments")) == 0)
quietly datasignature confirm
assert `"`c(rngstate)'"' == `"`rng_before'"'

capture _fesim_finalize, `finalize_options' reporting(invalid)
assert _rc == 198
quietly datasignature confirm
assert `"`c(rngstate)'"' == `"`rng_before'"'

di as result "FESIM COMMON METADATA AND RETURNED-RESULT TESTS PASS"
