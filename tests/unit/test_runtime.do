version 16.0
clear all
set more off
set varabbrev off

mata:
assert(fesim_runtime_schema_version() == 1)
timer_clear(100)
timer_on(100)
runtime_claimed = fesim_runtime_claim_timers(2)
assert(runtime_claimed == (99, 98))
fesim_runtime_start(runtime_claimed[1])
fesim_runtime_start(runtime_claimed[2])
runtime_second = fesim_runtime_stop(runtime_claimed[2])
runtime_first = fesim_runtime_stop(runtime_claimed[1])
assert(runtime_first >= 0)
assert(runtime_second >= 0)
fesim_runtime_release(runtime_claimed)
assert(timer_value(99) == (0, 0))
assert(timer_value(98) == (0, 0))
assert(timer_value(100)[2] == 1)
timer_off(100)
timer_clear(100)
end

capture mata: fesim_runtime_claim_timers(0)
assert _rc == 3300
capture mata: fesim_runtime_claim_timers(101)
assert _rc == 3300

mata: timer_clear(100); timer_on(100)
quietly fesim, workers(1000) firms(50) periods(5) seed(424242) ///
    truth(none) connectivity(keep) noreport clear
local runtime_total = r(runtime_total)
local runtime_solve = r(runtime_solve)
local runtime_simulate = r(runtime_simulate)
local runtime_output = r(runtime_output)
assert `runtime_total' >= 0
assert `runtime_solve' == 0
assert `runtime_simulate' >= 0
assert `runtime_output' >= 0
assert abs(`runtime_total' - `runtime_simulate' - `runtime_output') < 1e-12
mata: assert(timer_value(100)[2] == 1)
mata: assert(timer_value(99) == (0, 0)); assert(timer_value(98) == (0, 0))
mata: timer_off(100); timer_clear(100)

clear
set obs 2
generate original = _n
quietly datasignature set, reset
mata: timer_clear(100); timer_on(100)
capture fesim, workers(10) firms(3) periods(2) seed(123) ///
    initial(allunemployed) parameters(p_ue 0) truth(none) ///
    connectivity(largest) noreport clear
assert _rc == 459
quietly datasignature confirm
mata: assert(timer_value(100)[2] == 1)
mata: assert(timer_value(99) == (0, 0)); assert(timer_value(98) == (0, 0))
mata: timer_off(100); timer_clear(100)

di as result "FESIM RUNTIME TIMER TESTS PASS"
