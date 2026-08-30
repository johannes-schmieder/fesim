version 16.0
clear all
set more off
set varabbrev off

set rng mt64
set seed 20260829
local caller_rng_before `"`c(rng)'"'
local caller_state_before `"`c(rngstate)'"'

mata:
initial_rng = fesim_rng_init(24680, 1)
initial_population = fesim_akm_generate_population(
    8, 3, .4, .15, 1, initial_rng)
transition = fesim_akm_transition_matrix(
    initial_population, 1, .08, .12, .60)
stationary_probabilities = fesim_akm_stationary_probs(
    initial_population, 1, .08, .12, .60)

assert(rows(transition) == 4 & cols(transition) == 4)
assert(max(abs(rowsum(transition) :- 1)) < 1e-15)
assert(transition[1, 1] == .4)
assert(mreldif(transition[1, 2..4], ///
    .6 :* initial_population.firm_weight') < 1e-15)
assert(max(abs(transition' * stationary_probabilities - ///
    stationary_probabilities)) < 1e-12)
assert(abs(stationary_probabilities[1] - .08 / (.08 + .60)) < 1e-14)
assert(abs(sum(stationary_probabilities) - 1) < 1e-15)
assert(mreldif(stationary_probabilities, ///
    (.11764705882352944 \
    .12873443016651534 \
    .41316970510932616 \
    .34044880590062915)) < 1e-14)

stationary_state = fesim_akm_initialize_state(
    initial_population, "stationary", 1, .08, .12, .60, initial_rng)
assert(stationary_state.validated == 1)
assert(stationary_state.schema_version == 5)
assert(stationary_state.employed == J(8, 1, 1))
assert(stationary_state.firm_id == (3 \
    3 \
    3 \
    2 \
    1 \
    3 \
    2 \
    2))
assert(stationary_state.spell_id == J(8, 1, 1))
assert(stationary_state.tenure == (3 \
    5 \
    0 \
    0 \
    7 \
    0 \
    3 \
    1))
assert(all(missing(stationary_state.unemployment_duration)))
assert(stationary_state.ntransitions == J(8, 1, 0))
assert(stationary_state.current_value == ///
    initial_population.worker_value + ///
    initial_population.firm_value[stationary_state.firm_id])

repeat_rng = fesim_rng_init(24680, 1)
repeat_population = fesim_akm_generate_population(
    8, 3, .4, .15, 1, repeat_rng)
repeat_state = fesim_akm_initialize_state(
    repeat_population, "stationary", 1, .08, .12, .60, repeat_rng)
assert(repeat_state.employed == stationary_state.employed)
assert(repeat_state.firm_id == stationary_state.firm_id)
assert(repeat_state.tenure == stationary_state.tenure)

wage_rng = fesim_rng_init(24680, 1)
wage_population = fesim_akm_generate_population(
    8, 3, .4, .15, 1, wage_rng)
wage_junk = fesim_rng_rnormal(
    wage_rng, "wage_shocks", 1000, 1, 0, 1)
wage_state = fesim_akm_initialize_state(
    wage_population, "stationary", 1, .08, .12, .60, wage_rng)
assert(wage_state.employed == stationary_state.employed)
assert(wage_state.firm_id == stationary_state.firm_id)
assert(wage_state.tenure == stationary_state.tenure)

destination_rng = fesim_rng_init(24680, 1)
destination_population = fesim_akm_generate_population(
    8, 3, .4, .15, 1, destination_rng)
destination_junk = fesim_rng_runiform(
    destination_rng, "destination_draws", 100, 1)
destination_state = fesim_akm_initialize_state(
    destination_population, "stationary", 1, .08, .12, .60, ///
    destination_rng)
assert(destination_state.employed == stationary_state.employed)
assert(destination_state.tenure == stationary_state.tenure)
assert(any(destination_state.firm_id :!= stationary_state.firm_id))

random_rng = fesim_rng_init(24680, 1)
random_population = fesim_akm_generate_population(
    8, 3, .4, .15, 1, random_rng)
random_state = fesim_akm_initialize_state(
    random_population, "random", 1, .08, .12, .60, random_rng)
assert(random_state.employed == (1 \
    1 \
    1 \
    1 \
    0 \
    1 \
    0 \
    1))
random_employed = selectindex(random_state.employed :== 1)
random_unemployed = selectindex(random_state.employed :== 0)
assert(random_state.firm_id[random_employed] == (3 \
    3 \
    3 \
    2 \
    3 \
    2))
assert(random_state.tenure[random_employed] == J(6, 1, 0))
assert(random_state.spell_id[random_employed] == J(6, 1, 1))
assert(all(missing(random_state.unemployment_duration[random_employed])))
assert(all(missing(random_state.firm_id[random_unemployed])))
assert(all(missing(random_state.tenure[random_unemployed])))
assert(random_state.spell_id[random_unemployed] == J(2, 1, 0))
assert(random_state.unemployment_duration[random_unemployed] == J(2, 1, 0))

all_unemployed_rng = fesim_rng_init(24680, 1)
all_states_before = all_unemployed_rng.component_states
all_unemployed_state = fesim_akm_initialize_state(
    random_population, "allunemployed", 1, .08, .12, .60, ///
    all_unemployed_rng)
assert(all_unemployed_state.employed == J(8, 1, 0))
assert(all_unemployed_state.spell_id == J(8, 1, 0))
assert(all(missing(all_unemployed_state.firm_id)))
assert(all(missing(all_unemployed_state.tenure)))
assert(all_unemployed_state.unemployment_duration == J(8, 1, 0))
assert(all_unemployed_rng.component_states == all_states_before)

zero_exit_rng = fesim_rng_init(24680, 1)
zero_exit_population = fesim_akm_generate_population(
    8, 3, .4, .15, 1, zero_exit_rng)
zero_exit_state = fesim_akm_initialize_state(
    zero_exit_population, "stationary", 1, 0, 0, .60, zero_exit_rng)
assert(zero_exit_state.employed == J(8, 1, 1))
assert(zero_exit_state.tenure == J(8, 1, 0))

no_entry_rng = fesim_rng_init(24680, 1)
no_entry_population = fesim_akm_generate_population(
    8, 3, .4, .15, 1, no_entry_rng)
no_entry_state = fesim_akm_initialize_state(
    no_entry_population, "stationary", 1, .08, .12, 0, no_entry_rng)
assert(no_entry_state.employed == J(8, 1, 0))

assert(fesim_destination_sample_common((.2 \
    .3 \
    .5), (0 \
    .199999 \
    .2 \
    .499999 \
    .5 \
    .999)) == (1 \
    1 \
    2 \
    2 \
    3 \
    3))
assert(fesim_akm_geometric_ages((0 \
    .19 \
    .2 \
    .5 \
    .999), .2) == (0 \
    0 \
    1 \
    3 \
    30))
end

assert `"`c(rng)'"' == `"`caller_rng_before'"'
assert `"`c(rngstate)'"' == `"`caller_state_before'"'

mata: invalid_rng = fesim_rng_init(24680, 1)
mata: invalid_population = fesim_akm_generate_population( ///
    8, 3, .4, .15, 1, invalid_rng)
mata: invalid_states_before = invalid_rng.component_states
capture mata: fesim_akm_initialize_state( ///
    invalid_population, "stationary", 1, 0, .12, 0, invalid_rng)
assert _rc == 3300
mata: assert(invalid_rng.component_states == invalid_states_before)

capture mata: fesim_akm_initialize_state( ///
    invalid_population, "unknown", 1, .08, .12, .60, invalid_rng)
assert _rc == 3300
capture mata: fesim_destination_sample_common((.2 \ 0), (.5))
assert _rc == 3300
capture mata: fesim_akm_geometric_ages((.5), 1)
assert _rc == 3300
mata: one_rng = fesim_rng_init(24680, 1)
mata: one_population = fesim_akm_generate_population( ///
    2, 1, .4, .15, 0, one_rng)
capture mata: fesim_akm_initialize_state( ///
    one_population, "random", 1, .08, .12, .60, one_rng)
assert _rc == 3300

mata: all_unemployed_state.employed[1] = 1
capture mata: fesim_state_validate(all_unemployed_state, random_population)
assert _rc == 3300
assert `"`c(rng)'"' == `"`caller_rng_before'"'
assert `"`c(rngstate)'"' == `"`caller_state_before'"'

di as result "FESIM SIMPLE AKM INITIALIZATION TESTS PASS"
