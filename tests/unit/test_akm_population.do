version 16.0
clear all
set more off
set varabbrev off

set rng mt64
set seed 20260829
local caller_rng_before `"`c(rng)'"'
local caller_state_before `"`c(rngstate)'"'

mata:
assert(fesim_akm_simple_schema_version() == 4)
assert(fesim_akm_pop_moment_names() == ///
    ("alpha_mean", "alpha_sd", "alpha_var", ///
    "psi_mean", "psi_sd", "psi_var", ///
    "firm_weight_min", "firm_weight_max", "firm_weight_hhi"))

akm_rng_a = fesim_rng_init(12345, 1)
akm_population_a = fesim_akm_generate_population(
    5, 3, .4, .15, 1, akm_rng_a)
assert(akm_population_a.validated == 1)
assert(akm_population_a.worker_id == (1::5))
assert(akm_population_a.firm_id == (1::3))
assert(rows(akm_population_a.worker_value) == 5)
assert(rows(akm_population_a.firm_value) == 3)
assert(rows(akm_population_a.firm_weight) == 3)
assert(all(akm_population_a.firm_weight :> 0))
assert(abs(sum(akm_population_a.firm_weight) - 1) < 1e-15)
assert(akm_population_a.worker_value == ///
    (-.37058713098320051 \ .16604298147125318 \ ///
    .45549917710321647 \ .72064244721494219 \ .20889525780253365))
assert(akm_population_a.firm_value == ///
    (.12151104017043515 \ .10072601255320709 \ -.031556286430234518))
assert(akm_population_a.firm_weight == ///
    (.11953567881462088 \ .4170944252291483 \ .46336989595623085))

akm_rng_b = fesim_rng_init(12345, 1)
akm_population_b = fesim_akm_generate_population(
    5, 3, .4, .15, 1, akm_rng_b)
assert(akm_population_a.worker_value == akm_population_b.worker_value)
assert(akm_population_a.firm_value == akm_population_b.firm_value)
assert(akm_population_a.firm_weight == akm_population_b.firm_weight)

akm_rng_extra = fesim_rng_init(12345, 1)
wage_junk = fesim_rng_rnormal(
    akm_rng_extra, "wage_shocks", 1000, 1, 0, 1)
akm_population_extra = fesim_akm_generate_population(
    5, 3, .4, .15, 1, akm_rng_extra)
assert(akm_population_a.worker_value == akm_population_extra.worker_value)
assert(akm_population_a.firm_value == akm_population_extra.firm_value)
assert(akm_population_a.firm_weight == akm_population_extra.firm_weight)

akm_population_moments = fesim_akm_population_moments(akm_population_a)
akm_population_targets = fesim_akm_population_targets(.4, .15)
assert(rows(akm_population_moments) == 9)
assert(mreldif(akm_population_targets[1..6], ///
    (0 \ .4 \ .16 \ 0 \ .15 \ .0225)) < 1e-15)
assert(all(missing(akm_population_targets[7..9])))
assert(akm_population_moments[2] == ///
    sqrt(fesim_sample_variance(akm_population_a.worker_value)))
assert(akm_population_moments[5] == ///
    sqrt(fesim_sample_variance(akm_population_a.firm_value)))
assert(akm_population_moments[9] == ///
    sum(akm_population_a.firm_weight :^ 2))

zero_rng = fesim_rng_init(12345, 1)
zero_population = fesim_akm_generate_population(
    1, 1, 0, 0, 0, zero_rng)
assert(zero_population.worker_value == 0)
assert(zero_population.firm_value == 0)
assert(zero_population.firm_weight == 1)
zero_moments = fesim_akm_population_moments(zero_population)
assert(missing(zero_moments[2]))
assert(missing(zero_moments[3]))
assert(missing(zero_moments[5]))
assert(missing(zero_moments[6]))

uniform_weights = fesim_akm_stable_weights((-2 \ 0 \ 7), 0)
assert(uniform_weights == J(3, 1, 1 / 3))
dispersed_weights = fesim_akm_stable_weights((-2 \ 0 \ 7), 1e300)
assert(all(dispersed_weights :> 0))
assert(abs(sum(dispersed_weights) - 1) < 1e-15)
assert(dispersed_weights[3] == max(dispersed_weights))

end

assert `"`c(rng)'"' == `"`caller_rng_before'"'
assert `"`c(rngstate)'"' == `"`caller_state_before'"'

capture mata: fesim_akm_generate_population( ///
    0, 2, .4, .15, 1, akm_rng_a)
assert _rc == 3300
capture mata: fesim_akm_stable_weights((1 \ .), 1)
assert _rc == 3300
mata: bad_akm_rng = fesim_rng_init(12345, 1)
mata: bad_akm_population = fesim_akm_generate_population( ///
    5, 3, .4, .15, 1, bad_akm_rng)
mata: bad_akm_population.firm_weight[1] = .
capture mata: fesim_population_validate(bad_akm_population)
assert _rc == 3300
assert `"`c(rng)'"' == `"`caller_rng_before'"'
assert `"`c(rngstate)'"' == `"`caller_state_before'"'

di as result "FESIM SIMPLE AKM POPULATION TESTS PASS"
