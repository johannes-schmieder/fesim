version 16.0
clear all
set more off
set varabbrev off

set rng mt64
set seed 20260829
local caller_rng_before `"`c(rng)'"'
local caller_state_before `"`c(rngstate)'"'

mata:
struct fesim_state scalar fesim_test_emp_state(
    struct fesim_population scalar population)
{
    struct fesim_state scalar state

    state.schema_version = fesim_state_schema_version()
    state.period = 1
    state.employed = (J(5, 1, 1) \ J(5, 1, 0))
    state.firm_id = (1 \ 2 \ 3 \ 4 \ 5 \ J(5, 1, .))
    state.spell_id = (J(5, 1, 1) \ J(5, 1, 0))
    state.tenure = (0 \ .5 \ 1 \ 2 \ 4 \ J(5, 1, .))
    state.unemployment_duration = ///
        (J(5, 1, .) \ 0 \ .5 \ 1 \ 2 \ 4)
    state.ntransitions = J(10, 1, 0)
    state.current_value = ///
        (population.worker_value[1..5] :+ ///
        population.firm_value[state.firm_id[1..5]] \ J(5, 1, .))
    state.validated = 1
    fesim_state_validate(state, population)
    return(state)
}
end

mata:
assert(fesim_emp_schema_version() == 1)
assert(fesim_emp_month_years() == 1 / 12)

population_rng = fesim_rng_init(20260829, 1)
emp_population = fesim_emp_generate_population(
    50000, 2000, .4, .15, 1, 1, 1, population_rng)
fesim_emp_population_validate(emp_population)
assert(abs(mean(emp_population.firm_quality)) < 1e-12)
assert(abs(variance(emp_population.firm_quality) - 1) < 1e-12)
for (type_index = 1; type_index <= 5; type_index++) {
    assert(abs(mean(emp_population.worker_type_index :== type_index) - .2) < .01)
}
worker_correlation = correlation((emp_population.worker_value, ///
    emp_population.worker_mobility))
firm_correlation = correlation((emp_population.firm_value, ///
    emp_population.firm_quality))
assert(worker_correlation[1, 2] > .94)
assert(firm_correlation[1, 2] > .999999999999)

negative_rng = fesim_rng_init(20260829, 1)
negative_population = fesim_emp_generate_population(
    20000, 1000, .4, .15, 1, -1, -1, negative_rng)
negative_worker_correlation = correlation((negative_population.worker_value, ///
    negative_population.worker_mobility))
negative_firm_correlation = correlation((negative_population.firm_value, ///
    negative_population.firm_quality))
assert(negative_worker_correlation[1, 2] < -.94)
assert(negative_firm_correlation[1, 2] < -.999999999999)

repeat_rng = fesim_rng_init(20260829, 1)
repeat_population = fesim_emp_generate_population(
    50000, 2000, .4, .15, 1, 1, 1, repeat_rng)
assert(repeat_population.worker_value == emp_population.worker_value)
assert(repeat_population.firm_value == emp_population.firm_value)
assert(repeat_population.firm_weight == emp_population.firm_weight)
assert(repeat_population.worker_type_index == ///
    emp_population.worker_type_index)
assert(repeat_population.worker_mobility == emp_population.worker_mobility)
assert(repeat_population.firm_quality == emp_population.firm_quality)

lifecycle_rng = fesim_rng_init(13579, 1)
lifecycle_population = fesim_emp_generate_population(
    10, 5, .4, .15, .5, .25, .5, lifecycle_rng)
lifecycle_tables = fesim_destination_build(
    lifecycle_population.firm_id, lifecycle_population.firm_weight, ///
    lifecycle_population.firm_quality, .3, .1, .2, -.1)
no_event = fesim_emp_params_build(
    -1000, 0, 0, 0, -1000, 0, 0, 0, -1000, 0, 0)

random_state = fesim_emp_initialize_state(
    lifecycle_population, "random", lifecycle_rng)
random_employed = selectindex(random_state.employed :== 1)
random_unemployed = selectindex(random_state.employed :== 0)
assert(length(random_employed) > 0)
assert(length(random_unemployed) > 0)
assert(random_state.tenure[random_employed] == ///
    J(length(random_employed), 1, 0))
assert(random_state.unemployment_duration[random_unemployed] == ///
    J(length(random_unemployed), 1, 0))

base_state = fesim_test_emp_state(lifecycle_population)

stay_rng = fesim_rng_init(10101, 1)
stay_state = fesim_emp_initialize_state(
    lifecycle_population, "allunemployed", stay_rng)
base_period_before = base_state.period
base_tenure_before = base_state.tenure
base_unemployment_before = base_state.unemployment_duration
base_firm_before = base_state.firm_id
stay_state = fesim_emp_advance(
    base_state, lifecycle_population, no_event, lifecycle_tables, stay_rng)
stay_period = stay_state.period
assert(stay_period == base_period_before + 1)
assert(stay_state.employed == (J(5, 1, 1) \ J(5, 1, 0)))
assert(stay_state.firm_id[1..5] == base_firm_before[1..5])
assert(max(abs(stay_state.tenure[1..5] :- ///
    base_tenure_before[1..5] :- 1 / 12)) < 1e-15)
assert(max(abs(stay_state.unemployment_duration[6..10] :- ///
    base_unemployment_before[6..10] :- 1 / 12)) < 1e-15)
assert(stay_state.ntransitions == J(10, 1, 0))

base_state = fesim_test_emp_state(lifecycle_population)
eu_params = fesim_emp_params_build(
    1000, 0, 0, 0, -1000, 0, 0, 0, -1000, 0, 0)
eu_rng = fesim_rng_init(20202, 1)
eu_state = fesim_emp_initialize_state(
    lifecycle_population, "allunemployed", eu_rng)
eu_state = fesim_emp_advance(
    base_state, lifecycle_population, eu_params, lifecycle_tables, eu_rng)
assert(eu_state.employed == J(10, 1, 0))
assert(eu_state.ntransitions[1..5] == J(5, 1, 1))
assert(eu_state.ntransitions[6..10] == J(5, 1, 0))
assert(eu_state.unemployment_duration[1..5] == J(5, 1, 0))

base_state = fesim_test_emp_state(lifecycle_population)
ue_params = fesim_emp_params_build(
    -1000, 0, 0, 0, -1000, 0, 0, 0, 1000, 0, 0)
ue_rng = fesim_rng_init(30303, 1)
ue_state = fesim_emp_initialize_state(
    lifecycle_population, "allunemployed", ue_rng)
ue_state = fesim_emp_advance(
    base_state, lifecycle_population, ue_params, lifecycle_tables, ue_rng)
assert(ue_state.employed == J(10, 1, 1))
assert(ue_state.ntransitions[1..5] == J(5, 1, 0))
assert(ue_state.ntransitions[6..10] == J(5, 1, 1))
assert(ue_state.tenure[6..10] == J(5, 1, 0))
assert(all(ue_state.firm_id[6..10] :>= 1 :& ///
    ue_state.firm_id[6..10] :<= lifecycle_population.firms))

base_state = fesim_test_emp_state(lifecycle_population)
ee_params = fesim_emp_params_build(
    -1000, 0, 0, 0, 1000, 0, 0, 0, -1000, 0, 0)
ee_rng = fesim_rng_init(40404, 1)
ee_state = fesim_emp_initialize_state(
    lifecycle_population, "allunemployed", ee_rng)
ee_state = fesim_emp_advance(
    base_state, lifecycle_population, ee_params, lifecycle_tables, ee_rng)
assert(ee_state.employed == (J(5, 1, 1) \ J(5, 1, 0)))
assert(all(ee_state.firm_id[1..5] :!= (1 \ 2 \ 3 \ 4 \ 5)))
assert(ee_state.spell_id[1..5] == J(5, 1, 2))
assert(ee_state.tenure[1..5] == J(5, 1, 0))
assert(ee_state.ntransitions[1..5] == J(5, 1, 1))

all_employed = fesim_emp_initialize_state(
    lifecycle_population, "allunemployed", lifecycle_rng)
all_employed.employed = J(10, 1, 1)
all_employed.firm_id = 1 :+ mod((0::9), lifecycle_population.firms)
all_employed.spell_id = J(10, 1, 1)
all_employed.tenure = J(10, 1, 0)
all_employed.unemployment_duration = J(10, 1, .)
all_employed.current_value = lifecycle_population.worker_value :+ ///
    lifecycle_population.firm_value[all_employed.firm_id]
duration_params = fesim_emp_params_build(
    -1000, 0, 0, 2000, -1000, 0, 0, 0, -1000, 0, 0)
short_rng = fesim_rng_init(50505, 1)
long_rng = fesim_rng_init(50505, 1)
short_state = fesim_emp_initialize_state(
    lifecycle_population, "allunemployed", short_rng)
short_state = fesim_emp_advance(
    all_employed, lifecycle_population, duration_params, ///
    lifecycle_tables, short_rng)
long_employed = fesim_emp_initialize_state(
    lifecycle_population, "allunemployed", long_rng)
long_employed.employed = J(10, 1, 1)
long_employed.firm_id = 1 :+ mod((0::9), lifecycle_population.firms)
long_employed.spell_id = J(10, 1, 1)
long_employed.tenure = J(10, 1, 1)
long_employed.unemployment_duration = J(10, 1, .)
long_employed.current_value = lifecycle_population.worker_value :+ ///
    lifecycle_population.firm_value[long_employed.firm_id]
long_state = fesim_emp_initialize_state(
    lifecycle_population, "allunemployed", long_rng)
long_state = fesim_emp_advance(
    long_employed, lifecycle_population, duration_params, ///
    lifecycle_tables, long_rng)
assert(short_state.employed == J(10, 1, 1))
assert(long_state.employed == J(10, 1, 0))

all_unemployed = fesim_emp_initialize_state(
    lifecycle_population, "allunemployed", lifecycle_rng)
ue_duration_params = fesim_emp_params_build(
    -1000, 0, 0, 0, -1000, 0, 0, 0, -1000, 0, 2000)
short_ue_rng = fesim_rng_init(60606, 1)
long_ue_rng = fesim_rng_init(60606, 1)
short_ue_state = fesim_emp_initialize_state(
    lifecycle_population, "allunemployed", short_ue_rng)
short_ue_state = fesim_emp_advance(
    all_unemployed, lifecycle_population, ue_duration_params, ///
    lifecycle_tables, short_ue_rng)
long_unemployed = fesim_emp_initialize_state(
    lifecycle_population, "allunemployed", long_ue_rng)
long_unemployed.unemployment_duration = J(10, 1, 1)
long_ue_state = fesim_emp_initialize_state(
    lifecycle_population, "allunemployed", long_ue_rng)
long_ue_state = fesim_emp_advance(
    long_unemployed, lifecycle_population, ue_duration_params, ///
    lifecycle_tables, long_ue_rng)
assert(short_ue_state.employed == J(10, 1, 0))
assert(long_ue_state.employed == J(10, 1, 1))

burn_rng = fesim_rng_init(70707, 1)
burn_state = fesim_emp_initialize_state(
    lifecycle_population, "allunemployed", burn_rng)
base_state = fesim_test_emp_state(lifecycle_population)
base_tenure_before = base_state.tenure
base_unemployment_before = base_state.unemployment_duration
base_period_before = base_state.period
burn_state = fesim_emp_burn_in(
    base_state, lifecycle_population, 5, no_event, lifecycle_tables, burn_rng)
assert(burn_state.period == base_period_before + 60)
assert(max(abs(burn_state.tenure[1..5] :- ///
    base_tenure_before[1..5] :- 5)) < 1e-12)
assert(max(abs(burn_state.unemployment_duration[6..10] :- ///
    base_unemployment_before[6..10] :- 5)) < 1e-12)

isolation_rng_a = fesim_rng_init(80808, 1)
isolation_rng_b = fesim_rng_init(80808, 1)
isolation_state_a = fesim_emp_initialize_state(
    lifecycle_population, "allunemployed", isolation_rng_a)
base_state = fesim_test_emp_state(lifecycle_population)
isolation_state_a = fesim_emp_advance(
    base_state, lifecycle_population, no_event, lifecycle_tables, ///
    isolation_rng_a)
isolation_state_b = fesim_emp_initialize_state(
    lifecycle_population, "allunemployed", isolation_rng_b)
base_state = fesim_test_emp_state(lifecycle_population)
isolation_state_b = fesim_emp_advance(
    base_state, lifecycle_population, eu_params, lifecycle_tables, ///
    isolation_rng_b)
event_index = fesim_rng_component_index(isolation_rng_a, "mobility_events")
destination_index = fesim_rng_component_index(
    isolation_rng_a, "destination_draws")
assert(isolation_rng_a.component_states[event_index] == ///
    isolation_rng_b.component_states[event_index])
assert(isolation_rng_a.component_states[destination_index] == ///
    isolation_rng_b.component_states[destination_index])
end

assert `"`c(rng)'"' == `"`caller_rng_before'"'
assert `"`c(rngstate)'"' == `"`caller_state_before'"'

capture mata: fesim_emp_generate_population(10, 1, .4, .15, 1, 0, 0, lifecycle_rng)
assert _rc == 3300
capture mata: fesim_emp_generate_population(10, 5, .4, .15, 1, 1.1, 0, lifecycle_rng)
assert _rc == 3300
capture mata: fesim_emp_initialize_state(lifecycle_population, "stationary", lifecycle_rng)
assert _rc == 3300
capture mata: fesim_emp_burn_in(base_state, lifecycle_population, .1, ///
    no_event, lifecycle_tables, lifecycle_rng)
assert _rc == 3300
capture mata: fesim_emp_standardize(J(2, 1, 1))
assert _rc == 3300
mata: bad_emp_rng = fesim_rng_init(90909, 1)
mata: bad_emp_population = fesim_emp_generate_population( ///
    10, 5, .4, .15, .5, .25, .5, bad_emp_rng)
mata: bad_emp_population.worker_type_index[1] = 5; bad_emp_population.worker_mobility[1] = -99
capture mata: fesim_emp_population_validate(bad_emp_population)
assert _rc == 3300
mata: bad_emp_tables = fesim_destination_build( ///
    lifecycle_population.firm_id, lifecycle_population.firm_weight, ///
    lifecycle_population.firm_quality, .3, .1, .2, -.1)
mata: bad_emp_tables.firm_quality[1] = bad_emp_tables.firm_quality[1] + .1
capture mata: fesim_emp_tables_validate(lifecycle_population, bad_emp_tables)
assert _rc == 3300
assert `"`c(rng)'"' == `"`caller_rng_before'"'
assert `"`c(rngstate)'"' == `"`caller_state_before'"'

di as result "FESIM EMPIRICAL MONTHLY LIFECYCLE TESTS PASS"
