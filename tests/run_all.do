version 16.0
clear all
set more off
set varabbrev off

args requested_root requested_sha requested_suite requested_branch
local repository_root `"`requested_root'"'
if `"`repository_root'"' == "" local repository_root `"`c(pwd)'"'
local source_sha = lower(strtrim(`"`requested_sha'"'))
local suite = lower(strtrim(`"`requested_suite'"'))
if `"`suite'"' == "" local suite "quick"
local branch = strtrim(`"`requested_branch'"')
if `"`branch'"' == "" local branch "unknown"
local started_at `"`c(current_date)' `c(current_time)'"'
if `"`source_sha'"' != "" & ///
    (strlen(`"`source_sha'"') != 40 | !regexm(`"`source_sha'"', "^[0-9a-f]+$")) {
    di as error "requested_sha must be an exact 40-character lowercase Git SHA"
    exit 198
}

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

local tests install_smoke smoke unit/test_parser unit/test_registry ///
    unit/test_config unit/test_time unit/test_rates unit/test_rng unit/test_lifecycle integration/test_discovery ///
    integration/test_output_blocks
local n_tests : word count `tests'
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

if `"`source_sha'"' != "" {
    local finished_at `"`c(current_date)' `c(current_time)'"'
    local receipt_path `"`repository_root'/build/test-results/receipt-`source_sha'.json"'
    tempname receipt
    file open `receipt' using `"`receipt_path'"', write text replace
    file write `receipt' "{" _n
    file write `receipt' `"  "repository": "`repository_root'","' _n
    file write `receipt' `"  "sha": "`source_sha'","' _n
    file write `receipt' `"  "branch": "`branch'","' _n
    file write `receipt' `"  "stata_version": "`=c(stata_version)'","' _n
    file write `receipt' `"  "stata_flavor": "`c(edition_real)'","' _n
    file write `receipt' `"  "os": "`c(os)'","' _n
    file write `receipt' `"  "architecture": "`c(machine_type)'","' _n
    file write `receipt' `"  "suite": "`suite'","' _n
    file write `receipt' `"  "started_at": "`started_at'","' _n
    file write `receipt' `"  "finished_at": "`finished_at'","' _n
    file write `receipt' `"  "exit_code": 0,"' _n
    file write `receipt' `"  "tests_passed": `n_tests',"' _n
    file write `receipt' `"  "tests_failed": 0,"' _n
    file write `receipt' `"  "mlib_rebuilt": true,"' _n
    file write `receipt' `"  "status": "accepted""' _n
    file write `receipt' "}" _n
    file close `receipt'
    di as result "ACCEPTED RECEIPT: `receipt_path'"
}

di as result _newline "ALL FESIM CURRENT STATA TEST FILES PASSED"
exit 0
