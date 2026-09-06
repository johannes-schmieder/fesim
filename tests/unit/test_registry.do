version 16.0
clear all
set more off
set varabbrev off

quietly fesim_registry, action(list)
assert `"`r(dgps)'"' == "akm akmpaygap bm cpv blm"
assert `"`r(aliases)'"' == "akmsimple akmempirical bmsimple"
assert `"`r(qualified)'"' == ///
    "akm/simple akm/stylized akm/germany_chk_2002_2009 akmpaygap/simple akmpaygap/cck2016 bm/simple cpv/simple cpv/heterogeneous blm/static blm/dynamic"
assert `"`r(status)'"' == "partial"
assert r(n_dgps) == 5

quietly fesim_registry, action(resolve) dgp(AKMSIMPLE)
assert `"`r(dgp)'"' == "akm"
assert `"`r(dgp_alias)'"' == "akmsimple"
assert `"`r(preset)'"' == "simple"
assert `"`r(configurable)'"' == "yes"
assert `"`r(config_schema)'"' == "akm_simple_v3"
assert `"`r(status)'"' == "qualified"
assert `"`r(implemented)'"' == "yes"

quietly fesim_registry, action(resolve) dgp(akm) preset(SIMPLE)
assert `"`r(dgp)'"' == "akm"
assert `"`r(preset)'"' == "simple"

quietly fesim_registry, action(resolve) dgp(AKMEMPIRICAL)
assert `"`r(dgp)'"' == "akm"
assert `"`r(preset)'"' == "stylized"
assert `"`r(configurable)'"' == "yes"
assert `"`r(config_schema)'"' == "akm_stylized_v3"
assert `"`r(status)'"' == "qualified"
assert `"`r(implemented)'"' == "yes"
assert `"`r(calibration_class)'"' == "stylized"

quietly fesim_registry, action(resolve) dgp(akm) ///
    preset(germany_chk_2002_2009)
assert `"`r(dgp)'"' == "akm"
assert `"`r(preset)'"' == "germany_chk_2002_2009"
assert `"`r(presets)'"' == "simple stylized germany_chk_2002_2009"
assert `"`r(configurable)'"' == "yes"
assert `"`r(config_schema)'"' == "akm_germany_chk_2002_2009_v1"
assert `"`r(calibration_class)'"' == "targeted"
assert `"`r(status)'"' == "qualified"
assert `"`r(implemented)'"' == "yes"

quietly fesim_registry, action(resolve) dgp(akmpaygap) preset(simple)
assert `"`r(dgp)'"' == "akmpaygap"
assert `"`r(presets)'"' == "simple cck2016"
assert `"`r(config_schema)'"' == "akmpaygap_simple_v1"
assert `"`r(calibration_class)'"' == "stylized"
assert `"`r(status)'"' == "qualified"
assert `"`r(implemented)'"' == "yes"
quietly fesim_registry, action(resolve) dgp(akmpaygap) preset(cck2016)
assert `"`r(config_schema)'"' == "akmpaygap_cck2016_v1"
assert `"`r(calibration_class)'"' == "targeted"
assert `"`r(status)'"' == "qualified"

quietly fesim_registry, action(parameters) dgp(akmpaygap) preset(cck2016)
assert strpos(`"`r(model_parameters)'"', "female_share") == 1
assert strpos(`"`r(model_parameters)'"', "premium_loading_f") > 0
assert strpos(`"`r(model_parameters)'"', "worker_sort_m") > 0
quietly fesim_registry, action(parameter) dgp(akmpaygap) ///
    preset(cck2016) parameter(female_share)
assert r(default_value) == .46
assert r(lower_value) == 0
assert r(upper_value) == 1
assert `"`r(lower_closed)'"' == "no"
assert `"`r(upper_closed)'"' == "no"
quietly fesim_registry, action(parameter) dgp(akmpaygap) ///
    preset(cck2016) parameter(premium_loading_f)
assert reldif(r(default_value), .12567) < 1e-12
quietly fesim_registry, action(parameter) dgp(akmpaygap) ///
    preset(cck2016) parameter(premium_deviation_sd_f)
assert reldif(r(default_value), .171976891180182) < 1e-12

capture noisily fesim_registry, action(resolve) dgp(akmsimple) preset(stylized)
assert _rc == 198
capture noisily fesim_registry, action(resolve) dgp(unknown)
assert _rc == 198
capture noisily fesim_registry, action(resolve) dgp(bm) preset(unknown)
assert _rc == 198

quietly fesim_registry, action(parameters) dgp(akm) preset(simple)
assert `"`r(common_options)'"' == "workers firms periods frequency start seed initial burnin jobrule truth connectivity network report"
assert `"`r(scalar_parameters)'"' == "workers firms periods burnin mu sd_worker sd_firm sd_error firm_size_sd p_eu p_ee p_ue wage_trend block_count block_log_bonus bridge_count ladder_down_share ladder_lateral_share ladder_up_share ladder_band"
assert `"`r(model_parameters)'"' == "mu sd_worker sd_firm sd_error firm_size_sd p_eu p_ee p_ue wage_trend"
assert `"`r(network_parameters)'"' == "block_count block_log_bonus bridge_count ladder_down_share ladder_lateral_share ladder_up_share ladder_band"

quietly fesim_registry, action(parameter) dgp(akm) preset(simple) parameter(workers)
assert `"`r(type)'"' == "integer"
assert r(default_value) == 10000
assert r(lower_value) == 1
assert r(upper_value) == 2147483647
assert `"`r(scope)'"' == "common"
assert `"`r(named_option)'"' == "yes"
assert `"`r(parameters_allowed)'"' == "yes"

quietly fesim_registry, action(parameter) dgp(akm) preset(simple) parameter(p_ee)
assert reldif(r(default_value), .12) < 1e-12
assert r(lower_value) == 0
assert r(upper_value) == 1
assert `"`r(lower_closed)'"' == "yes"
assert `"`r(upper_closed)'"' == "no"
assert `"`r(unit)'"' == "probability"
assert strpos(`"`r(description)'"', "Annual") == 1

foreach name in mu sd_worker sd_firm sd_error firm_size_sd p_eu p_ee p_ue wage_trend {
    quietly fesim_registry, action(parameter) dgp(akm) ///
        preset(simple) parameter(`name')
    assert `"`r(scope)'"' == "model"
    assert `"`r(named_option)'"' == "no"
    assert `"`r(parameters_allowed)'"' == "yes"
}

quietly fesim_registry, action(parameter) dgp(akm) preset(simple) parameter(frequency)
assert `"`r(type)'"' == "string"
assert `"`r(default)'"' == "year"
assert `"`r(parameters_allowed)'"' == "no"
assert `"`r(default_source)'"' == "package"

quietly fesim_registry, action(parameters) dgp(akm) preset(stylized)
assert `"`r(config_schema)'"' == "akm_stylized_v3"
assert `"`r(scalar_parameters)'"' == ///
    "workers firms periods burnin mu sd_worker sd_firm sd_error firm_size_sd wage_trend rho_z_alpha rho_q_psi kappa_eu eu_worker eu_firm eu_duration kappa_ee ee_worker ee_firm ee_duration kappa_ue ue_worker ue_duration theta_sort theta_quality theta_up theta_down block_count block_log_bonus bridge_count ladder_down_share ladder_lateral_share ladder_up_share ladder_band"
assert `"`r(model_parameters)'"' == ///
    "mu sd_worker sd_firm sd_error firm_size_sd wage_trend rho_z_alpha rho_q_psi kappa_eu eu_worker eu_firm eu_duration kappa_ee ee_worker ee_firm ee_duration kappa_ue ue_worker ue_duration theta_sort theta_quality theta_up theta_down"

quietly fesim_registry, action(parameters) dgp(akm) ///
    preset(germany_chk_2002_2009)
assert `"`r(config_schema)'"' == "akm_germany_chk_2002_2009_v1"
quietly fesim_registry, action(parameter) dgp(akm) ///
    preset(germany_chk_2002_2009) parameter(firms)
assert r(default_value) == 1000
quietly fesim_registry, action(parameter) dgp(akm) ///
    preset(germany_chk_2002_2009) parameter(periods)
assert r(default_value) == 8
quietly fesim_registry, action(parameter) dgp(akm) ///
    preset(germany_chk_2002_2009) parameter(sd_worker)
assert reldif(r(default_value), .357) < 1e-12
quietly fesim_registry, action(parameter) dgp(akm) ///
    preset(germany_chk_2002_2009) parameter(sd_firm)
assert reldif(r(default_value), .230) < 1e-12
quietly fesim_registry, action(parameter) dgp(akm) ///
    preset(germany_chk_2002_2009) parameter(sd_error)
assert reldif(r(default_value), .135) < 1e-12
quietly fesim_registry, action(parameter) dgp(akm) ///
    preset(germany_chk_2002_2009) parameter(theta_sort)
assert reldif(r(default_value), 2.2) < 1e-12

quietly fesim_registry, action(parameter) dgp(akm) ///
    preset(stylized) parameter(burnin)
assert r(default_value) == 5
assert `"`r(unit)'"' == "years"
quietly fesim_registry, action(parameter) dgp(akm) ///
    preset(stylized) parameter(rho_z_alpha)
assert r(default_value) == .3
assert r(lower_value) == -1
assert r(upper_value) == 1
quietly fesim_registry, action(parameter) dgp(akm) ///
    preset(stylized) parameter(kappa_eu)
assert reldif(r(default_value), -2.416230718633671) < 1e-12
assert `"`r(unit)'"' == "log annual hazard"
quietly fesim_registry, action(parameter) dgp(akm) ///
    preset(stylized) parameter(theta_down)
assert r(default_value) == -.1
quietly fesim_registry, action(parameter) dgp(akm) ///
    preset(simple) parameter(network)
assert `"`r(default)'"' == "random"
assert `"`r(named_option)'"' == "yes"
assert `"`r(parameters_allowed)'"' == "no"
quietly fesim_registry, action(parameter) dgp(akm) ///
    preset(simple) parameter(block_count)
assert r(default_value) == 4
assert r(lower_value) == 2
assert `"`r(scope)'"' == "network"
quietly fesim_registry, action(parameter) dgp(akm) ///
    preset(simple) parameter(block_log_bonus)
assert reldif(r(default_value), ln(9)) < 1e-12
assert r(lower_value) == 0
quietly fesim_registry, action(parameter) dgp(akm) ///
    preset(simple) parameter(bridge_count)
assert r(default_value) == 3
assert `"`r(scope)'"' == "network"
quietly fesim_registry, action(parameter) dgp(akm) ///
    preset(simple) parameter(ladder_down_share)
assert r(default_value) == .1
assert r(lower_value) == 0
assert r(upper_value) == 1
assert `"`r(scope)'"' == "network"
quietly fesim_registry, action(parameter) dgp(akm) ///
    preset(simple) parameter(ladder_lateral_share)
assert r(default_value) == .2
quietly fesim_registry, action(parameter) dgp(akm) ///
    preset(simple) parameter(ladder_up_share)
assert r(default_value) == .7
quietly fesim_registry, action(parameter) dgp(akm) ///
    preset(simple) parameter(ladder_band)
assert r(default_value) == .1
assert `"`r(unit)'"' == "percentile-rank distance"
capture noisily fesim_registry, action(parameter) dgp(akm) ///
    preset(simple) parameter(unknown)
assert _rc == 198

di as result "FESIM REGISTRY TESTS PASS"
