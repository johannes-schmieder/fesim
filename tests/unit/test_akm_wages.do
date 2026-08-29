version 16.0
clear all
set more off
set varabbrev off

set rng mt64
set seed 20260829
local caller_rng_before `"`c(rng)'"'
local caller_state_before `"`c(rngstate)'"'

mata:
assert(fesim_akm_wage_component_names() == ///
    ("lnwage", "alpha_true", "psi_true", "time_true", ///
    "xb_true", "match_true", "epsilon_true", "lnwage_true"))
assert(fesim_akm_wage_moment_names() == ///
    ("epsilon_mean", "epsilon_sd", "epsilon_var"))

wage_rng = fesim_rng_init(24680, 1)
wage_population = fesim_akm_generate_population(
    8, 3, .4, .15, 1, wage_rng)
wage_state = fesim_akm_initialize_state(
    wage_population, "random", 1, .08, .12, .60, wage_rng)
wage_components = fesim_akm_wage_components(
    wage_state, wage_population, 3, .2, .1, 2.5, wage_rng)
wage_employed = selectindex(wage_state.employed :== 1)
wage_unemployed = selectindex(wage_state.employed :== 0)

assert(rows(wage_components) == 8 & cols(wage_components) == 8)
assert(wage_components[, 2] == wage_population.worker_value)
assert(wage_components[, 4] == J(8, 1, .25))
assert(wage_components[wage_employed, 3] == ///
    wage_population.firm_value[wage_state.firm_id[wage_employed], 1])
assert(wage_components[wage_employed, 5] == J(6, 1, 0))
assert(wage_components[wage_employed, 6] == J(6, 1, 0))
assert(wage_components[wage_employed, 7] == ///
    (-.071645344072539571 \
    -.23781066385622243 \
    -.064221974548160768 \
    .1960629156663331 \
    -.19630367639507998 \
    .083246122520140922))
assert(wage_components[wage_employed, 1] == ///
    (3.0955466950393302 \
    2.7132600649485856 \
    3.8315093518299168 \
    4.2182993436411698 \
    2.9479806225717216 \
    3.6728191116582107))
assert(wage_components[wage_employed, 8] == ///
    wage_components[wage_employed, 1])
assert(all(missing(wage_components[wage_unemployed, 1])))
assert(all(missing(wage_components[wage_unemployed, 3])))
assert(all(missing(wage_components[wage_unemployed, 5..8])))
assert(!any(missing(wage_components[wage_unemployed, 2])))
assert(!any(missing(wage_components[wage_unemployed, 4])))

wage_moments = fesim_akm_wage_moments(wage_components)
wage_targets = fesim_akm_wage_targets(.2)
assert(mreldif(wage_moments, ///
    (-.048445436780921454 \
    .16470299590290099 \
    .027127076859391024)) < 1e-15)
assert(mreldif(wage_targets, (0 \ .2 \ .04)) < 1e-15)

repeat_rng = fesim_rng_init(24680, 1)
repeat_population = fesim_akm_generate_population(
    8, 3, .4, .15, 1, repeat_rng)
repeat_state = fesim_akm_initialize_state(
    repeat_population, "random", 1, .08, .12, .60, repeat_rng)
repeat_components = fesim_akm_wage_components(
    repeat_state, repeat_population, 3, .2, .1, 2.5, repeat_rng)
assert(all((repeat_components :== wage_components) :| ///
    (missing(repeat_components) :& missing(wage_components))))

mobility_rng = fesim_rng_init(24680, 1)
mobility_population = fesim_akm_generate_population(
    8, 3, .4, .15, 1, mobility_rng)
mobility_state = fesim_akm_initialize_state(
    mobility_population, "random", 1, .08, .12, .60, mobility_rng)
mobility_junk = fesim_rng_runiform(
    mobility_rng, "mobility_events", 1000, 1)
mobility_components = fesim_akm_wage_components(
    mobility_state, mobility_population, 3, .2, .1, 2.5, mobility_rng)
assert(all((mobility_components :== wage_components) :| ///
    (missing(mobility_components) :& missing(wage_components))))

zero_rng = fesim_rng_init(24680, 1)
zero_population = fesim_akm_generate_population(
    8, 3, .4, .15, 1, zero_rng)
zero_state = fesim_akm_initialize_state(
    zero_population, "random", 1, .08, .12, .60, zero_rng)
zero_components = fesim_akm_wage_components(
    zero_state, zero_population, 3, 0, 0, 0, zero_rng)
assert(zero_components[wage_employed, 7] == J(6, 1, 0))
assert(zero_components[wage_employed, 1] == ///
    3 :+ zero_population.worker_value[wage_employed] :+ ///
    zero_population.firm_value[zero_state.firm_id[wage_employed], 1])
assert(fesim_akm_wage_moments(zero_components) == (0 \ 0 \ 0))

varied_rng = fesim_rng_init(24680, 1)
varied_population = fesim_akm_generate_population(
    8, 3, .4, .15, 1, varied_rng)
varied_state = fesim_akm_initialize_state(
    varied_population, "random", 1, .08, .12, .60, varied_rng)
varied_components = fesim_akm_wage_components(
    varied_state, varied_population, 3, .9, 0, 0, varied_rng)
zero_next = fesim_akm_wage_components(
    zero_state, zero_population, 3, .2, 0, 0, zero_rng)
varied_next = fesim_akm_wage_components(
    varied_state, varied_population, 3, .2, 0, 0, varied_rng)
assert(all((zero_next :== varied_next) :| ///
    (missing(zero_next) :& missing(varied_next))))

empty_rng = fesim_rng_init(24680, 1)
empty_population = fesim_akm_generate_population(
    8, 3, .4, .15, 1, empty_rng)
empty_state = fesim_akm_initialize_state(
    empty_population, "allunemployed", 1, .08, .12, .60, empty_rng)
empty_components = fesim_akm_wage_components(
    empty_state, empty_population, 3, .2, .1, 2.5, empty_rng)
assert(all(missing(empty_components[, 1])))
assert(empty_components[, 2] == empty_population.worker_value)
assert(empty_components[, 4] == J(8, 1, .25))
assert(all(missing(empty_components[, 3])))
assert(all(missing(empty_components[, 5..8])))
assert(all(missing(fesim_akm_wage_moments(empty_components))))
end

assert `"`c(rng)'"' == `"`caller_rng_before'"'
assert `"`c(rngstate)'"' == `"`caller_state_before'"'

mata: invalid_rng = fesim_rng_init(24680, 1)
mata: invalid_population = fesim_akm_generate_population( ///
    8, 3, .4, .15, 1, invalid_rng)
mata: invalid_state = fesim_akm_initialize_state( ///
    invalid_population, "random", 1, .08, .12, .60, invalid_rng)
mata: invalid_before = invalid_rng.component_states
capture mata: fesim_akm_wage_components( ///
    invalid_state, invalid_population, 3, -1, 0, 0, invalid_rng)
assert _rc == 3300
mata: assert(invalid_rng.component_states == invalid_before)
capture mata: fesim_akm_wage_components( ///
    invalid_state, invalid_population, 3, .2, 0, -1, invalid_rng)
assert _rc == 3300
capture mata: fesim_akm_wage_moments(J(2, 7, .))
assert _rc == 3300
capture mata: fesim_akm_wage_targets(-1)
assert _rc == 3300
assert `"`c(rng)'"' == `"`caller_rng_before'"'
assert `"`c(rngstate)'"' == `"`caller_state_before'"'

di as result "FESIM SIMPLE AKM WAGE TESTS PASS"
