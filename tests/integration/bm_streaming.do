version 16.0
clear all
set more off
set varabbrev off
quietly _fesim_load
mata:
void fesim_test_bm_stream(real scalar block)
{
    real scalar seed
    seed = fesim_bm_simulate_to_stata(2001, 50, 5, 2000, "%ty", "year",
        23457, 1, "stationary", .25, "full", (.4, 1, 1, .5, .2, .05),
        1, "S", "F", "T", (.,.,.), block, 10000000)
    assert(seed == 23457)
}
void fesim_test_bm_monolithic()
{
    struct fesim_bm_solution scalar s
    struct fesim_bm_firms scalar f
    struct fesim_bm_state scalar initial
    struct fesim_bm_history scalar h
    struct fesim_bm_panel scalar p
    struct fesim_rng_state scalar rng
    s = fesim_bm_solve(.4,1,1,.5,.2,.05,1001,4000,1e-9)
    rng = fesim_rng_init(23457,1)
    f = fesim_bm_construct_firms(s,50,"random",rng,1e-9)
    initial = fesim_bm_initialize_state(s,f,2001,"stationary",rng,1e-9)
    initial = fesim_bm_burn_in(s,f,initial,.25,10000000,rng,1e-9)
    h = fesim_bm_simulate_events(s,f,initial.employed,initial.firm_id,
        initial.spell_id,initial.tenure,initial.unemployment_duration,
        5,1,10000000,rng,1e-9)
    p = fesim_bm_aggregate_history(s,f,h,"year",5,1e-9)
    (void) fesim_bm_output_panel(s,f,p,2000,"%ty","full")
}
end
local caller `"`c(rngstate)'"'
mata: fesim_test_bm_monolithic()
tempfile reference
quietly save `reference'
ds
local variables `r(varlist)'
foreach block in 1 7 333 2001 {
    clear
    quietly mata: fesim_test_bm_stream(`block')
    assert `"`c(rngstate)'"' == `"`caller'"'
    cf `variables' using `reference'
    assert T[1,5] <= `block' * 5
}
di as result "FESIM BM STREAMING TESTS PASS"
