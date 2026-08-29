version 16.0
clear all
set more off
set varabbrev off

mata:
annual = .6
quarter = fesim_rate_annual_to_interval(annual, .25)
month = fesim_rate_annual_to_interval(annual, 1 / 12)
assert(abs(fesim_rate_annual_to_interval(annual, 1) - annual) < 1e-15)
assert(abs((1 - quarter)^4 - (1 - annual)) < 1e-14)
assert(abs((1 - month)^12 - (1 - annual)) < 1e-14)
assert(fesim_rate_annual_to_interval(0, .25) == 0)
assert(fesim_rate_annual_to_interval(1, .25) == 1)
near_one = fesim_rate_annual_to_interval(.999999, 1 / 12)
assert(near_one > 0 & near_one < 1)

annual_competing = fesim_rate_competing_to_interval(.08, .12, 1)
assert(abs(annual_competing[1] - .08) < 1e-15)
assert(abs(annual_competing[2] - .12) < 1e-15)
assert(abs(annual_competing[3] - .80) < 1e-15)
assert(abs(sum(annual_competing) - 1) < 1e-15)

quarter_competing = fesim_rate_competing_to_interval(.08, .12, .25)
assert(abs(quarter_competing[3]^4 - .80) < 1e-14)
assert(abs(quarter_competing[1] / quarter_competing[2] - 2 / 3) < 1e-14)
assert(abs(sum(quarter_competing) - 1) < 1e-15)
assert(fesim_rate_competing_to_interval(0, 0, 1 / 12) == (0, 0, 1))
near_bound = fesim_rate_competing_to_interval(.499999, .5, 1 / 12)
assert(all(near_bound :> 0))
assert(abs(sum(near_bound) - 1) < 1e-15)
end

capture mata: fesim_rate_annual_to_interval(-.01, 1)
assert _rc == 3300
capture mata: fesim_rate_annual_to_interval(1.01, 1)
assert _rc == 3300
capture mata: fesim_rate_annual_to_interval(.5, 0)
assert _rc == 3300
capture mata: fesim_rate_competing_to_interval(-.01, .1, 1)
assert _rc == 3300
capture mata: fesim_rate_competing_to_interval(.6, .4, 1)
assert _rc == 3300
capture mata: fesim_rate_competing_to_interval(.1, .1, 0)
assert _rc == 3300

di as result "FESIM RATE CONVERSION TESTS PASS"
