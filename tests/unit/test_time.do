version 16.0
clear all
set more off
set varabbrev off

set seed 24681357
set obs 3
generate long original_id = _n
quietly datasignature set, reset
local rng_before `"`c(rngstate)'"'

quietly fesim_time, frequency(year) periods(3)
assert `"`r(frequency)'"' == "year"
assert `"`r(start)'"' == "2000"
assert `"`r(format)'"' == "%ty"
assert `"`r(interval_unit)'"' == "year"
assert `"`r(internal_clock)'"' == "output_period"
assert r(start_value) == yearly("2000", "Y")
assert r(end_value) == yearly("2002", "Y")
assert r(periods_per_year) == 1
assert r(delta_years) == 1
quietly datasignature confirm
assert `"`c(rngstate)'"' == `"`rng_before'"'

quietly fesim_time, frequency(QUARTER) start(1999q4) periods(6)
assert `"`r(frequency)'"' == "quarter"
assert `"`r(start)'"' == "1999q4"
assert `"`r(format)'"' == "%tq"
assert r(start_value) == quarterly("1999q4", "YQ")
assert r(end_value) == quarterly("2001q1", "YQ")
assert r(periods_per_year) == 4
assert r(delta_years) == .25

quietly fesim_time, frequency(month) start(2020m2) periods(13)
assert `"`r(format)'"' == "%tm"
assert r(start_value) == monthly("2020m2", "YM")
assert r(end_value) == monthly("2021m2", "YM")
assert r(periods_per_year) == 12
assert abs(r(delta_years) - 1 / 12) < 1e-15

quietly fesim_time, frequency(month) start(2019m2)
local nonleap_delta = r(delta_years)
quietly fesim_time, frequency(month) start(2020m2)
assert abs(r(delta_years) - `nonleap_delta') < 1e-15

quietly fesim_config, frequency(month) start(2020m2) periods(13)
assert `"`r(time_format)'"' == "%tm"
assert `"`r(interval_unit)'"' == "month"
assert `"`r(internal_clock)'"' == "output_period"
assert r(start_value) == monthly("2020m2", "YM")
assert r(end_value) == monthly("2021m2", "YM")
assert r(periods_per_year) == 12
assert abs(r(delta_years) - 1 / 12) < 1e-15

mata:
assert(fesim_time_schema_version() == 1)
assert(fesim_time_periods_per_year(" YEAR ") == 1)
assert(fesim_time_periods_per_year("quarter") == 4)
assert(fesim_time_periods_per_year("month") == 12)
assert(fesim_time_delta_years("quarter") == .25)
assert(fesim_time_values(100, 4) == (100::103))
end

capture noisily fesim_time, frequency(week)
assert _rc == 198
capture noisily fesim_time, frequency(year) start(200)
assert _rc == 198
capture noisily fesim_time, frequency(quarter) start(2000q5)
assert _rc == 198
capture noisily fesim_time, frequency(month) start(2000m0)
assert _rc == 198
capture noisily fesim_time, frequency(month) start(2000m01)
assert _rc == 198
capture noisily fesim_time, frequency(year) periods(0)
assert _rc == 198
capture mata: fesim_time_periods_per_year("week")
assert _rc == 3300
capture mata: fesim_time_values(100, 0)
assert _rc == 3300

quietly datasignature confirm
assert `"`c(rngstate)'"' == `"`rng_before'"'
di as result "FESIM TIME ENGINE TESTS PASS"
