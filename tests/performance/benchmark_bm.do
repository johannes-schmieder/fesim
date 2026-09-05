version 16.0
clear all
set more off
set varabbrev off
args root sha workers truth result
capture log close _all
log using `"`result'.stata.log"', text replace
quietly adopath ++ `"`root'"'
capture noisily fesim, dgp(bm) workers(`workers') firms(500) periods(10) ///
    seed(20260905) truth(`truth') connectivity(keep) noreport clear
local rc = _rc
if `rc' exit `rc', STATA clear
foreach name in runtime_total runtime_solve runtime_simulate runtime_output ///
    bm_events bm_peak_block_events bm_peak_block_rows bm_block_workers {
    local `name' = r(`name')
}
local N = _N
quietly describe, short
local width = r(width)
tempname handle
file open `handle' using `"`result'"', write text replace
file write `handle' "{" _n
file write `handle' `"  "sha": "`sha'","' _n
file write `handle' `"  "status": "passed","' _n
file write `handle' `"  "truth": "`truth'","' _n
file write `handle' `"  "workers": `workers',"' _n
file write `handle' `"  "worker_years": `N',"' _n
file write `handle' `"  "dataset_width": `width',"' _n
foreach name in runtime_total runtime_solve runtime_simulate runtime_output ///
    bm_events bm_peak_block_events bm_peak_block_rows {
    local numeric = strtrim(string(``name'', "%21.15f"))
    file write `handle' `"  "`name'": `numeric',"' _n
}
file write `handle' `"  "bm_block_workers": `bm_block_workers'"' _n
file write `handle' "}" _n
file close `handle'
di as result "FESIM BM BENCHMARK PASS"
exit 0, STATA clear
