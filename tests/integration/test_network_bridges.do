version 16.0
clear all
set more off
set varabbrev off

args requested_root
local repository_root `"`requested_root'"'
if `"`repository_root'"' == "" local repository_root `"`c(pwd)'"'
quietly adopath ++ `"`repository_root'"'

tempfile simple_first
quietly fesim, dgp(akm) preset(simple) network(bridges) ///
    workers(400) firms(40) periods(8) frequency(year) start(2000) ///
    seed(246813) truth(full) connectivity(keep) burnin(4) ///
    parameters(block_count 4 p_eu .02 p_ee .60 p_ue .80) ///
    clear noreport
assert `"`r(network_design)'"' == "bridges"
assert r(bridges_imposed) == 3
assert r(parameters)["bridge_count", "value"] == 3
assert rowsof(r(bridges)) == 3
assert colsof(r(bridges)) == 8
matrix simple_bridges_a = r(bridges)
assert `"`: char _dta[fesim_network_design]'"' == "bridges"
assert `"`: char _dta[fesim_bridges_imposed]'"' == "3"
confirm variable nbridges_imposed worker_block_true firm_block_true
quietly summarize nbridges_imposed, meanonly
assert r(sum) == 3
bysort workerid: egen byte __worker_bridges = total(nbridges_imposed)
assert __worker_bridges <= 1
drop __worker_bridges
mata:
simple_bridge = st_matrix("simple_bridges_a")
assert(simple_bridge[, 1] == (1::3))
assert(simple_bridge[, 7] == (1::3))
assert(simple_bridge[, 8] == (2::4))
assert(length(uniqrows(simple_bridge[, 2])) == 3)
assert(all(simple_bridge[, 3] :>= 2))
assert(all(simple_bridge[, 4] :>= simple_bridge[, 3]))
end
forvalues bridge = 1/3 {
    local bridge_worker = simple_bridges_a[`bridge', 2]
    local bridge_period = simple_bridges_a[`bridge', 3]
    local source_firm = simple_bridges_a[`bridge', 5]
    local target_firm = simple_bridges_a[`bridge', 6]
    local source_block = simple_bridges_a[`bridge', 7]
    local target_block = simple_bridges_a[`bridge', 8]
    local bridge_time = 2000 + `bridge_period' - 1
    quietly count if workerid == `bridge_worker' & time == `bridge_time' & ///
        nbridges_imposed == 1 & firmid == `target_firm' & ///
        worker_block_true == `source_block' & ///
        firm_block_true == `target_block'
    assert r(N) == 1
    quietly count if workerid == `bridge_worker' & ///
        time == `bridge_time' - 1 & firmid == `source_firm'
    assert r(N) == 1
}
save `simple_first'

quietly fesim, dgp(akm) preset(simple) network(bridges) ///
    workers(400) firms(40) periods(8) frequency(year) start(2000) ///
    seed(246813) truth(full) connectivity(keep) burnin(4) ///
    parameters(block_count 4 p_eu .02 p_ee .60 p_ue .80) ///
    clear noreport
matrix simple_bridges_b = r(bridges)
mata: assert(st_matrix("simple_bridges_a") == st_matrix("simple_bridges_b"))
cf _all using `simple_first'

quietly fesim, dgp(akm) preset(stylized) network(bridges) ///
    workers(500) firms(40) periods(6) frequency(year) start(2000) ///
    seed(975318) truth(basic) connectivity(keep) burnin(2) ///
    parameters(block_count 4 bridge_count 5 kappa_ee 0 kappa_eu -3) ///
    clear noreport
assert `"`r(network_design)'"' == "bridges"
assert r(bridges_imposed) == 5
assert rowsof(r(bridges)) == 5
matrix stylized_bridges = r(bridges)
confirm variable nbridges_imposed
capture confirm variable worker_block_true
assert _rc == 111
quietly summarize nbridges_imposed, meanonly
assert r(sum) == 5
mata:
stylized_bridge = st_matrix("stylized_bridges")
assert(stylized_bridge[, 1] == (1::5))
assert(stylized_bridge[, 7] == (1 \ 2 \ 3 \ 1 \ 2))
assert(stylized_bridge[, 8] == (2 \ 3 \ 4 \ 2 \ 3))
assert(length(uniqrows(stylized_bridge[, 2])) == 5)
assert(all(stylized_bridge[, 3] :>= 2))
end
forvalues bridge = 1/5 {
    local bridge_worker = stylized_bridges[`bridge', 2]
    local bridge_period = stylized_bridges[`bridge', 3]
    local bridge_time = 2000 + `bridge_period' - 1
    quietly count if workerid == `bridge_worker' & time == `bridge_time' & ///
        nbridges_imposed == 1
    assert r(N) == 1
}

clear
set obs 2
generate sentinel = _n
local caller_rng `"`c(rng)'"'
local caller_rngstate `"`c(rngstate)'"'
capture noisily fesim, dgp(akm) preset(simple) network(bridges) ///
    workers(80) firms(8) periods(4) frequency(year) start(2000) ///
    seed(1234) truth(none) connectivity(keep) ///
    parameters(block_count 4 p_ee 0) clear noreport
assert _rc == 3300
assert _N == 2
confirm variable sentinel
assert sentinel == _n
assert `"`c(rng)'"' == `"`caller_rng'"'
assert `"`c(rngstate)'"' == `"`caller_rngstate'"'

di as result "FESIM NETWORK-BRIDGE INTEGRATION TESTS PASS"
