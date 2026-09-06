version 19.0
clear all
set more off
set seed 23172
local caller "`c(rngstate)'"
tempfile stat annual monthly
* Exact static/dynamic nesting, including nondefault weights and burn-in.
quietly fesim, dgp(blm) workers(101) firms(15) periods(5) seed(222) truth(full) clear noreport
quietly save `stat'
quietly fesim, dgp(blm) preset(dynamic) workers(101) firms(15) periods(5) seed(222) truth(full) ///
    parameters(rho 0 mobility_wage 0 origin_dependence 0) clear noreport
quietly cf _all using `stat'
foreach preset in static dynamic {
    quietly fesim, dgp(blm) preset(`preset') workers(101) firms(15) periods(5) ///
        seed(832) truth(full) clear noreport
    generate double years=tenure
    by workerid: generate double cum_moves=sum(n_ee_true)
    keep workerid time firmid lnwage spellid years cum_moves worker_type_true firm_type_true ///
        lag_lnwage_true lag_firm_type_true persistence_true move_shift_true innovation_sd_true move_probability_true
    replace time=time-2000+1
    quietly save `annual', replace
    foreach frequency in quarter month {
        local factor=cond("`frequency'"=="month",12,4)
        quietly fesim, dgp(blm) preset(`preset') workers(101) firms(15) periods(`=5*`factor'') ///
            frequency(`frequency') seed(832) truth(full) clear noreport
        generate double years=tenure/`factor'
        by workerid: generate double cum_moves=sum(n_ee_true)
        by workerid: keep if mod(_n,`factor')==0
        by workerid: replace time=_n
        keep workerid time firmid lnwage spellid years cum_moves worker_type_true firm_type_true ///
            lag_lnwage_true lag_firm_type_true persistence_true move_shift_true innovation_sd_true move_probability_true
        quietly cf _all using `annual', all
    }
    * Private writer, complete-worker blocks of 1, 7, 33 and all workers.
    quietly fesim_config, dgp(blm) preset(`preset') workers(101) firms(15) periods(5)
    local keys "`r(matrix_results)'"
    local inputs ""
    foreach key of local keys {
        matrix `key'=r(`key')
        local inputs "`inputs' `key'"
    }
    matrix P=r(parameters)
    matrix PR=J(1,12,.)
    local col=0
    foreach name in worker_types firm_types mu sd_worker sd_firm interaction sd_error lambda_move sorting rho mobility_wage origin_dependence {
        local ++col
        matrix PR[1,`col']=P["`name'","value"]
    }
    foreach block in 1 7 33 101 {
        clear
        mata: timer_ids=fesim_runtime_claim_timers(3)
        mata: master=fesim_blm_simulate_to_stata(101,15,5,2000,"%ty","year",832,1,20,"full",st_matrix("PR"),tokens(st_local("inputs")),"`preset'","TIMING",timer_ids,`block')
        mata: fesim_runtime_release(timer_ids)
        assert TIMING[1,4]<=`block'*5
        if `block'==1 quietly save `monthly', replace
        else quietly cf _all using `monthly'
    }
}
assert "`c(rngstate)'"=="`caller'"
* A max-grid configuration retains its COMPLETE value provenance in chunks.
quietly fesim, dgp(blm) preset(dynamic) workers(20) firms(50) periods(1) burnin(0) ///
    parameters(worker_types 20 firm_types 20) seed(34) clear noreport
mata:
payload=""
n=strtoreal(st_global("_dta[fesim_blm_model_chunks]"))
assert(n>1)
for(i=1;i<=n;i++) {
    part=st_global("_dta[fesim_blm_model_"+strofreal(i)+"]")
    assert(strlen(part)<=30000)
    payload=payload+part
}
assert(payload==st_global("r(blm_model)"))
end
display "FESIM BLM INVARIANCE PASS"
