version 16.0
clear all
set more off
set varabbrev off

mata:
assert(fesim_paygap_schema_version() == 1)
assert(fesim_paygap_handler_version() == 1)
assert(fesim_paygap_type_support() == (-2, -1, 0, 1, 2) / sqrt(2))

paygap_rng = fesim_rng_init(20260831, 1)
paygap_population = fesim_paygap_gen_population(
    20000, 1000, .46, .420, .400, .113, .099, .247, .12567, ///
    0, .171976891180182, 1, paygap_rng)
fesim_paygap_population_validate(paygap_population)
assert(abs(mean(paygap_population.group) - .46) < .015)
assert(abs(mean(paygap_population.firm_surplus)) < .08)
assert(abs(sqrt(variance(paygap_population.firm_surplus)) - 1) < .08)
assert(rows(paygap_population.worker_mobility) == 20000)
for (type_index = 1; type_index <= 5; type_index++) {
    assert(abs(mean(paygap_population.worker_type_index :== type_index) - .2) < .015)
}
premium_correlation = correlation((paygap_population.firm_value, ///
    paygap_population.firm_alt_value))
assert(abs(premium_correlation[1, 2] - .590) < .06)

paygap_weights = fesim_paygap_destination_weights(
    paygap_population, .142, 0, .18, .273)
assert(rows(paygap_weights) == 1000)
assert(cols(paygap_weights) == 10)
assert(max(abs(colsum(paygap_weights) :- 1)) < 1e-12)
weighted_surplus = colsum(paygap_weights :* paygap_population.firm_surplus)
assert(weighted_surplus[5] > weighted_surplus[1])
assert(weighted_surplus[10] > weighted_surplus[6])

state_before = fesim_paygap_initialize_state(
    paygap_population, paygap_weights, "random", paygap_rng)
employed_before = state_before.employed
firm_before = state_before.firm_id
tenure_before = state_before.tenure
unemployment_before = state_before.unemployment_duration
period_before = state_before.period
state_before = fesim_paygap_advance(
    state_before, paygap_population, paygap_weights, 1, ///
    0, 0, 0, 0, 0, 0, paygap_rng)
assert(state_before.period == period_before + 1)
assert(state_before.employed == employed_before)
assert(all((missing(state_before.firm_id) :& missing(firm_before)) :| ///
    state_before.firm_id :== firm_before))
assert(state_before.ntransitions == J(20000, 1, 0))
employed_rows = selectindex(employed_before :== 1)
unemployed_rows = selectindex(employed_before :== 0)
assert(state_before.tenure[employed_rows] == tenure_before[employed_rows] :+ 1)
assert(state_before.unemployment_duration[unemployed_rows] == ///
    unemployment_before[unemployed_rows] :+ 1)

wage_components = fesim_paygap_wage_components(
    state_before, paygap_population, 3, 2.815, .143, .125, 0, 0, 0, ///
    paygap_rng)
assert(rows(wage_components) == 20000)
assert(cols(wage_components) == 8)
assert(all(!missing(wage_components[employed_rows, 1])))
assert(all(missing(wage_components[unemployed_rows, 1])))
assert(max(abs(wage_components[employed_rows, 1] :- ( ///
    3 :- paygap_population.group[employed_rows] :* .185 :+ ///
    wage_components[employed_rows, 2] :+ ///
    wage_components[employed_rows, 3] :+ ///
    wage_components[employed_rows, 7]))) < 1e-12)

repeat_rng = fesim_rng_init(20260831, 1)
repeat_population = fesim_paygap_gen_population(
    20000, 1000, .46, .420, .400, .113, .099, .247, .12567, ///
    0, .171976891180182, 1, repeat_rng)
assert(repeat_population.group == paygap_population.group)
assert(repeat_population.worker_value == paygap_population.worker_value)
assert(repeat_population.firm_surplus == paygap_population.firm_surplus)
assert(repeat_population.firm_value == paygap_population.firm_value)
assert(repeat_population.firm_alt_value == paygap_population.firm_alt_value)
end

capture mata: fesim_paygap_gen_population( ///
    10, 4, 1, .4, .4, 0, 0, .1, .1, 0, 0, 1, repeat_rng)
assert _rc == 3300

di as result "FESIM PAY-GAP LIFECYCLE TESTS PASS"
