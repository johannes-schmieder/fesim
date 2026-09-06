version 19.0
set more off
set varabbrev off
args repository_root
if "`repository_root'" == "" local repository_root "`c(pwd)'"
quietly adopath ++ "`repository_root'"
set scheme s2color
capture mkdir "`repository_root'/docs/manual_figures"
local scripts 01_akm 02_mobility 03_paygap 04_bm 05_bm_paths 06_bm_flows 07_cpv_paths 08_cpv_dispersion 09_cpv_bargaining 10_cpv_movers 11_blm_interactions 12_blm_sorting 13_blm_dynamics 14_blm_movers
local graphs fesim_akm fesim_mobility fesim_paygap fesim_bm fesim_bm_paths fesim_bm_flows fesim_cpv_paths fesim_cpv_dispersion fesim_cpv_bargaining fesim_cpv_movers fesim_blm_interactions fesim_blm_sorting fesim_blm_dynamics fesim_blm_movers
forvalues index=1/14 {
    local script : word `index' of `scripts'
    local graph : word `index' of `graphs'
    do "`repository_root'/docs/manual_examples/`script'.do"
    graph export "`repository_root'/docs/manual_figures/`script'.pdf", ///
        name(`graph') replace
}
display as result "FESIM MANUAL FIGURES PASS"
