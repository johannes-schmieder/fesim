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
assert `"`r(config_schema)'"' == "akm_simple_v3"
assert `"`r(seed)'"' == "current"
assert `"`r(network)'"' == "random"
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
assert `"`r(parameter_names)'"' == "workers firms periods burnin mu sd_worker sd_firm sd_error firm_size_sd p_eu p_ee p_ue wage_trend block_count block_log_bonus bridge_count ladder_down_share ladder_lateral_share ladder_up_share ladder_band"
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

quietly fesim_config, dgp(akmempirical)
local stylized_alias_config `"`r(config)'"'
tempname stylized_alias_parameters stylized_canonical_parameters
matrix `stylized_alias_parameters' = r(parameters)
assert `"`r(dgp)'"' == "akm"
assert `"`r(preset)'"' == "stylized"
assert `"`r(config_schema)'"' == "akm_stylized_v3"
assert `"`r(calibration_class)'"' == "stylized"
assert `"`r(initial)'"' == "random"
assert `"`r(internal_clock)'"' == "month"
assert r(burnin) == 5
assert rowsof(`stylized_alias_parameters') == 34
assert reldif(`stylized_alias_parameters'["rho_z_alpha", "value"], .3) < 1e-12
assert reldif(`stylized_alias_parameters'["rho_q_psi", "value"], .5) < 1e-12
assert reldif(`stylized_alias_parameters'["theta_sort", "value"], .25) < 1e-12
quietly fesim_config, dgp(akm) preset(stylized)
matrix `stylized_canonical_parameters' = r(parameters)
assert `"`stylized_alias_config'"' == `"`r(config)'"'
assert mreldif(`stylized_alias_parameters', ///
    `stylized_canonical_parameters') == 0

quietly fesim_config, dgp(akmempirical) frequency(quarter) ///
    parameters(theta_sort .4 eu_duration -.3)
assert `"`r(calibration_class)'"' == "stylized_modified"
assert `"`r(model_overrides)'"' == "eu_duration=-.3 theta_sort=.4"
assert `"`r(parameter_overrides)'"' == "eu_duration=-.3 theta_sort=.4"
assert `"`r(internal_clock)'"' == "month"

quietly fesim_config, dgp(akm) preset(germany_chk_2002_2009)
tempname germany_parameters
matrix `germany_parameters' = r(parameters)
assert `"`r(preset)'"' == "germany_chk_2002_2009"
assert `"`r(config_schema)'"' == "akm_germany_chk_2002_2009_v1"
assert `"`r(calibration_class)'"' == "targeted"
assert `"`r(start)'"' == "2002"
assert `"`r(initial)'"' == "random"
assert `"`r(internal_clock)'"' == "month"
assert r(workers) == 10000
assert r(firms) == 1000
assert r(periods) == 8
assert r(burnin) == 5
assert reldif(`germany_parameters'["sd_worker", "value"], .357) < 1e-12
assert reldif(`germany_parameters'["sd_firm", "value"], .230) < 1e-12
assert reldif(`germany_parameters'["sd_error", "value"], .135) < 1e-12
assert reldif(`germany_parameters'["theta_sort", "value"], 2.2) < 1e-12

quietly fesim_config, dgp(akm) preset(germany_chk_2002_2009) ///
    frequency(quarter)
assert `"`r(start)'"' == "2002q1"
quietly fesim_config, dgp(akm) preset(germany_chk_2002_2009) ///
    parameters(theta_sort 2.1)
assert `"`r(calibration_class)'"' == "targeted_modified"
assert `"`r(model_overrides)'"' == "theta_sort=2.1"

quietly fesim_config, dgp(akmpaygap) preset(simple)
tempname paygap_simple_parameters
matrix `paygap_simple_parameters' = r(parameters)
assert `"`r(config_schema)'"' == "akmpaygap_simple_v1"
assert `"`r(calibration_class)'"' == "stylized"
assert `"`r(initial)'"' == "random"
assert `"`r(internal_clock)'"' == "output_period"
assert r(burnin) == 5
assert `paygap_simple_parameters'["female_share", "value"] == .5

quietly fesim_config, dgp(akmpaygap) preset(cck2016)
tempname paygap_cck_parameters
matrix `paygap_cck_parameters' = r(parameters)
assert `"`r(config_schema)'"' == "akmpaygap_cck2016_v1"
assert `"`r(calibration_class)'"' == "targeted"
assert `"`r(start)'"' == "2002"
assert r(firms) == 1000
assert r(periods) == 8
assert `paygap_cck_parameters'["sd_worker_m", "value"] == .420
assert `paygap_cck_parameters'["premium_loading_m", "value"] == .247
quietly fesim_config, dgp(akmpaygap) preset(cck2016) ///
    parameters(group_sort_m .5)
assert `"`r(calibration_class)'"' == "targeted_modified"
assert `"`r(model_overrides)'"' == "group_sort_m=.5"
capture noisily fesim_config, dgp(akmpaygap) network(blocks)
assert _rc == 198
capture noisily fesim_config, dgp(akmpaygap) initial(stationary)
assert _rc == 198
capture noisily fesim_config, dgp(akmpaygap) ///
    parameters(female_share 1)
assert _rc == 198
capture noisily fesim_config, dgp(akmpaygap) ///
    parameters(p_eu_m .7 p_ee_m .3)
assert _rc == 198

capture noisily fesim_config, dgp(akm) preset(empirical)
assert _rc == 198
capture noisily fesim_config, dgp(akmempirical) initial(stationary)
assert _rc == 198
capture noisily fesim_config, dgp(akmempirical) burnin(0)
assert _rc == 198
capture noisily fesim_config, dgp(akmempirical) firms(1)
assert _rc == 198
capture noisily fesim_config, dgp(akmempirical) ///
    parameters(rho_z_alpha 1.1)
assert _rc == 198
capture noisily fesim_config, dgp(akmempirical) ///
    parameters(sd_worker 0 rho_z_alpha .1)
assert _rc == 198
quietly fesim_config, dgp(akmempirical) initial(allunemployed) burnin(0) ///
    parameters(sd_worker 0 rho_z_alpha 0 sd_firm 0 rho_q_psi 0)
assert r(burnin) == 0
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

quietly fesim_config, network(blocks) workers(12) firms(8) ///
    parameters(block_count 4 block_log_bonus 0)
assert `"`r(network)'"' == "blocks"
assert `"`r(parameters_supplied)'"' == "block_count block_log_bonus"
assert r(parameters)["block_count", "value"] == 4
assert r(parameters)["block_log_bonus", "value"] == 0
assert strpos(`"`r(config_sources)'"', "block_count=parameters") > 0
assert `"`r(calibration_class)'"' == "stylized"
assert `"`r(model_overrides)'"' == ""

quietly fesim_config, network(bridges) workers(12) firms(10) ///
    parameters(block_count 5)
assert r(parameters)["bridge_count", "value"] == 4
assert r(parameters)["bridge_count", "default"] == 4
assert strpos(`"`r(config_sources)'"', "bridge_count=derived") > 0
assert r(parameters)["block_log_bonus", "value"] == 0

quietly fesim_config, network(ladder) workers(12) firms(3) ///
    parameters(ladder_down_share .2 ladder_lateral_share .3 ///
        ladder_up_share .5 ladder_band .15)
assert `"`r(network)'"' == "ladder"
assert `"`r(parameters_supplied)'"' == ///
    "ladder_down_share ladder_lateral_share ladder_up_share ladder_band"
assert r(parameters)["ladder_down_share", "value"] == .2
assert r(parameters)["ladder_lateral_share", "value"] == .3
assert r(parameters)["ladder_up_share", "value"] == .5
assert r(parameters)["ladder_band", "value"] == .15
assert `"`r(calibration_class)'"' == "stylized"
assert `"`r(model_overrides)'"' == ""

capture noisily fesim_config, network(random) parameters(block_count 4)
assert _rc == 198
capture noisily fesim_config, network(blocks) parameters(bridge_count 4)
assert _rc == 198
capture noisily fesim_config, network(bridges) parameters(block_log_bonus 1)
assert _rc == 198
capture noisily fesim_config, network(random) parameters(ladder_band .2)
assert _rc == 198
capture noisily fesim_config, network(ladder) parameters(block_count 3)
assert _rc == 198
capture noisily fesim_config, network(ladder) ///
    parameters(ladder_down_share .2 ladder_lateral_share .2 ///
        ladder_up_share .5)
assert _rc == 198
capture noisily fesim_config, network(ladder) parameters(ladder_band 1.1)
assert _rc == 198
capture noisily fesim_config, network(blocks) workers(3) firms(8) ///
    parameters(block_count 4)
assert _rc == 198
capture noisily fesim_config, network(bridges) workers(8) firms(8) ///
    parameters(block_count 5 bridge_count 3)
assert _rc == 198
capture noisily fesim_config, network(bridges) workers(4) firms(4) ///
    parameters(block_count 4 bridge_count 5)
assert _rc == 198
capture noisily fesim_config, network(bridges) workers(12) firms(7) ///
    parameters(block_count 4)
assert _rc == 198

di as result "FESIM CONFIGURATION TESTS PASS"
