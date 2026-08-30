version 16.0
clear all
set more off
set varabbrev off

local simple_options workers(80) firms(16) periods(6) frequency(quarter) ///
    start(2000q1) seed(24680) truth(basic) connectivity(keep) ///
    noreport clear

quietly fesim, dgp(akm) preset(simple) network(random) `simple_options'
matrix simple_random_moments = r(moments)
matrix simple_random_targets = r(targets)
matrix simple_random_network = r(network)
local simple_random_design `"`r(network_design)'"'
assert `"`simple_random_design'"' == "random"
capture confirm variable worker_block_true
assert _rc == 111
tempfile simple_random
quietly save `simple_random'

quietly fesim, dgp(akm) preset(simple) network(blocks) `simple_options' ///
    parameters(block_count 4 block_log_bonus 0)
matrix simple_zero_moments = r(moments)
matrix simple_zero_targets = r(targets)
matrix simple_zero_network = r(network)
quietly cf _all using `simple_random'
mata: assert(mreldif(st_matrix("simple_random_moments"), ///
    st_matrix("simple_zero_moments")) == 0)
mata: assert(mreldif(st_matrix("simple_random_targets"), ///
    st_matrix("simple_zero_targets")) == 0)
mata: assert(mreldif(st_matrix("simple_random_network"), ///
    st_matrix("simple_zero_network")) == 0)

quietly fesim, dgp(akm) preset(simple) network(blocks) workers(120) ///
    firms(24) periods(8) frequency(quarter) start(2000q1) seed(13579) ///
    truth(full) connectivity(keep) noreport clear ///
    parameters(block_count 4 block_log_bonus 2.1972245773362196)
assert `"`r(network_design)'"' == "blocks"
local metadata_design : char _dta[fesim_network_design]
assert `"`metadata_design'"' == "blocks"
confirm variable worker_block_true firm_block_true
assert inrange(worker_block_true, 1, 4)
assert missing(firm_block_true) == !employed
assert inrange(firm_block_true, 1, 4) if employed
by workerid (time): assert worker_block_true == worker_block_true[1]
bysort firmid (workerid time): assert ///
    firm_block_true == firm_block_true[1] if employed
preserve
quietly bysort workerid: keep if _n == 1
quietly contract worker_block_true
assert _freq == 30
assert _N == 4
restore
quietly count if employed
local employed = r(N)
quietly count if employed & worker_block_true == firm_block_true
assert r(N) / `employed' > .4

local stylized_options workers(80) firms(16) periods(4) frequency(quarter) ///
    start(2000q1) seed(97531) truth(basic) connectivity(keep) ///
    noreport clear
quietly fesim, dgp(akm) preset(stylized) network(random) ///
    `stylized_options'
matrix stylized_random_moments = r(moments)
matrix stylized_random_targets = r(targets)
matrix stylized_random_network = r(network)
matrix stylized_random_durations = r(durations)
tempfile stylized_random
quietly save `stylized_random'

quietly fesim, dgp(akm) preset(stylized) network(blocks) ///
    `stylized_options' parameters(block_count 4 block_log_bonus 0)
matrix stylized_zero_moments = r(moments)
matrix stylized_zero_targets = r(targets)
matrix stylized_zero_network = r(network)
matrix stylized_zero_durations = r(durations)
quietly cf _all using `stylized_random'
mata: assert(mreldif(st_matrix("stylized_random_moments"), ///
    st_matrix("stylized_zero_moments")) == 0)
mata: assert(mreldif(st_matrix("stylized_random_targets"), ///
    st_matrix("stylized_zero_targets")) == 0)
mata: assert(mreldif(st_matrix("stylized_random_network"), ///
    st_matrix("stylized_zero_network")) == 0)
mata: assert(mreldif(st_matrix("stylized_random_durations"), ///
    st_matrix("stylized_zero_durations")) == 0)

quietly fesim, dgp(akm) preset(stylized) network(blocks) workers(80) ///
    firms(16) periods(4) frequency(quarter) seed(97531) truth(full) ///
    connectivity(keep) noreport clear ///
    parameters(block_count 4 block_log_bonus 2.1972245773362196)
confirm variable worker_block_true firm_block_true
assert missing(firm_block_true) == !employed
by workerid (time): assert worker_block_true == worker_block_true[1]

di as result "FESIM BLOCK-NETWORK INTEGRATION TESTS PASS"
