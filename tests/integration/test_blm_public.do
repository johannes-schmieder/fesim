version 19.0
clear all
set more off
set seed 27541
local rng "`c(rngstate)'"
quietly fesim describe blm
assert "`r(preset)'"=="static" & "`r(initial_modes)'"=="random"
assert rowsof(r(parameters))==16 & colsof(r(parameters))==4
assert rowsof(r(blm_destination))==60
matrix WW=(1,3)
matrix FW=(1,2,1)
matrix MU=(1,2,3\4,4,5)
matrix SD=(.1,.2,0\.3,.1,.2)
matrix RATE=(.5,1,2\.2,.3,.8)
matrix DEST=(2,1,3\1,2,3\1,1,4\1,2,1\2,1,1\1,3,1)
matrix RHO=J(2,3,.4)
matrix G=J(2,3,-1)
matrix C=J(6,3,.05)
matrix WW_before=WW
matrix DEST_before=DEST
quietly fesim, dgp(blm) preset(dynamic) workers(1000) firms(9) periods(6) ///
    frequency(month) burnin(0) seed(671) truth(full) parameters(worker_types 2 firm_types 3 ///
    worker_weights WW firm_weights FW mean_matrix MU sd_matrix SD move_rate_matrix RATE ///
    destination_matrix DEST rho_matrix RHO mobility_wage_matrix G move_shift_matrix C) clear
assert "`c(rngstate)'"=="`rng'"
mata: assert(st_matrix("WW")==st_matrix("WW_before"))
mata: assert(st_matrix("DEST")==st_matrix("DEST_before"))
mata: assert(st_matrix("r(blm_mean)")==st_matrix("MU"))
assert r(N)==6000 & r(employment_rate)==1
matrix CELL=r(blm_cells)
assert colsof(CELL)==6 & rowsof(CELL)==6
assert rowsof(r(blm_workers))==2
local model `"`r(blm_model)'"'
local config `"`r(command)'"'
assert "`r(calibration_class)'"=="stylized_modified"
assert employed==1 & missing(unemp_duration)
assert lnwage==lnwage_true
assert abs(lnwage-conditional_mean_true-epsilon_true)<1e-12
assert abs(conditional_mean_true-wage_location_true-persistence_true-move_shift_true)<1e-12
bysort workerid (time): assert ntransitions==n_ee_true if _n>1
bysort workerid (time): assert spellid==spellid[_n-1]+n_ee_true if _n>1
bysort workerid (time): assert lag_lnwage_true==lnwage[_n-1] if _n>1
assert tenure==0 if moved_month_true
bysort workerid (time): assert tenure==tenure[_n-1]+1 if _n>1 & !moved_month_true
assert epsilon_true==0 if innovation_sd_true==0
* Values, not matrix names, define provenance and seeded output.
tempfile reference
quietly save `reference'
matrix RENAMED=MU
quietly fesim, dgp(blm) preset(dynamic) workers(1000) firms(9) periods(6) ///
    frequency(month) burnin(0) seed(671) truth(full) parameters(worker_types 2 firm_types 3 ///
    worker_weights WW firm_weights FW mean_matrix RENAMED sd_matrix SD move_rate_matrix RATE ///
    destination_matrix DEST rho_matrix RHO mobility_wage_matrix G move_shift_matrix C) clear
assert `"`r(blm_model)'"'==`"`model'"'
assert `"`r(command)'"'==`"`config'"'
quietly cf _all using `reference'
* Invalid inputs leave caller data, RNG and source matrices intact.
quietly datasignature
local signature "`r(datasignature)'"
matrix BAD=J(1,1,.)
matrix ZERO=J(1,1,0)
local bad1 "initial(stationary)"
local bad2 "initial(allunemployed)"
local bad3 "burnin(.1)"
local bad4 "parameters(worker_types 21)"
local bad5 "parameters(firm_types 20) firms(5)"
local bad6 "parameters(worker_types 1 firm_types 1 mean_matrix BAD)"
local bad7 "parameters(worker_types 1 firm_types 1 mean_matrix ZERO mu 2)"
local bad8 "parameters(worker_types 1 firm_types 1 worker_weights ZERO)"
local bad9 "parameters(worker_types 1 firm_types 1 destination_matrix ZERO)"
local bad10 "parameters(rho .3)"
local bad11 "parameters(mobility_wage -1)"
local bad12 "parameters(origin_dependence .1)"
local bad13 "parameters(mean_matrix MU mean_matrix MU)"
local bad14 "parameters(mean_matrix absent_matrix)"
local bad15 "network(ladder)"
local bad16 "parameters(worker_types 1 firm_types 1 rho 1)"
local bad17 "parameters(worker_types 1 firm_types 1 sd_error -1)"
local bad18 "workers(10000000) periods(1000)"
local bad19 "workers(10000000) periods(10) burnin(100)"
local bad20 "parameters(worker_types 1 firm_types 1 destination_matrix ZERO lambda_move 0)"
local bad21 "preset(dynamic) parameters(rho .9999999999999999)"
forvalues i=1/21 {
    capture noisily fesim, dgp(blm) seed(777) clear `bad`i''
    assert _rc==198
    assert "`c(rngstate)'"=="`rng'"
    quietly datasignature
    assert "`r(datasignature)'"=="`signature'"
    mata: assert(st_matrix("WW")==st_matrix("WW_before"))
    mata: assert(st_matrix("DEST")==st_matrix("DEST_before"))
}
* Failure after simulation begins also rolls back.
capture noisily fesim, dgp(blm) workers(10) firms(2) periods(2) burnin(0) seed(345) ///
    parameters(worker_types 1 firm_types 1 sd_error 1e200) clear
assert _rc==430
assert "`c(rngstate)'"=="`rng'"
quietly datasignature
assert "`r(datasignature)'"=="`signature'"
* Self-only rows are infeasible when an actual alternative is needed.
matrix SELF=(1,0\0,1)
capture noisily fesim, dgp(blm) workers(10) firms(2) periods(2) ///
    parameters(worker_types 1 firm_types 2 destination_matrix SELF) clear
assert _rc==198
* With a single firm, positive requested intensity still produces zero moves.
quietly fesim, dgp(blm) preset(dynamic) workers(30) firms(1) periods(4) burnin(0) ///
    parameters(worker_types 1 firm_types 1) seed(3) truth(full) clear noreport
assert firmid==1 & spellid==1 & n_ee_true==0 & move_probability_true==0
* Every month moves to the other actual firm, while class remains unchanged.
quietly fesim, dgp(blm) workers(20) firms(2) periods(4) burnin(0) ///
    parameters(worker_types 1 firm_types 1 lambda_move 1e6) seed(3) truth(full) clear noreport
assert n_ee_true==12 & firm_type_true==1
by workerid: assert jobtojob==0 & newjob==1 & ntransitions==12 if _n>1
assert tenure==0
* Largest keeps whole workers and recomputes realized type-cell counts.
quietly fesim, dgp(blm) workers(30) firms(12) periods(3) burnin(0) ///
    parameters(lambda_move 0) seed(3) truth(full) connectivity(largest) clear noreport
matrix GEN=r(blm_cells_generated)
matrix RET=r(blm_cells)
mata: assert(sum(st_matrix("GEN")[,1])==90)
mata: assert(sum(st_matrix("RET")[,1])==st_nobs())
by workerid: assert _N==3
assert "`c(rngstate)'"=="`rng'"
display "FESIM BLM PUBLIC PASS"
