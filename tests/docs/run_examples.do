version 16.0
clear all
set more off
set varabbrev off

args repository_root
capture noisily do `"`repository_root'/examples/akmsimple.do"'
assert _rc == 0
assert `"`e(cmd)'"' == "areg"
assert e(N) > 0
assert _N > 0 & _N <= 6 * 500
assert mod(_N, 6) == 0
isid workerid time

capture noisily do `"`repository_root'/examples/akm_stylized.do"'
assert _rc == 0
assert _N == 6000
assert `"`r(calibration_class)'"' == "stylized_modified"
isid workerid time

capture noisily do `"`repository_root'/examples/akm_germany_chk.do"'
assert _rc == 0
assert _N == 8000
assert `"`r(calibration_class)'"' == "targeted"
assert rowsof(r(targets)) == 10
isid workerid time

di as result "FESIM DOCUMENTED EXAMPLES PASS"
