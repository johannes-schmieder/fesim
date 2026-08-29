version 16.0
clear all
set more off
set varabbrev off

quietly fesim_config
local default_config `"`r(config)'"'
local default_sources `"`r(config_sources)'"'
tempname default_parameters canonical_parameters alias_parameters ordered_a ordered_b
matrix `default_parameters' = r(parameters)
assert `"`r(dgp)'"' == "akm"
assert `"`r(preset)'"' == "simple"
assert `"`r(calibration_class)'"' == "stylized"
assert `"`r(config_schema)'"' == "akm_simple_v1"
assert `"`r(seed)'"' == "current"
assert `"`r(frequency)'"' == "year"
assert `"`r(start)'"' == "2000"
assert r(workers) == 10000
assert r(firms) == 500
assert r(periods) == 10
assert r(N_requested) == 100000
assert `"`r(overrides)'"' == ""
assert `"`r(parameter_overrides)'"' == ""
assert `"`r(model_overrides)'"' == ""
assert strpos(`"`default_sources'"', "workers=preset") > 0
assert strpos(`"`default_sources'"', "frequency=package") > 0

quietly fesim_config, dgp(akm) preset(simple)
local canonical_config `"`r(config)'"'
matrix `canonical_parameters' = r(parameters)
quietly fesim_config, dgp(AKMSIMPLE)
local alias_config `"`r(config)'"'
matrix `alias_parameters' = r(parameters)
assert `"`default_config'"' == `"`canonical_config'"'
assert `"`default_config'"' == `"`alias_config'"'
assert mreldif(`default_parameters', `canonical_parameters') == 0
assert mreldif(`default_parameters', `alias_parameters') == 0

quietly fesim_config, workers(20) firms(4) periods(3) burnin(2) ///
    frequency(quarter) start(2010q2) seed(42) initial(random) ///
    truth(full) connectivity(largest) noreport ///
    parameters(mu 4 sd_worker .5 p_ee .2)
assert r(workers) == 20
assert r(firms) == 4
assert r(periods) == 3
assert r(burnin) == 2
assert r(N_requested) == 60
assert `"`r(frequency)'"' == "quarter"
assert `"`r(start)'"' == "2010q2"
assert `"`r(seed)'"' == "42"
assert `"`r(initial)'"' == "random"
assert `"`r(truth)'"' == "full"
assert `"`r(connectivity)'"' == "largest"
assert `"`r(report)'"' == "noreport"
assert `"`r(calibration_class)'"' == "stylized_modified"
assert `"`r(parameter_names)'"' == "workers firms periods burnin mu sd_worker sd_firm sd_error firm_size_sd p_eu p_ee p_ue wage_trend"
assert `"`r(parameters_supplied)'"' == "mu sd_worker p_ee"
assert `"`r(parameter_overrides)'"' == "mu=4 sd_worker=.5 p_ee=.2"
assert `"`r(model_overrides)'"' == "mu=4 sd_worker=.5 p_ee=.2"
assert strpos(`"`r(config_sources)'"', "mu=parameters") > 0
assert strpos(`"`r(config_sources)'"', "workers=option") > 0
tempname modified
matrix `modified' = r(parameters)
assert `modified'[1,1] == 20
assert `modified'[5,1] == 4
assert reldif(`modified'[6,1], .5) < 1e-12
assert reldif(`modified'[11,1], .2) < 1e-12

quietly fesim_config, workers(20)
assert `"`r(calibration_class)'"' == "stylized"
assert `"`r(model_overrides)'"' == ""

quietly fesim_config, workers(20) firms(4) periods(3) ///
    parameters(mu 4 p_ue .7)
local ordered_config_a `"`r(config)'"'
matrix `ordered_a' = r(parameters)
quietly fesim_config, parameters(p_ue .7 mu 4) periods(3) ///
    firms(4) workers(20)
local ordered_config_b `"`r(config)'"'
matrix `ordered_b' = r(parameters)
assert `"`ordered_config_a'"' == `"`ordered_config_b'"'
assert mreldif(`ordered_a', `ordered_b') == 0

capture noisily fesim_config, dgp(akmempirical)
assert _rc == 498
capture noisily fesim_config, parameters(unknown 1)
assert _rc == 198
capture noisily fesim_config, parameters(frequency 1)
assert _rc == 198
capture noisily fesim_config, parameters(mu)
assert _rc == 198
capture noisily fesim_config, parameters(mu 4 mu 5)
assert _rc == 198
capture noisily fesim_config, workers(10) parameters(workers 20)
assert _rc == 198
capture noisily fesim_config, parameters(mu notanumber)
assert _rc == 198
capture noisily fesim_config, workers(1.5)
assert _rc == 198
capture noisily fesim_config, workers(0)
assert _rc == 198
capture noisily fesim_config, parameters(sd_error -1)
assert _rc == 198
capture noisily fesim_config, parameters(p_ue 1.1)
assert _rc == 198
capture noisily fesim_config, parameters(p_eu .7 p_ee .3)
assert _rc == 198
capture noisily fesim_config, firms(1)
assert _rc == 198
capture noisily fesim_config, workers(2147483647) periods(2)
assert _rc == 198
capture noisily fesim_config, frequency(week)
assert _rc == 198
capture noisily fesim_config, frequency(quarter) start(2000m1)
assert _rc == 198
capture noisily fesim_config, seed(notaninteger)
assert _rc == 198
capture noisily fesim_config, seed(current)
assert _rc == 198
capture noisily fesim_config, initial(random)
assert _rc == 198
quietly fesim_config, initial(random) burnin(1)
assert `"`r(initial)'"' == "random"
assert r(burnin) == 1
capture noisily fesim_config, report noreport
assert _rc == 198

di as result "FESIM CONFIGURATION TESTS PASS"
