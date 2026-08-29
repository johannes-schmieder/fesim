version 16.0
clear all
set more off
set varabbrev off

set rng mt64
set seed 20260829
local caller_rng_before `"`c(rng)'"'
local caller_state_before `"`c(rngstate)'"'

mata:
mobility_rng = fesim_rng_init(24680, 1)
mobility_population = fesim_akm_generate_population(
    8, 3, .4, .15, 1, mobility_rng)
typing_rng = fesim_rng_init(1, 1)
mobility_state_2 = fesim_akm_initialize_state(
    mobility_population, "allunemployed", 1, .08, .12, .60, typing_rng)
mobility_state_3 = fesim_akm_initialize_state(
    mobility_population, "allunemployed", 1, .08, .12, .60, typing_rng)
mobility_state_1 = fesim_akm_initialize_state(
    mobility_population, "random", 1, .08, .12, .60, mobility_rng)
mobility_state_2 = fesim_akm_advance(
    mobility_state_1, mobility_population, 1, .25, .35, .70, mobility_rng)

assert(mobility_state_2.period == 2)
assert(mobility_state_2.employed == (1 \
    1 \
    0 \
    1 \
    1 \
    0 \
    1 \
    1))
assert(mobility_state_2.spell_id == (2 \
    1 \
    1 \
    1 \
    1 \
    1 \
    1 \
    2))
assert(mobility_state_2.ntransitions == (1 \
    0 \
    1 \
    0 \
    1 \
    1 \
    1 \
    1))
state_2_employed = selectindex(mobility_state_2.employed :== 1)
state_2_unemployed = selectindex(mobility_state_2.employed :== 0)
assert(mobility_state_2.firm_id[state_2_employed] == (2 \
    3 \
    2 \
    2 \
    3 \
    3))
assert(mobility_state_2.tenure[state_2_employed] == (0 \
    1 \
    1 \
    0 \
    0 \
    0))
assert(all(missing(mobility_state_2.firm_id[state_2_unemployed])))
assert(all(missing(mobility_state_2.tenure[state_2_unemployed])))
assert(mobility_state_2.unemployment_duration[state_2_unemployed] == ///
    J(2, 1, 0))
assert(mobility_state_2.current_value[state_2_employed] == ///
    mobility_population.worker_value[state_2_employed] + ///
    mobility_population.firm_value[ ///
        mobility_state_2.firm_id[state_2_employed]])
t2_employed = mobility_state_2.employed
t2_firm_id = mobility_state_2.firm_id
t2_spell_id = mobility_state_2.spell_id
t2_tenure = mobility_state_2.tenure
t2_ntransitions = mobility_state_2.ntransitions

mobility_state_3 = fesim_akm_advance(
    mobility_state_2, mobility_population, 1, .25, .35, .70, mobility_rng)
assert(mobility_state_3.period == 3)
assert(mobility_state_3.employed == (0 \
    1 \
    1 \
    1 \
    1 \
    1 \
    0 \
    1))
assert(mobility_state_3.spell_id == (2 \
    1 \
    2 \
    2 \
    1 \
    2 \
    1 \
    3))
assert(mobility_state_3.ntransitions == (1 \
    0 \
    1 \
    1 \
    0 \
    1 \
    1 \
    1))
state_3_employed = selectindex(mobility_state_3.employed :== 1)
assert(mobility_state_3.firm_id[state_3_employed] == (3 \
    2 \
    3 \
    2 \
    1 \
    2))
assert(mobility_state_3.tenure[state_3_employed] == (2 \
    0 \
    0 \
    1 \
    0 \
    0))

repeat_rng = fesim_rng_init(24680, 1)
repeat_population = fesim_akm_generate_population(
    8, 3, .4, .15, 1, repeat_rng)
repeat_state = fesim_akm_initialize_state(
    repeat_population, "random", 1, .08, .12, .60, repeat_rng)
repeat_state = fesim_akm_advance(
    repeat_state, repeat_population, 1, .25, .35, .70, repeat_rng)
repeat_state = fesim_akm_advance(
    repeat_state, repeat_population, 1, .25, .35, .70, repeat_rng)
assert(repeat_state.employed == mobility_state_3.employed)
assert(repeat_state.spell_id == mobility_state_3.spell_id)
assert(repeat_state.ntransitions == mobility_state_3.ntransitions)
assert(all((repeat_state.firm_id :== mobility_state_3.firm_id) :| ///
    (missing(repeat_state.firm_id) :& missing(mobility_state_3.firm_id))))
assert(all((repeat_state.tenure :== mobility_state_3.tenure) :| ///
    (missing(repeat_state.tenure) :& missing(mobility_state_3.tenure))))

wage_rng = fesim_rng_init(24680, 1)
wage_population = fesim_akm_generate_population(
    8, 3, .4, .15, 1, wage_rng)
wage_state = fesim_akm_initialize_state(
    wage_population, "random", 1, .08, .12, .60, wage_rng)
wage_junk = fesim_rng_rnormal(wage_rng, "wage_shocks", 1000, 1, 0, 1)
wage_state = fesim_akm_advance(
    wage_state, wage_population, 1, .25, .35, .70, wage_rng)
assert(wage_state.employed == t2_employed)
assert(wage_state.firm_id[state_2_employed] == ///
    t2_firm_id[state_2_employed])
assert(wage_state.tenure[state_2_employed] == ///
    t2_tenure[state_2_employed])

destination_rng = fesim_rng_init(24680, 1)
destination_population = fesim_akm_generate_population(
    8, 3, .4, .15, 1, destination_rng)
destination_state_2 = fesim_akm_initialize_state(
    destination_population, "allunemployed", 1, .08, .12, .60, typing_rng)
destination_state_1 = fesim_akm_initialize_state(
    destination_population, "random", 1, .08, .12, .60, destination_rng)
destination_junk = fesim_rng_runiform(
    destination_rng, "destination_draws", 100, 1)
destination_state_2 = fesim_akm_advance(
    destination_state_1, destination_population, ///
    1, .25, .35, .70, destination_rng)
assert(destination_state_2.employed == t2_employed)
assert(destination_state_2.spell_id == t2_spell_id)
assert(destination_state_2.ntransitions == t2_ntransitions)
assert(destination_state_2.tenure[state_2_employed] == ///
    t2_tenure[state_2_employed])
assert(any(destination_state_2.firm_id[state_2_employed] :!= ///
    t2_firm_id[state_2_employed]))

zero_rng = fesim_rng_init(24680, 1)
zero_population = fesim_akm_generate_population(
    8, 3, .4, .15, 1, zero_rng)
zero_state_2 = fesim_akm_initialize_state(
    zero_population, "allunemployed", 1, .08, .12, .60, typing_rng)
zero_state_1 = fesim_akm_initialize_state(
    zero_population, "random", 1, .08, .12, .60, zero_rng)
zero_initial_employed = zero_state_1.employed
zero_initial_firm = zero_state_1.firm_id
zero_initial_spell = zero_state_1.spell_id
zero_initial_tenure = zero_state_1.tenure
zero_employed = selectindex(zero_initial_employed :== 1)
zero_unemployed = selectindex(zero_initial_employed :== 0)
zero_state_2 = fesim_akm_advance(
    zero_state_1, zero_population, 1, 0, 0, 0, zero_rng)
assert(zero_state_2.employed == zero_initial_employed)
assert(zero_state_2.firm_id[zero_employed] == ///
    zero_initial_firm[zero_employed])
assert(zero_state_2.spell_id == zero_initial_spell)
assert(zero_state_2.tenure[zero_employed] == ///
    zero_initial_tenure[zero_employed] :+ 1)
assert(all(missing(zero_state_2.tenure[zero_unemployed])))
assert(zero_state_2.unemployment_duration[zero_unemployed] == J(2, 1, 1))
assert(zero_state_2.ntransitions == J(8, 1, 0))

all_rng = fesim_rng_init(13579, 1)
all_population = fesim_akm_generate_population(5, 2, 0, 0, 0, all_rng)
all_state = fesim_akm_initialize_state(
    all_population, "allunemployed", 1, .08, 0, .60, all_rng)
all_state = fesim_akm_advance(
    all_state, all_population, 1, 0, 0, 1, all_rng)
assert(all_state.employed == J(5, 1, 1))
assert(all_state.spell_id == J(5, 1, 1))
assert(all_state.tenure == J(5, 1, 0))
assert(all(missing(all_state.unemployment_duration)))
assert(all_state.ntransitions == J(5, 1, 1))

one_rng = fesim_rng_init(97531, 1)
one_population = fesim_akm_generate_population(4, 1, 0, 0, 0, one_rng)
one_state = fesim_akm_initialize_state(
    one_population, "allunemployed", 1 / 12, .08, 0, .60, one_rng)
one_state = fesim_akm_advance(
    one_state, one_population, 1 / 12, 0, 0, 1, one_rng)
assert(one_state.employed == J(4, 1, 1))
assert(one_state.firm_id == J(4, 1, 1))
one_state = fesim_akm_advance(
    one_state, one_population, 1 / 4, .499999, 0, .60, one_rng)
fesim_state_validate(one_state, one_population)
near_state = fesim_akm_initialize_state(
    all_population, "allunemployed", 1 / 12, .499999, .5, .60, all_rng)
near_state = fesim_akm_advance(
    near_state, all_population, 1 / 12, .499999, .5, .60, all_rng)
fesim_state_validate(near_state, all_population)

assert(fesim_akm_draw_excluding((.1 \
    .2 \
    .7), (1 \
    1 \
    2 \
    2 \
    3 \
    3), (0 \
    .3 \
    .1 \
    .2 \
    .3 \
    .4)) == (2 \
    3 \
    1 \
    3 \
    1 \
    2))

burn_rng = fesim_rng_init(24680, 1)
burn_population = fesim_akm_generate_population(
    8, 3, .4, .15, 1, burn_rng)
burn_state = fesim_akm_initialize_state(
    burn_population, "random", 1, .08, .12, .60, burn_rng)
burn_state = fesim_akm_burn_in(
    burn_state, burn_population, 2, 1, .25, .35, .70, burn_rng)
assert(burn_state.period == 3)
assert(burn_state.employed == mobility_state_3.employed)
assert(burn_state.spell_id == mobility_state_3.spell_id)
assert(burn_state.ntransitions == mobility_state_3.ntransitions)
end

assert `"`c(rng)'"' == `"`caller_rng_before'"'
assert `"`c(rngstate)'"' == `"`caller_state_before'"'

mata: invalid_rng = fesim_rng_init(24680, 1)
mata: invalid_population = fesim_akm_generate_population( ///
    8, 3, .4, .15, 1, invalid_rng)
mata: invalid_state = fesim_akm_initialize_state( ///
    invalid_population, "random", 1, .08, .12, .60, invalid_rng)
mata: invalid_before = invalid_rng.component_states
capture mata: fesim_akm_advance( ///
    invalid_state, invalid_population, 1, .7, .3, .6, invalid_rng)
assert _rc == 3300
mata: assert(invalid_rng.component_states == invalid_before)
capture mata: fesim_akm_burn_in( ///
    invalid_state, invalid_population, -1, 1, .08, .12, .60, invalid_rng)
assert _rc == 3300
capture mata: fesim_akm_draw_excluding((.2 \ .8), (1), (1))
assert _rc == 3300
capture mata: fesim_akm_draw_excluding((1 \ 0), (1), (.5))
assert _rc == 3300
assert `"`c(rng)'"' == `"`caller_rng_before'"'
assert `"`c(rngstate)'"' == `"`caller_state_before'"'

di as result "FESIM SIMPLE AKM MOBILITY TESTS PASS"
