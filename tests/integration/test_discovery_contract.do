version 19.0
clear all
set more off
set varabbrev off
set obs 3
generate caller_id=_n
datasignature set
set seed 314159
local rng "`c(rngstate)'"
foreach family in akm akmpaygap bm cpv {
    quietly fesim presets `family'
    local presets "`r(presets)'"
    foreach preset of local presets {
        quietly fesim describe `family', preset(`preset')
        foreach item in observed_variables truth_basic_variables initial_modes networks source_note target_scope parameter_units config config_sources {
            assert "`r(`item')'"!=""
        }
        assert rowsof(r(parameters))>0 & colsof(r(parameters))==4
        datasignature confirm
        assert "`c(rngstate)'"=="`rng'"
    }
}
tempfile reference
foreach alias in akmsimple akmempirical bmsimple {
    quietly fesim describe `alias'
    local family "`r(dgp)'"
    local preset "`r(preset)'"
    quietly fesim, dgp(`family') preset(`preset') workers(120) firms(12) ///
        periods(4) seed(1234) truth(full) noreport clear
    quietly save `reference', replace
    quietly fesim, dgp(`alias') workers(120) firms(12) periods(4) ///
        seed(1234) truth(full) noreport clear
    quietly cf _all using `reference'
}
* Freeze the parser's existing accepted minima, including noREPORT behavior.
quietly fesim, dgp(akm) preset(simple) workers(120) firms(12) periods(4) ///
    frequency(quarter) start(2000q1) seed(1234) initial(stationary) burnin(0) ///
    jobrule(end) truth(full) connectivity(keep) network(random) ///
    parameters(p_ee .2) noreport clear
quietly save `reference', replace
quietly fesim, dgp(akm) pres(simple) work(120) firm(12) period(4) ///
    freq(quarter) start(2000q1) seed(1234) initial(stationary) burnin(0) ///
    jobrule(end) truth(full) connect(keep) netw(random) ///
    parameters(p_ee .2) noreport clear
quietly cf _all using `reference'
datasignature set, reset
foreach options in "dgp(akmchk)" "dgp(cck2016)" "jobrule(dominant)" ///
    "truth(compact)" "connectivity(force)" "solveonly" "solution(foo)" ///
    "wor(10)" "norep" "workers(10) parameters(workers 11)" "dgp(bm) network(ladder)" ///
    "dgp(akmpaygap) network(blocks)" "parameters(p_ee .1 p_ee .2)" {
    capture fesim, `options' clear
    local failure_rc = _rc
    assert `failure_rc'==cond("`options'"=="connectivity(force)",498,198)
    datasignature confirm
    assert "`c(rngstate)'"=="`rng'"
}
display "FESIM DISCOVERY AND ABBREVIATION CONTRACT PASS"
