version 16.0
clear all
set more off
set varabbrev off

capture noisily fesim nonsense
local rc = _rc
assert `rc' == 198

capture noisily fesim list extra
local rc = _rc
assert `rc' == 198

capture noisily fesim presets akm extra
local rc = _rc
assert `rc' == 198

capture noisily fesim describe
local rc = _rc
assert `rc' == 198

capture noisily fesim describe unknown
local rc = _rc
assert `rc' == 198

capture noisily fesim describe akm, preset(unknown)
local rc = _rc
assert `rc' == 198

capture noisily fesim describe akmsimple, preset(stylized)
local rc = _rc
assert `rc' == 198

capture noisily fesim, workers(0) clear
local rc = _rc
assert `rc' == 198

capture noisily fesim, firms(0) clear
local rc = _rc
assert `rc' == 198

capture noisily fesim, periods(0) clear
local rc = _rc
assert `rc' == 198

capture noisily fesim, burnin(-1) clear
local rc = _rc
assert `rc' == 198

capture noisily fesim, frequency(week) clear
local rc = _rc
assert `rc' == 198

capture noisily fesim, frequency(quarter) start(2000m1) clear
local rc = _rc
assert `rc' == 198

capture noisily fesim, seed(notaninteger) clear
local rc = _rc
assert `rc' == 198

capture noisily fesim, dgp(akm) preset(simple) report noreport clear
local rc = _rc
assert `rc' == 198

capture noisily fesim, parameters(mu 4 mu 5) clear
local rc = _rc
assert `rc' == 198

capture noisily fesim, unsupported_option clear
local rc = _rc
assert `rc' == 198

capture noisily fesim, mu(4) clear
local rc = _rc
assert `rc' == 198

capture noisily fesim, sdworker(.5) clear
local rc = _rc
assert `rc' == 198

capture noisily fesim workerid, clear
local rc = _rc
assert `rc' == 198

capture noisily fesim if 1, clear
local rc = _rc
assert `rc' == 198

capture noisily fesim in 1, clear
local rc = _rc
assert `rc' == 198

capture noisily fesim, workers(10) firms(2) periods(2) ///
    seed(12345) noreport clear
local rc = _rc
assert `rc' == 0
assert _N == 20

capture noisily fesim, dgp(akmsimple) workers(10) firms(2) periods(2) ///
    frequency(year) start(2000) seed(12345) noreport clear
local rc = _rc
assert `rc' == 0
assert _N == 20

di as result "FESIM PARSER TESTS PASS"
