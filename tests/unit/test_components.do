version 16.0
clear all
set more off
set varabbrev off

mata:
assert(fesim_network_schema_version() == 1)
assert(fesim_network_diagnostic_names() == ///
    ("components", "edges", "employed_observations", "workers", ///
    "firms", "largest_component_id", "largest_edges", ///
    "largest_observations", "largest_workers", "largest_firms", ///
    "largest_observation_share", "largest_worker_share", ///
    "largest_firm_share"))

network_edges = (1, 1, 3 \ 2, 1, 2 \ 2, 2, 1 \ ///
    3, 3, 6 \ 4, 4, 2 \ 5, 4, 4)
network_result = fesim_network_analyze(network_edges, 5, 4)
assert(network_result.validated == 1)
assert(network_result.schema_version == 1)
assert(network_result.diagnostics[1..10] == ///
    (3 \ 6 \ 18 \ 5 \ 4 \ 1 \ 3 \ 6 \ 2 \ 2))
assert(network_result.diagnostics[11] == 1 / 3)
assert(network_result.diagnostics[12] == 2 / 5)
assert(network_result.diagnostics[13] == 1 / 2)
assert(network_result.worker_component == (1 \ 1 \ 3 \ 4 \ 4))
assert(network_result.firm_component == (1 \ 1 \ 3 \ 4))

network_edges = (1, 1, 6 \ 2, 2, 3 \ 2, 3, 3)
network_result = fesim_network_analyze(network_edges, 2, 3)
assert(network_result.diagnostics[6] == 2)
assert(network_result.diagnostics[9] == 1)
assert(network_result.diagnostics[10] == 2)

network_edges = (1, 1, 3 \ 2, 2, 3)
network_result = fesim_network_analyze(network_edges, 2, 2)
assert(network_result.diagnostics[6] == 1)

network_result = fesim_network_analyze(J(0, 3, .), 3, 2)
assert(network_result.diagnostics[1..5] == (0 \ 0 \ 0 \ 0 \ 0))
assert(missing(network_result.diagnostics[6]))
assert(network_result.diagnostics[7..10] == (0 \ 0 \ 0 \ 0))
assert(all(missing(network_result.worker_component)))
assert(all(missing(network_result.firm_component)))
end

capture mata: fesim_network_analyze((1, 1, 2 \ 1, 1, 3), 2, 2)
assert _rc == 3300
capture mata: fesim_network_analyze((2, 1, 1 \ 1, 2, 1), 2, 2)
assert _rc == 3300
capture mata: fesim_network_analyze((1, 3, 1), 2, 2)
assert _rc == 3300
capture mata: fesim_network_analyze((1, 1, 0), 2, 2)
assert _rc == 3300

clear
set obs 10
generate long workerid = floor((_n - 1) / 2) + 1
generate int time = mod(_n - 1, 2) + 1
generate byte employed = 1
generate long firmid = cond(workerid == 1, 1, ///
    cond(workerid == 2, time, ///
    cond(workerid == 3, 3, 4)))
sort workerid time
quietly _fesim_network, workers(5) firms(4) periods(2) connectivity(keep)
matrix kept_network = r(network)
assert _N == 10
assert r(N_workers_sample) == 5
assert r(components) == 3
assert r(edges) == 6
assert r(employed_observations) == 10
assert r(workers) == 5
assert r(firms) == 4
assert r(largest_component_id) == 1
assert r(largest_edges) == 3
assert r(largest_observations) == 4
assert r(largest_workers) == 2
assert r(largest_firms) == 2
assert r(largest_component_obs_share) == .4
assert r(largest_component_worker_share) == .4
assert r(largest_component_firm_share) == .5
mata: assert(st_matrix("kept_network")[, 1] == ///
    st_matrix("kept_network")[, 2])

quietly _fesim_network, workers(5) firms(4) periods(2) ///
    connectivity(largest)
matrix largest_network = r(network)
assert _N == 4
assert r(N_workers_sample) == 2
assert r(components) == 1
assert r(edges) == 3
assert r(employed_observations) == 4
assert r(workers) == 2
assert r(firms) == 2
assert r(largest_component_id) == 1
assert r(largest_component_obs_share) == 1
assert r(largest_component_worker_share) == 1
assert r(largest_component_firm_share) == 1
assert inlist(workerid, 1, 2)
by workerid (time): assert _N == 2
mata: assert(st_matrix("largest_network")[, 1] == ///
    st_matrix("kept_network")[, 1])

clear
set obs 6
generate long workerid = floor((_n - 1) / 2) + 1
generate int time = mod(_n - 1, 2) + 1
generate byte employed = 0
generate long firmid = .
quietly _fesim_network, workers(3) firms(2) periods(2) connectivity(keep)
matrix empty_network = r(network)
assert r(components) == 0
assert missing(r(largest_component_id))
assert missing(r(largest_component_obs_share))
capture _fesim_network, workers(3) firms(2) periods(2) connectivity(largest)
assert _rc == 459
assert _N == 6

di as result "FESIM NETWORK COMPONENT TESTS PASS"
