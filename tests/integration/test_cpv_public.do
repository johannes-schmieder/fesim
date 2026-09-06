version 16
clear all
set more off
set varabbrev off
local caller "`c(rngstate)'"
quietly fesim, dgp(cpv) workers(2000) firms(30) periods(10) seed(7001) truth(full) clear noreport
assert "`r(dgp)'"=="cpv" & "`r(preset)'"=="simple"
assert "`r(internal_clock)'"=="continuous_time"
assert r(solver)["bellman_scaled_residual",1]<1e-10
matrix flows=r(cpv_flows)
assert flows[5,1]>0 & flows[5,2]>0 & missing(flows[5,3])
assert n_employed_offers_true==n_ee_true+n_renegotiations_true+n_rejected_offers_true
assert n_events_true==n_unemployment_offers_true+n_employed_offers_true+n_eu_true
assert ntransitions_true==n_eu_true+n_ee_true+n_ue_true
assert abs(employment_exposure_true+unemployment_exposure_true-1)<1e-12
assert lnwage==ln(contract_wage_true) if employed
assert contract_wage_true<=match_productivity_true+1e-12 if employed
assert worker_ability_true==1
assert missing(firm_productivity_true)==!employed
by workerid: assert lnwage>=lnwage[_n-1]-1e-12 if _n>1 & employed & employed[_n-1] & spellid==spellid[_n-1]
mata: reference=st_data(.,("workerid","time","firmid","employed","spellid","tenure","unemp_duration","ntransitions")); wage=st_data(.,"lnwage")
quietly fesim, dgp(cpv) preset(heterogeneous) workers(2000) firms(30) periods(10) seed(7001) truth(full) clear noreport
mata: assert(mreldif(reference,st_data(.,("workerid","time","firmid","employed","spellid","tenure","unemp_duration","ntransitions")))==0)
mata: assert(mreldif(wage,st_data(.,"lnwage")-ln(st_data(.,"worker_ability_true")))<1e-12)
assert "`c(rngstate)'"=="`caller'"
foreach beta in 0 1 {
    quietly fesim, dgp(cpv) workers(1000) firms(20) periods(5) seed(44) truth(full) parameters(beta `beta') clear noreport
    if `beta'==1 {
        assert n_renegotiations_true==0
        assert abs(contract_wage_true-match_productivity_true)<1e-12 if employed
    }
}
quietly fesim, dgp(cpv) workers(1000) firms(5) periods(5) seed(44) truth(full) parameters(p_min 1.7 p_max 1.7) clear noreport
assert n_ee_true==0
quietly summarize n_renegotiations_true, meanonly
assert r(sum)>0
foreach options in "firms(1)" "parameters(lambda_e 0)" {
    quietly fesim, dgp(cpv) workers(100) periods(4) `options' truth(full) seed(45) clear noreport
    assert n_ee_true==0 & n_renegotiations_true==0
}
quietly fesim, dgp(cpv) workers(1) firms(1) periods(1) initial(allunemployed) parameters(lambda_u .00000001) truth(full) seed(46) clear noreport
assert employed==0 & missing(lnwage) & worker_ability_true==1
* Parser and solver failures preserve caller data and RNG, including random firms.
clear
set obs 3
generate sentinel=_n
quietly datasignature
local signature "`r(datasignature)'"
foreach bad in "parameters(beta -1)" "parameters(beta 1.1)" ///
    "parameters(lambda_e -1)" "parameters(lambda_u 0)" ///
    "parameters(p_min 2 p_max 1)" "parameters(sd_worker -1)" ///
    "parameters(random_firms .5)" "initial(random) burnin(0)" ///
    "network(blocks)" "jobrule(longest)" "workers(10000001)" ///
    "firms(1000001)" "burnin(100001)" "periods(100001)" {
    capture noisily fesim, dgp(cpv) `bad' clear noreport
    assert _rc==198
    assert "`c(rngstate)'"=="`caller'"
    quietly datasignature
    assert "`r(datasignature)'"=="`signature'"
}
foreach bad in "b 3 random_firms 1" "beta 0 lambda_e 10 random_firms 1" "sd_worker 1000" {
    capture noisily fesim, dgp(cpv) workers(20) firms(10) parameters(`bad') clear noreport
    assert _rc==430
    assert "`c(rngstate)'"=="`caller'"
    quietly datasignature
    assert "`r(datasignature)'"=="`signature'"
}
capture noisily fesim, dgp(cpv) connectivity(force) clear noreport
assert _rc==498
assert "`c(rngstate)'"=="`caller'"
display "CPV PUBLIC CONTRACT AND ROLLBACK PASS"
