version 16.0
clear all
set more off
set varabbrev off

mata: assert(fesim_output_schema_version() == 1)
mata: assert(fesim_output_checked_rows(37, 7) == 259)
mata: assert(fesim_output_default_block(10000, 10) == 10000)
mata: assert(fesim_output_default_block(100000, 10) == 25000)
mata: assert(fesim_output_final_bytes(10000, 10) == 2100000)
mata: assert(fesim_output_peak_bytes(10000, 10, 1000) == 2820000)

set rng mt64
set seed 7654321
local rng_before `"`c(rngstate)'"'
mata: assert(fesim_output_toy_panel(37, 7, 1) == 259)
assert `"`c(rngstate)'"' == `"`rng_before'"'
assert _N == 259
isid workerid time
assert workerid == floor((_n - 1) / 7) + 1
assert time == mod(_n - 1, 7) + 1
assert missing(firmid) == !employed
assert missing(lnwage) == !employed
assert inrange(firmid, 1, 97) if employed
local worker_type : type workerid
local time_type : type time
local firm_type : type firmid
local employed_type : type employed
local wage_type : type lnwage
assert `"`worker_type'"' == "long"
assert `"`time_type'"' == "long"
assert `"`firm_type'"' == "long"
assert `"`employed_type'"' == "byte"
assert `"`wage_type'"' == "double"
mata: block_one = st_data(., .)

clear
mata: assert(fesim_output_toy_panel(37, 7, 9) == 259)
mata: block_nine = st_data(., .)
mata: assert(mreldif(block_one, block_nine) == 0)

clear
mata: assert(fesim_output_toy_panel(37, 7, 37) == 259)
mata: block_all = st_data(., .)
mata: assert(mreldif(block_one, block_all) == 0)

capture mata: fesim_output_checked_rows(2147483647, 2)
assert _rc == 3300
capture mata: fesim_output_checked_rows(0, 10)
assert _rc == 3300
capture mata: fesim_output_toy_panel(10, 2, 0)
assert _rc == 3300

di as result "FESIM BLOCK OUTPUT TESTS PASS"
