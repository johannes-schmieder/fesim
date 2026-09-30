version 16.0
clear all
set more off
set varabbrev off

mata:
assert(fesim_network_leaveout_names() == ///
    ("largest_observations", "largest_workers", "largest_firms", ///
    "largest_matches", "worker_cut_vertices", ///
    "worker_set_observations", "worker_set_workers", ///
    "worker_set_firms", "worker_set_matches", ///
    "worker_set_observation_share", "worker_set_worker_share", ///
    "worker_set_firm_share", "worker_set_match_share", ///
    "vulnerable_matches_largest", ///
    "vulnerable_match_share_largest", ///
    "vulnerable_matches_worker_set", ///
    "vulnerable_match_share_worker", ///
    "worker_out_connected", "match_out_connected"))

single = fesim_network_leaveout((1, 1, 4), 1, 1)
assert(single[1..9] == (4 \ 1 \ 1 \ 1 \ 0 \ 4 \ 1 \ 1 \ 1))
assert(single[10..13] == J(4, 1, 1))
assert(single[14..19] == (0 \ 0 \ 0 \ 0 \ 1 \ 1))

path_edges = (1, 1, 2 \ 2, 1, 3 \ 2, 2, 4)
path_cut = fesim_network_bipartite_cut(path_edges, 2, 2)
assert(path_cut == (0 \ 1 \ 2))
path = fesim_network_leaveout(path_edges, 2, 2)
assert(path[1..9] == (9 \ 2 \ 2 \ 3 \ 1 \ 2 \ 1 \ 1 \ 1))
assert(path[10] == 2 / 9)
assert(path[11] == 1 / 2)
assert(path[12] == 1 / 2)
assert(path[13] == 1 / 3)
assert(path[14] == 2)
assert(path[15] == 2 / 3)
assert(path[16] == 0)
assert(path[17] == 0)
assert(path[18..19] == (1 \ 1))

cycle_edges = (1, 1, 1 \ 1, 2, 1 \ 2, 1, 1 \ 2, 2, 1)
cycle = fesim_network_leaveout(cycle_edges, 2, 2)
assert(cycle[1..4] == (4 \ 2 \ 2 \ 4))
assert(cycle[5] == 0)
assert(cycle[6..13] == (4 \ 2 \ 2 \ 4 \ 1 \ 1 \ 1 \ 1))
assert(cycle[14..19] == (0 \ 0 \ 0 \ 0 \ 1 \ 1))

star = fesim_network_leaveout((1, 1, 1 \ 1, 2, 1 \ 1, 3, 1), 1, 3)
assert(star[1..5] == (3 \ 1 \ 3 \ 3 \ 1))
assert(star[6..9] == J(4, 1, 0))
assert(star[10..13] == J(4, 1, 0))
assert(star[14] == 3)
assert(star[15] == 1)
assert(star[16] == 0)
assert(missing(star[17]))
assert(star[18..19] == (0 \ 0))

iterated_edges = (1, 1, 1 \ 1, 6, 1 \ 1, 7, 1 \ ///
    2, 1, 1 \ 2, 2, 1 \ 3, 2, 1 \ 3, 3, 1 \ ///
    4, 3, 1 \ 4, 4, 1 \ 4, 8, 1 \ ///
    5, 4, 1 \ 5, 5, 1 \ 6, 5, 1 \ 6, 6, 1)
iterated_cut = fesim_network_bipartite_cut(iterated_edges, 6, 8)
assert(iterated_cut == (1 \ 0 \ 0 \ 1 \ 0 \ 0 \ 2))
iterated = fesim_network_leaveout(iterated_edges, 6, 8)
assert(iterated[1..5] == (14 \ 6 \ 8 \ 14 \ 2))
assert(iterated[6..13] == J(8, 1, 0))
assert(iterated[14] == 2)
assert(iterated[15] == 1 / 7)
assert(iterated[16] == 0)
assert(missing(iterated[17]))
assert(iterated[18..19] == (0 \ 0))

empty = fesim_network_leaveout(J(0, 3, .), 3, 2)
assert(empty[1..9] == J(9, 1, 0))
assert(all(missing(empty[10..13])))
assert(empty[14] == 0)
assert(missing(empty[15]))
assert(empty[16] == 0)
assert(all(missing(empty[17..19])))

chain_workers = 10000
chain_edges = J(2 * chain_workers - 1, 3, 1)
chain_edges[1, .] = (1, 1, 1)
for (i = 2; i <= chain_workers; i++) {
    chain_edges[2 * i - 2, .] = (i, i - 1, 1)
    chain_edges[2 * i - 1, .] = (i, i, 1)
}
chain_cut = fesim_network_bipartite_cut(
    chain_edges, chain_workers, chain_workers)
assert(sum(chain_cut[1..chain_workers]) == chain_workers - 1)
assert(chain_cut[chain_workers + 1] == 2 * chain_workers - 2)
end

capture mata: fesim_network_bipartite_cut( ///
    (1, 1, 1 \ 2, 2, 1), 2, 2)
assert _rc == 3300
capture mata: fesim_network_bipartite_cut( ///
    (1, 1, 1 \ 1, 1, 2), 2, 2)
assert _rc == 3300
capture mata: fesim_network_bipartite_cut( ///
    (2, 1, 1 \ 1, 2, 1), 2, 2)
assert _rc == 3300

clear
input long workerid int time long firmid
1 1 1
1 2 1
2 1 1
2 2 2
end
generate byte employed = 1
sort workerid time
by workerid (time): generate byte jobtojob = ///
    cond(_n == 1, ., firmid != firmid[_n - 1])
quietly fesim__network, workers(2) firms(2) periods(2) connectivity(keep)
matrix panel_leaveout = r(leaveout)
assert rowsof(panel_leaveout) == 19
assert colsof(panel_leaveout) == 1
assert panel_leaveout["largest_observations", "value"] == 4
assert panel_leaveout["largest_workers", "value"] == 2
assert panel_leaveout["largest_firms", "value"] == 2
assert panel_leaveout["largest_matches", "value"] == 3
assert panel_leaveout["worker_cut_vertices", "value"] == 1
assert panel_leaveout["worker_set_observations", "value"] == 2
assert panel_leaveout["worker_set_workers", "value"] == 1
assert panel_leaveout["worker_set_firms", "value"] == 1
assert panel_leaveout["worker_set_matches", "value"] == 1
assert panel_leaveout["vulnerable_matches_largest", "value"] == 2
assert panel_leaveout["vulnerable_matches_worker_set", "value"] == 0
assert panel_leaveout["worker_out_connected", "value"] == 1
assert panel_leaveout["match_out_connected", "value"] == 1

clear
set obs 6
generate long workerid = floor((_n - 1) / 2) + 1
generate int time = mod(_n - 1, 2) + 1
generate byte employed = 0
generate long firmid = .
sort workerid time
by workerid (time): generate byte jobtojob = cond(_n == 1, ., 0)
quietly fesim__network, workers(3) firms(2) periods(2) connectivity(keep)
matrix empty_panel_leaveout = r(leaveout)
forvalues row = 1/9 {
    assert empty_panel_leaveout[`row', 1] == 0
}
forvalues row = 10/13 {
    assert missing(empty_panel_leaveout[`row', 1])
}
assert empty_panel_leaveout[14, 1] == 0
assert missing(empty_panel_leaveout[15, 1])
assert empty_panel_leaveout[16, 1] == 0
forvalues row = 17/19 {
    assert missing(empty_panel_leaveout[`row', 1])
}

di as result "FESIM LEAVE-OUT CONNECTIVITY TESTS PASS"
