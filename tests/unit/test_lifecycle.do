version 16.0
clear all
set more off
set varabbrev off

set rng mt64
set seed 11235813
set obs 4
generate long original_id = _n
generate double original_value = _n / 10
quietly datasignature set, reset
local rng_before `"`c(rngstate)'"'

mata:
assert(fesim_mata_api_version() == 7)
assert(fesim_config_schema_version() == 2)
assert(fesim_population_schema_version() == 2)
assert(fesim_state_schema_version() == 3)
assert(fesim_results_schema_version() == 2)
assert(fesim_handler_schema_version() == 1)
assert(fesim_dispatch_status() == "shared_lifecycle_toy_only")

toy_config = fesim_toy_config(7, 3, 5)
assert(toy_config.validated == 1)
assert(toy_config.dgp == "_toy")
assert(toy_config.workers == 7)
assert(toy_config.firms == 3)
assert(toy_config.periods == 5)

toy_population = fesim_toy_generate_population(toy_config)
assert(toy_population.validated == 1)
assert(toy_population.worker_id == (1::7))
assert(toy_population.firm_id == (1::3))
assert(toy_population.firm_weight == J(3, 1, 1 / 3))

toy_state = fesim_toy_initialize_state(toy_population)
assert(toy_state.validated == 1)
assert(all(toy_state.employed :== 1))
toy_state = fesim_toy_advance(toy_state, toy_population)
assert(toy_state.period == 2)

toy_handler = fesim_dispatch_handler(" _TOY ", "DETERMINISTIC")
assert(toy_handler.solve_required == 0)
assert(toy_handler.qualification == "internal_toy_only")
assert(toy_handler.lifecycle_stages == ///
    "defaults validate solve generate_population initialize_state burn_in " + ///
    "advance observe finalize_flows compute_moments metadata")

toy_result_a = fesim_dispatch_run("_toy", "deterministic", 7, 3, 5)
toy_result_b = fesim_dispatch_run("_toy", "deterministic", 7, 3, 5)
assert(toy_result_a.validated == 1)
assert(toy_result_a.status == "validated")
assert(toy_result_a.N == 35)
assert(rows(toy_result_a.observed) == 35)
assert(cols(toy_result_a.observed) == 8)
assert(toy_result_a.lifecycle == toy_handler.lifecycle_stages)
assert(mreldif(toy_result_a.observed, toy_result_b.observed) == 0)
assert(mreldif(toy_result_a.moments, toy_result_b.moments) == 0)
assert(toy_result_a.metadata_values == ///
    ("_toy", "deterministic", "output_period"))

toy_original_first = toy_result_b.observed[1, 5]
toy_result_a.observed[1, 5] = -999
toy_result_c = fesim_dispatch_run("_toy", "deterministic", 7, 3, 5)
assert(toy_result_b.observed[1, 5] == toy_original_first)
assert(toy_result_c.observed[1, 5] == toy_original_first)
end

mata: bad_config = fesim_toy_config(2, 2, 2); bad_config.workers = 0
capture mata: fesim_config_validate(bad_config)
assert _rc == 3300
mata: bad_population = fesim_toy_generate_population(fesim_toy_config(2, 2, 2)); bad_population.worker_id[1] = 9
capture mata: fesim_population_validate(bad_population)
assert _rc == 3300
mata: bad_state = fesim_toy_initialize_state(fesim_toy_generate_population(fesim_toy_config(2, 2, 2))); bad_state.tenure[1] = -1
capture mata: fesim_state_validate(bad_state, fesim_toy_generate_population(fesim_toy_config(2, 2, 2)))
assert _rc == 3300
mata: bad_handler = fesim_dispatch_handler("_toy", "deterministic"); bad_handler.solve_required = 2
capture mata: fesim_handler_validate(bad_handler)
assert _rc == 3300
capture mata: fesim_dispatch_handler("akm", "simple")
assert _rc == 3300
capture mata: fesim_dispatch_run("_toy", "deterministic", 0, 2, 2)
assert _rc == 3300

quietly datasignature confirm
assert `"`c(rngstate)'"' == `"`rng_before'"'
di as result "FESIM CORE LIFECYCLE TESTS PASS"
