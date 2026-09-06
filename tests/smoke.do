version 16.0
clear all
set more off
set varabbrev off

args repository_root
if `"`repository_root'"' == "" {
    di as error "smoke.do requires the repository root"
    exit 198
}

capture noisily which fesim
assert _rc == 0

capture noisily fesim version
assert _rc == 0
assert `"`r(version)'"' == "1.1.0-dev"
assert `"`r(status)'"' == "development"
assert r(api_level) == 1

capture noisily fesim list
assert _rc == 0
assert `"`r(dgps)'"' == "akm akmpaygap bm cpv"
assert `"`r(qualified)'"' == ///
    "akm/simple akm/stylized akm/germany_chk_2002_2009 akmpaygap/simple akmpaygap/cck2016 bm/simple cpv/simple cpv/heterogeneous"

capture noisily fesim presets akm
assert _rc == 0
assert `"`r(dgp)'"' == "akm"
assert `"`r(presets)'"' == "simple stylized germany_chk_2002_2009"

capture noisily fesim describe AKMSIMPLE
assert _rc == 0
assert `"`r(dgp)'"' == "akm"
assert `"`r(dgp_alias)'"' == "akmsimple"
assert `"`r(preset)'"' == "simple"
assert `"`r(calibration_class)'"' == "stylized"
assert `"`r(config_schema)'"' == "akm_simple_v3"
assert strpos(`"`r(config)'"', "dgp=akm preset=simple") == 1

capture noisily fesim describe akm, preset(SIMPLE)
assert _rc == 0
assert `"`r(dgp)'"' == "akm"
assert `"`r(preset)'"' == "simple"

capture noisily help fesim
assert _rc == 0

quietly adopath ++ `"`repository_root'/build"'
mata: mata clear
mata: mata mlib index
mata: assert(fesim_mata_api_version() == 35)
mata: assert(fesim_bm_schema_version() == 1)
mata: assert(fesim_config_schema_version() == 2)
mata: assert(fesim_moment_schema_version() == 1)
mata: assert(fesim_akm_simple_schema_version() == 4)
mata: assert(fesim_dispatch_status() == "akm_paygap_bm_and_cpv_public")

di as result "FESIM SOURCE SMOKE PASS"
