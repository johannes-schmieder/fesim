version 19.0
clear all
set more off
set varabbrev off

local repository_root `"`c(pwd)'"'
capture noisily do `"`repository_root'/tests/run_all.do"' ///
    `"`repository_root'"' "" full windows
local suite_rc = _rc
if `suite_rc' exit `suite_rc'

tempname status
file open `status' using `"`repository_root'/windows-ci.status"', ///
    write text replace
file write `status' "WINDOWS_CI=PASS"
file close `status'

di as result "FESIM WINDOWS QUALIFICATION PASS"
exit 0
