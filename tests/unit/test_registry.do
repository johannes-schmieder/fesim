version 16.0
clear all
set more off
set varabbrev off

quietly fesim_registry, action(list)
assert `"`r(dgps)'"' == "akm akmpaygap bm"
assert `"`r(aliases)'"' == "akmsimple akmempirical bmsimple"
assert r(n_dgps) == 3

quietly fesim_registry, action(resolve) dgp(AKMSIMPLE)
assert `"`r(dgp)'"' == "akm"
assert `"`r(dgp_alias)'"' == "akmsimple"
assert `"`r(preset)'"' == "simple"
assert `"`r(configurable)'"' == "yes"
assert `"`r(config_schema)'"' == "akm_simple_v1"

quietly fesim_registry, action(resolve) dgp(akm) preset(SIMPLE)
assert `"`r(dgp)'"' == "akm"
assert `"`r(preset)'"' == "simple"

quietly fesim_registry, action(resolve) dgp(AKMEMPIRICAL)
assert `"`r(dgp)'"' == "akm"
assert `"`r(preset)'"' == "empirical"
assert `"`r(configurable)'"' == "no"
assert `"`r(config_schema)'"' == ""

capture noisily fesim_registry, action(resolve) dgp(akmsimple) preset(empirical)
assert _rc == 198
capture noisily fesim_registry, action(resolve) dgp(unknown)
assert _rc == 198
capture noisily fesim_registry, action(resolve) dgp(bm) preset(unknown)
assert _rc == 198

quietly fesim_registry, action(parameters) dgp(akm) preset(simple)
assert `"`r(common_options)'"' == "workers firms periods frequency start seed initial burnin jobrule truth connectivity report"
assert `"`r(scalar_parameters)'"' == "workers firms periods burnin mu sd_worker sd_firm sd_error firm_size_sd p_eu p_ee p_ue wage_trend"
assert `"`r(model_parameters)'"' == "mu sd_worker sd_firm sd_error firm_size_sd p_eu p_ee p_ue wage_trend"

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

capture noisily fesim_registry, action(parameter) dgp(akm) ///
    preset(empirical) parameter(mu)
assert _rc == 498
capture noisily fesim_registry, action(parameter) dgp(akm) ///
    preset(simple) parameter(unknown)
assert _rc == 198

di as result "FESIM REGISTRY TESTS PASS"
