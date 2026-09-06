version 19.0
clear all
set more off
args repository_root
if "`repository_root'"=="" local repository_root "`c(pwd)'"
set obs 3
generate caller_id=_n
datasignature set
set seed 7654321
local rng "`c(rngstate)'"
foreach example in 01_akm 02_mobility 03_paygap 04_bm 05_bm_paths 06_bm_flows 07_cpv_paths 08_cpv_dispersion 09_cpv_bargaining 10_cpv_movers {
    do "`repository_root'/docs/manual_examples/`example'.do"
    datasignature confirm
    assert "`c(rngstate)'"=="`rng'"
}
display "FESIM MANUAL EXAMPLES AND CALLER STATE PASS"
