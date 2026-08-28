version 16.0
clear all
set more off
set varabbrev off

set seed 8675309
set obs 5
generate long original_id = _n
generate double original_value = runiform()
quietly datasignature set, reset
local rng_before `"`c(rngstate)'"'

quietly fesim version
quietly datasignature confirm
assert `"`c(rngstate)'"' == `"`rng_before'"'

quietly fesim list
quietly datasignature confirm
assert `"`c(rngstate)'"' == `"`rng_before'"'

quietly fesim presets
quietly datasignature confirm
assert `"`c(rngstate)'"' == `"`rng_before'"'

quietly fesim presets akm
quietly datasignature confirm
assert `"`c(rngstate)'"' == `"`rng_before'"'

quietly fesim describe AKMSIMPLE
quietly datasignature confirm
assert `"`c(rngstate)'"' == `"`rng_before'"'

quietly fesim_config, dgp(AKMSIMPLE) workers(25) ///
    parameters(mu 4 p_ee .2)
quietly datasignature confirm
assert `"`c(rngstate)'"' == `"`rng_before'"'

capture noisily fesim, dgp(akmsimple)
local rc = _rc
assert `rc' == 4
quietly datasignature confirm
assert `"`c(rngstate)'"' == `"`rng_before'"'

capture noisily fesim, dgp(unknown) clear
local rc = _rc
assert `rc' == 198
quietly datasignature confirm
assert `"`c(rngstate)'"' == `"`rng_before'"'

capture noisily fesim, dgp(akmsimple) seed(24680) clear
local rc = _rc
assert `rc' == 498
quietly datasignature confirm
assert `"`c(rngstate)'"' == `"`rng_before'"'

di as result "FESIM DISCOVERY AND STATE-PRESERVATION TESTS PASS"
