version 16.0
clear all
set more off
set varabbrev off

tempfile simple_random stylized_random firm_ranks

local simple_options workers(20000) firms(100) periods(2) seed(731904) ///
    truth(full) parameters(p_eu .01 p_ee .70 p_ue .80)
quietly fesim, dgp(akm) preset(simple) network(random) ///
    `simple_options' clear noreport
sort workerid time
rename employed employed_random
rename firmid firmid_random
rename ntransitions ntransitions_random
rename from_unemp from_unemp_random
rename to_unemp to_unemp_random
rename jobtojob jobtojob_random
keep workerid time employed_random firmid_random ntransitions_random ///
    from_unemp_random to_unemp_random jobtojob_random
save `simple_random'

quietly fesim, dgp(akm) preset(simple) network(ladder) ///
    `simple_options' clear noreport
assert `"`r(network_design)'"' == "ladder"
assert r(parameters)["ladder_down_share", "value"] == .1
assert r(parameters)["ladder_lateral_share", "value"] == .2
assert r(parameters)["ladder_up_share", "value"] == .7
assert r(parameters)["ladder_band", "value"] == .1
assert strpos(`"`r(command)'"', "network=ladder") > 0
capture confirm variable worker_block_true
assert _rc == 111
capture confirm variable firm_block_true
assert _rc == 111
capture confirm variable nbridges_imposed
assert _rc == 111

sort workerid time
merge 1:1 workerid time using `simple_random', assert(match) nogen
assert employed == employed_random
assert ntransitions == ntransitions_random if !missing(ntransitions)
assert from_unemp == from_unemp_random if !missing(from_unemp)
assert to_unemp == to_unemp_random if !missing(to_unemp)
assert jobtojob == jobtojob_random if !missing(jobtojob)
by workerid: assert firmid == firmid_random if _n == 1
assert firmid == firmid_random if from_unemp == 1

preserve
keep if employed == 1
keep firmid psi_true
bysort firmid: keep if _n == 1
isid firmid
assert _N == 100
egen double __rank = rank(psi_true), unique
generate double firm_rank = (__rank - .5) / 100
keep firmid firm_rank
save `firm_ranks', replace
restore
merge m:1 firmid using `firm_ranks', assert(master match) nogen
sort workerid time
by workerid: generate double origin_rank = firm_rank[_n - 1]
generate double rank_change = firm_rank - origin_rank if jobtojob == 1
generate byte ladder_down = rank_change < -.1 - 1e-12 if jobtojob == 1
generate byte ladder_lateral = abs(rank_change) <= .1 + 1e-12 ///
    if jobtojob == 1
generate byte ladder_up = rank_change > .1 + 1e-12 if jobtojob == 1
count if jobtojob == 1 & origin_rank > .15 & origin_rank < .85
assert r(N) > 3000
quietly summarize ladder_down if ///
    jobtojob == 1 & origin_rank > .15 & origin_rank < .85, meanonly
assert abs(r(mean) - .1) < .03
quietly summarize ladder_lateral if ///
    jobtojob == 1 & origin_rank > .15 & origin_rank < .85, meanonly
assert abs(r(mean) - .2) < .03
quietly summarize ladder_up if ///
    jobtojob == 1 & origin_rank > .15 & origin_rank < .85, meanonly
assert abs(r(mean) - .7) < .03

local stylized_options workers(20000) firms(100) periods(3) ///
    frequency(month) start(2000m1) seed(850217) truth(full) ///
    initial(allunemployed) burnin(0) ///
    parameters(kappa_eu -5 kappa_ee 2 kappa_ue 2)
quietly fesim, dgp(akm) preset(stylized) network(random) ///
    `stylized_options' clear noreport
sort workerid time
rename employed employed_random
rename firmid firmid_random
rename ntransitions ntransitions_random
rename from_unemp from_unemp_random
rename to_unemp to_unemp_random
rename jobtojob jobtojob_random
keep workerid time employed_random firmid_random ntransitions_random ///
    from_unemp_random to_unemp_random jobtojob_random
save `stylized_random', replace

quietly fesim, dgp(akm) preset(stylized) network(ladder) ///
    `stylized_options' clear noreport
assert `"`r(network_design)'"' == "ladder"
capture confirm variable worker_block_true
assert _rc == 111
sort workerid time
merge 1:1 workerid time using `stylized_random', assert(match) nogen
by workerid: assert employed == employed_random if _n <= 3
by workerid: assert firmid == firmid_random if _n <= 2
by workerid: assert ntransitions == ntransitions_random if _n <= 3 & ///
    !missing(ntransitions)
by workerid: assert from_unemp == from_unemp_random if _n <= 3 & ///
    !missing(from_unemp)
by workerid: assert to_unemp == to_unemp_random if _n <= 3 & ///
    !missing(to_unemp)
by workerid: assert jobtojob == jobtojob_random if _n <= 3 & ///
    !missing(jobtojob)
assert firmid == firmid_random if from_unemp == 1

preserve
keep if employed == 1
keep firmid psi_true
bysort firmid: keep if _n == 1
isid firmid
assert _N == 100
egen double __rank = rank(psi_true), unique
generate double firm_rank_new = (__rank - .5) / 100
keep firmid firm_rank_new
save `firm_ranks', replace
restore
merge m:1 firmid using `firm_ranks', assert(master match) nogen
sort workerid time
by workerid: generate double origin_rank_new = firm_rank_new[_n - 1]
generate double rank_change_new = firm_rank_new - origin_rank_new ///
    if jobtojob == 1
generate byte ladder_down_new = rank_change_new < -.1 - 1e-12 ///
    if jobtojob == 1
generate byte ladder_lateral_new = abs(rank_change_new) <= .1 + 1e-12 ///
    if jobtojob == 1
generate byte ladder_up_new = rank_change_new > .1 + 1e-12 ///
    if jobtojob == 1
count if jobtojob == 1 & origin_rank_new > .15 & origin_rank_new < .85
assert r(N) > 1500
quietly summarize ladder_down_new if ///
    jobtojob == 1 & origin_rank_new > .15 & origin_rank_new < .85, meanonly
assert abs(r(mean) - .1) < .04
quietly summarize ladder_lateral_new if ///
    jobtojob == 1 & origin_rank_new > .15 & origin_rank_new < .85, meanonly
assert abs(r(mean) - .2) < .04
quietly summarize ladder_up_new if ///
    jobtojob == 1 & origin_rank_new > .15 & origin_rank_new < .85, meanonly
assert abs(r(mean) - .7) < .04

di as result "FESIM LADDER NETWORK INTEGRATION TESTS PASS"
