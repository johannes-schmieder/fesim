version 19.0
clear all
set more off
set varabbrev off
args root sha preset workers firms frequency truth worker_types firm_types result
capture log close _all
log using `"`result'.stata.log"', text replace
quietly adopath ++ `"`root'"'
local periods=cond("`frequency'"=="month",120,10)
capture noisily fesim, dgp(blm) preset(`preset') workers(`workers') ///
    firms(`firms') periods(`periods') frequency(`frequency') seed(20260926) ///
    truth(`truth') burnin(20) parameters(worker_types `worker_types' firm_types `firm_types') connectivity(keep) noreport clear
local rc=_rc
if `rc' exit `rc', STATA clear
foreach name in runtime_total runtime_solve runtime_simulate runtime_output ///
    blm_moves_generated blm_worker_months blm_peak_block_rows blm_block_workers {
    local `name'=r(`name')
}
local model_fingerprint "`r(blm_fingerprint)'"
assert r(N)==`workers'*`periods'
assert r(blm_worker_months)==`workers'*360
assert r(blm_peak_block_rows)<=max(100000,`periods')
assert employed==1 & missing(unemp_duration)
if "`truth'"=="full" assert abs(lnwage-conditional_mean_true-epsilon_true)<1e-12
matrix cells=r(blm_cells)
mata: assert(sum(st_matrix("cells")[,1])==st_nobs())
local N=_N
quietly describe, short
local width=r(width)
quietly datasignature
local signature "`r(datasignature)'"
tempname handle
file open `handle' using `"`result'"', write text replace
file write `handle' "{" _n
file write `handle' `"  "worker_types": `worker_types',"' _n
file write `handle' `"  "firm_types": `firm_types',"' _n
file write `handle' `"  "model_fingerprint": "`model_fingerprint'","' _n
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
    blm_moves_generated blm_worker_months blm_peak_block_rows {
    local numeric=strtrim(string(``name'',"%21.15f"))
    file write `handle' `"  "`name'": `numeric',"' _n
}
file write `handle' `"  "blm_block_workers": `blm_block_workers'"' _n
file write `handle' "}" _n
file close `handle'
display "FESIM BLM BENCHMARK PASS"
exit, STATA clear
