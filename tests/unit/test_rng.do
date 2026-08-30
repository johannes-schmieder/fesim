version 16.0
clear all
set more off
set varabbrev off

mata: assert(fesim_rng_schema_version() == 2)
mata: assert(fesim_rng_component_names() == ///
    ("worker_primitives", "firm_primitives", "initial_states", ///
    "mobility_events", "destination_draws", "wage_shocks", ///
    "observation_error", "solver", "network_design"))
mata: assert(fesim_rng_stream_ids() == ///
    (101, 102, 103, 104, 105, 106, 107, 108, 109))

set rng mt64s
set rngstream 17
set seed 13579
mata: caller_junk = runiform(1, 7)
local seeded_caller_state `"`c(rngstate)'"'

mata:
seeded_a = fesim_rng_init(24680, 1)
assert(seeded_a.master_seed == 24680)
assert(seeded_a.seed_source == "requested")
assert(seeded_a.rng_name == "mt64s")
assert(seeded_a.method == "fixed_nonoverlapping_mt64s_component_streams")
assert(rngstate() == seeded_a.caller_state)
worker_a = fesim_rng_rnormal(seeded_a, "worker_primitives", 1, 10, 0, 1)
mobility_a = fesim_rng_runiform(seeded_a, "mobility_events", 1, 10)
worker_cont_a = fesim_rng_runiform(seeded_a, "worker_primitives", 1, 10)
worker_cont2_a = fesim_rng_runiform(seeded_a, "worker_primitives", 1, 10)
assert(mreldif(worker_cont_a, worker_cont2_a) > 0)
assert(rngstate() == seeded_a.caller_state)

seeded_b = fesim_rng_init(24680, 1)
worker_b = fesim_rng_rnormal(seeded_b, "worker_primitives", 1, 10, 0, 1)
mobility_b = fesim_rng_runiform(seeded_b, "mobility_events", 1, 10)
worker_cont_b = fesim_rng_runiform(seeded_b, "worker_primitives", 1, 10)
worker_cont2_b = fesim_rng_runiform(seeded_b, "worker_primitives", 1, 10)
assert(worker_a == worker_b)
assert(mobility_a == mobility_b)
assert(worker_cont_a == worker_cont_b)
assert(worker_cont2_a == worker_cont2_b)
assert(mreldif(worker_a, mobility_a) > 0)

seeded_extra = fesim_rng_init(24680, 1)
worker_extra = fesim_rng_rnormal(seeded_extra, "worker_primitives", 1, 10, 0, 1)
wage_junk = fesim_rng_rnormal(seeded_extra, "wage_shocks", 1, 1000, 0, 1)
mobility_extra = fesim_rng_runiform(seeded_extra, "mobility_events", 1, 10)
assert(worker_a == worker_extra)
assert(mobility_a == mobility_extra)

seeded_network = fesim_rng_init(24680, 1)
network_junk = fesim_rng_runiform(seeded_network, "network_design", 1000, 1)
worker_network = fesim_rng_rnormal(
    seeded_network, "worker_primitives", 1, 10, 0, 1)
mobility_network = fesim_rng_runiform(
    seeded_network, "mobility_events", 1, 10)
assert(worker_a == worker_network)
assert(mobility_a == mobility_network)

integer_draws = fesim_rng_runiformint(seeded_extra, "destination_draws", ///
    100, 1, 1, 4)
assert(all(integer_draws :>= 1 :& integer_draws :<= 4))
zero_sd = fesim_rng_rnormal(seeded_extra, "observation_error", 5, 1, 2, 0)
assert(all(zero_sd :== 2))
assert(rngstate() == seeded_extra.caller_state)
end

assert `"`c(rngstate)'"' == `"`seeded_caller_state'"'

set rng mt64
set seed 97531
mata:
unseeded_caller_state = rngstate()
expected_seed_matrix = runiformint(1, 1, 0, 2147483647)
expected_seed = expected_seed_matrix[1, 1]
expected_continuation_state = rngstate()
rngstate(unseeded_caller_state)
unseeded = fesim_rng_init(., 0)
assert(unseeded.master_seed == expected_seed)
assert(unseeded.seed_source == "current_rng")
assert(unseeded.caller_state == unseeded_caller_state)
assert(unseeded.continuation_state == expected_continuation_state)
assert(rngstate() == expected_continuation_state)
unseeded_worker = fesim_rng_runiform(unseeded, "worker_primitives", 10, 1)
assert(rngstate() == expected_continuation_state)
end

di as result "FESIM RNG MANAGER TESTS PASS"
