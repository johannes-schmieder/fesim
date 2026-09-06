version 16
clear all
set more off
set varabbrev off
quietly _fesim_load
mata:
void cpv_stream(real scalar block) {
    real scalar seed
    seed=fesim_cpv_simulate_to_stata(1201,30,5,2000,"%ty","year",23457,1,
        "stationary",.25,"full",(1,1.5,2,.5,.3,.2,.05,.5,.4,1),1,
        "S","F","T",(.,.,.),block,10000000)
    assert(seed==23457)
}
end
local caller "`c(rngstate)'"
mata: cpv_stream(1201)
tempfile reference
quietly save `reference'
foreach block in 1 7 333 {
    clear
    mata: cpv_stream(`block')
    assert "`c(rngstate)'"=="`caller'"
    cf _all using `reference'
    assert T[1,5]<=`block'*5
}
local snapshots "workerid firmid employed lnwage spellid tenure unemp_duration contract_wage_true bargaining_firm_true employment_value_true"
local counts "n_eu_true n_ee_true n_ue_true n_renegotiations_true n_events_true employment_exposure_true unemployment_exposure_true"
quietly fesim, dgp(cpv) workers(500) firms(30) periods(5) frequency(year) burnin(.25) truth(full) seed(333) clear noreport
mata: annual=st_data(.,tokens(st_local("snapshots"))); counts=colsum(st_data(.,tokens(st_local("counts"))))
foreach frequency in quarter month {
    local scale=cond("`frequency'"=="quarter",4,12)
    quietly fesim, dgp(cpv) workers(500) firms(30) periods(`=5*`scale'') frequency(`frequency') burnin(.25) truth(full) seed(333) clear noreport
    mata: assert(mreldif(counts,colsum(st_data(.,tokens(st_local("counts")))))<1e-12)
    by workerid: keep if mod(_n,`scale')==0
    replace tenure=tenure/`scale'
    replace unemp_duration=unemp_duration/`scale'
    mata: assert(mreldif(annual,st_data(.,tokens(st_local("snapshots"))))<1e-12)
}
display "CPV BLOCK AND FREQUENCY INVARIANCE PASS"
