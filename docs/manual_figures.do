version 19.0
set more off
set varabbrev off
args repository_root
if "`repository_root'" == "" local repository_root "`c(pwd)'"
quietly adopath ++ "`repository_root'"
set scheme s2color
capture mkdir "`repository_root'/docs/manual_figures"
local scripts 01_akm 02_mobility 03_paygap 04_bm 05_bm_paths 06_bm_flows
local graphs fesim_akm fesim_mobility fesim_paygap fesim_bm fesim_bm_paths fesim_bm_flows
forvalues index=1/6 {
    local script : word `index' of `scripts'
    local graph : word `index' of `graphs'
    do "`repository_root'/docs/manual_examples/`script'.do"
    graph export "`repository_root'/docs/manual_figures/`script'.pdf", ///
        name(`graph') replace
}
display as result "FESIM MANUAL FIGURES PASS"
