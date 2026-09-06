version 19.0
clear all
set more off
set varabbrev off
args root sha preset workers firms frequency truth result
capture log close _all
log using `"`result'.stata.log"', text replace
quietly adopath ++ `"`root'"'
local periods=cond("`frequency'"=="month",120,10)
capture noisily fesim, dgp(cpv) preset(`preset') workers(`workers') ///
    firms(`firms') periods(`periods') frequency(`frequency') seed(20260912) ///
    truth(`truth') connectivity(keep) noreport clear
local rc=_rc
if `rc' exit `rc', STATA clear
foreach name in runtime_total runtime_solve runtime_simulate runtime_output ///
    cpv_events cpv_peak_block_rows cpv_block_workers {
    local `name'=r(`name')
}
local N=_N
quietly describe, short
local width=r(width)
quietly datasignature
local signature "`r(datasignature)'"
tempname handle
file open `handle' using `"`result'"', write text replace
file write `handle' "{" _n
file write `handle' `"  "sha": "`sha'","' _n
file write `handle' `"  "status": "passed","' _n
file write `handle' `"  "preset": "`preset'","' _n
file write `handle' `"  "truth": "`truth'","' _n
file write `handle' `"  "frequency": "`frequency'","' _n
file write `handle' `"  "workers": `workers',"' _n
file write `handle' `"  "firms": `firms',"' _n
file write `handle' `"  "periods": `periods',"' _n
file write `handle' `"  "observations": `N',"' _n
file write `handle' `"  "dataset_width": `width',"' _n
file write `handle' `"  "signature": "`signature'","' _n
foreach name in runtime_total runtime_solve runtime_simulate runtime_output ///
    cpv_events cpv_peak_block_rows {
    local numeric=strtrim(string(``name'',"%21.15f"))
    file write `handle' `"  "`name'": `numeric',"' _n
}
file write `handle' `"  "cpv_block_workers": `cpv_block_workers'"' _n
file write `handle' "}" _n
file close `handle'
display "FESIM CPV BENCHMARK PASS"
exit, STATA clear
