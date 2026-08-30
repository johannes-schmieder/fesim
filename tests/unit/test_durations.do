version 16.0
clear all
set more off
set varabbrev off

set rng mt64
set seed 31415926
local rng_before `"`c(rngstate)'"'

input byte employed double tenure double unemp_duration
1 0   .
1 .5  .
0 .   .25
0 .   1
1 2   .
0 .   2
end
quietly datasignature set, reset

quietly _fesim_durations, deltayears(.25)
matrix durations = r(durations)
assert rowsof(durations) == 12
assert colsof(durations) == 1
assert durations["tenure_years_N", "realized"] == 3
assert durations["unemployment_duration_years_N", "realized"] == 3
quietly summarize tenure if employed
assert reldif(durations["tenure_years_mean", "realized"], ///
    r(mean) * .25) < 1e-12
assert reldif(durations["tenure_years_sd", "realized"], ///
    r(sd) * .25) < 1e-12
quietly _pctile tenure if employed, percentiles(10 50 90)
assert durations["tenure_years_p10", "realized"] == r(r1) * .25
assert durations["tenure_years_p50", "realized"] == r(r2) * .25
assert durations["tenure_years_p90", "realized"] == r(r3) * .25
quietly summarize unemp_duration if !employed
assert reldif( ///
    durations["unemployment_duration_years_mean", "realized"], ///
    r(mean) * .25) < 1e-12
quietly _pctile unemp_duration if !employed, percentiles(10 50 90)
assert durations["unemployment_duration_years_p10", "realized"] == ///
    r(r1) * .25
assert durations["unemployment_duration_years_p50", "realized"] == ///
    r(r2) * .25
assert durations["unemployment_duration_years_p90", "realized"] == ///
    r(r3) * .25
quietly datasignature confirm
assert `"`c(rngstate)'"' == `"`rng_before'"'

capture noisily _fesim_durations, deltayears(0)
assert _rc == 198
quietly replace tenure = -1 in 1
capture noisily _fesim_durations, deltayears(.25)
assert _rc == 459

di as result "FESIM DURATION DIAGNOSTIC TESTS PASS"
