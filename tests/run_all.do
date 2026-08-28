version 16.0
clear all
set more off
set varabbrev off

args requested_root
local repository_root `"`requested_root'"'
if `"`repository_root'"' == "" local repository_root `"`c(pwd)'"'

capture confirm file `"`repository_root'/fesim.ado"'
if _rc {
    di as error "repository root does not contain fesim.ado: `repository_root'"
    exit 601
}

capture mkdir `"`repository_root'/build"'
capture mkdir `"`repository_root'/build/test-results"'
capture mkdir `"`repository_root'/build/stata-personal"'
capture mkdir `"`repository_root'/build/stata-plus"'

sysdir set PERSONAL `"`repository_root'/build/stata-personal"'
sysdir set PLUS `"`repository_root'/build/stata-plus"'

capture noisily do `"`repository_root'/src/build_mlib.do"' `"`repository_root'"' `"`repository_root'/build"'
local build_rc = _rc
if `build_rc' {
    di as error "fesim Mata build failed (rc=`build_rc')"
    exit `build_rc'
}

local tests install_smoke smoke unit/test_parser integration/test_discovery
foreach test of local tests {
    capture log close fesim_test
    discard
    if `"`test'"' != "install_smoke" quietly adopath + `"`repository_root'"'
    log using `"`repository_root'/build/test-results/`=subinstr("`test'","/","_",.)'.log"', ///
        text replace name(fesim_test)
    di as txt _newline "===== RUNNING `test' ====="
    capture noisily do `"`repository_root'/tests/`test'.do"' `"`repository_root'"'
    local test_rc = _rc
    di as txt "===== `test' rc=`test_rc' ====="
    log close fesim_test
    if `test_rc' {
        di as error "fesim Stata test failed: `test' (rc=`test_rc')"
        exit `test_rc'
    }
}

di as result _newline "ALL FESIM CHECKPOINT 1 STATA TEST FILES PASSED"
exit 0
