version 16.0
clear all
set more off
set varabbrev off

set rng mt64
set seed 97531
local rng_before `"`c(rngstate)'"'
tempfile common_none

mata:
void fesim_test_bm_write(string scalar truth)
{
    struct fesim_bm_solution scalar solution
    struct fesim_bm_firms scalar universe
    struct fesim_bm_state scalar state
    struct fesim_bm_history scalar history
    struct fesim_bm_panel scalar panel
    struct fesim_rng_state scalar rng_state

    solution = fesim_bm_solve(
        .4, 1, 1, .5, .2, .05, 401, 4000, 1e-10)
    rng_state = fesim_rng_init(86420, 1)
    universe = fesim_bm_construct_firms(
        solution, 5, "quantile", rng_state, 1e-10)
    state = fesim_bm_initialize_state(
        solution, universe, 3, "stationary", rng_state, 1e-10)
    history = fesim_bm_simulate_events(
        solution, universe, state.employed, state.firm_id, ///
        state.spell_id, state.tenure, state.unemployment_duration, ///
        2, 1, 1000, rng_state, 1e-10)
    panel = fesim_bm_aggregate_history(
        solution, universe, history, "year", 2, 1e-10)
    stata("clear", 1)
    assert(fesim_bm_output_panel(
        solution, universe, panel, 2001, "%ty", truth) == 6)
}

void fesim_test_bm_output_nonempty()
{
    struct fesim_bm_solution scalar solution
    struct fesim_bm_firms scalar universe
    struct fesim_bm_state scalar state
    struct fesim_bm_history scalar history
    struct fesim_bm_panel scalar panel
    struct fesim_rng_state scalar rng_state

    solution = fesim_bm_solve(
        .4, 1, 1, .5, .2, .05, 101, 1000, 1e-10)
    rng_state = fesim_rng_init(1234, 1)
    universe = fesim_bm_construct_firms(
        solution, 3, "quantile", rng_state, 1e-10)
    state = fesim_bm_initialize_state(
        solution, universe, 1, "allunemployed", rng_state, 1e-10)
    history = fesim_bm_simulate_events(
        solution, universe, state.employed, state.firm_id, ///
        state.spell_id, state.tenure, state.unemployment_duration, ///
        1, 1, 100, rng_state, 1e-10)
    panel = fesim_bm_aggregate_history(
        solution, universe, history, "year", 1, 1e-10)
    (void) fesim_bm_output_panel(
        solution, universe, panel, 2001, "%ty", "none")
}
end

mata: fesim_test_bm_write("none")
isid workerid time
assert _N == 6
assert time == 2001 + mod(_n - 1, 2)
assert employed == !missing(firmid)
assert employed == !missing(lnwage)
assert employed == !missing(spellid)
assert employed == !missing(tenure)
assert !employed == !missing(unemp_duration)
assert missing(ntransitions) if mod(_n - 1, 2) == 0
assert `"`: format time'"' == "%ty"
confirm long variable workerid time firmid spellid ntransitions
confirm byte variable employed newjob from_unemp to_unemp jobtojob
confirm double variable lnwage tenure unemp_duration
foreach variable in lnwage_true posted_wage_true productivity_true {
    capture confirm variable `variable'
    assert _rc == 111
}
preserve
keep workerid time firmid employed lnwage spellid tenure unemp_duration ///
    newjob from_unemp to_unemp jobtojob ntransitions
save `common_none'
restore

mata: fesim_test_bm_write("basic")
preserve
keep workerid time firmid employed lnwage spellid tenure unemp_duration ///
    newjob from_unemp to_unemp jobtojob ntransitions
cf _all using `common_none'
restore
assert lnwage == lnwage_true if employed
assert abs(lnwage - ln(posted_wage_true)) < 1e-14 if employed
assert productivity_true == 1 if employed
assert missing(lnwage_true) & missing(posted_wage_true) & ///
    missing(productivity_true) if !employed
capture confirm variable reservation_wage_true
assert _rc == 111

mata: fesim_test_bm_write("full")
preserve
keep workerid time firmid employed lnwage spellid tenure unemp_duration ///
    newjob from_unemp to_unemp jobtojob ntransitions
cf _all using `common_none'
restore
foreach variable in reservation_wage_true unemployment_value_true ///
    employment_value_true offer_quantile_true expected_firm_mass_true ///
    expected_firm_share_true continuum_employment_true ///
    finite_scaled_employment_true continuum_profit_true ///
    finite_scaled_profit_true n_eu_true n_ee_true n_ue_true ///
    n_unemployment_offers_true n_employed_offers_true ///
    n_rejected_offers_true n_events_true ntransitions_true ///
    employment_exposure_true unemployment_exposure_true {
    confirm double variable `variable'
}
assert !missing(reservation_wage_true) & !missing(unemployment_value_true)
assert reservation_wage_true > 0 & reservation_wage_true < 1
assert employment_value_true > unemployment_value_true if employed
assert missing(employment_value_true) if !employed
assert ntransitions_true == n_eu_true + n_ee_true + n_ue_true
assert n_unemployment_offers_true == n_ue_true
assert n_employed_offers_true == n_ee_true + n_rejected_offers_true
assert n_events_true == n_unemployment_offers_true + ///
    n_employed_offers_true + n_eu_true
assert abs(employment_exposure_true + unemployment_exposure_true - 1) < 1e-12
assert missing(ntransitions) & !missing(ntransitions_true) ///
    if mod(_n - 1, 2) == 0
assert abs(continuum_profit_true - continuum_profit_true[1]) < 1e-12 ///
    if employed & employed[1]
assert `"`: char _dta[fesim_bm_output_schema]'"' == "1"
assert real(`"`: char _dta[fesim_bm_reservation_wage]'"') == ///
    reservation_wage_true[1]
assert real(`"`: char _dta[fesim_bm_productivity]'"') == 1
assert `"`: char _dta[fesim_bm_firm_mode]'"' == "quantile"

quietly datasignature set, reset
capture mata: fesim_test_bm_output_nonempty()
assert _rc == 3300
quietly datasignature confirm
assert `"`c(rngstate)'"' == `"`rng_before'"'

di as result "FESIM BM OUTPUT INTEGRATION TESTS PASS"
