version 16.0
clear all
set more off
set varabbrev off

args repository_root
if `"`repository_root'"' == "" {
    di as error "install_smoke.do requires the repository root"
    exit 198
}

local oldpwd `"`c(pwd)'"'
capture mkdir `"`repository_root'/build/install-smoke-cwd"'
quietly cd `"`repository_root'/build/install-smoke-cwd"'

capture ado uninstall fesim
quietly net install fesim, from(`"`repository_root'"') replace
discard

capture noisily findfile fesim.ado
assert _rc == 0
assert strpos(`"`r(fn)'"', "build/stata-plus") > 0

capture noisily findfile _fesim_finalize.ado
assert _rc == 0
assert strpos(`"`r(fn)'"', "build/stata-plus") > 0

capture noisily findfile _fesim_durations.ado
assert _rc == 0
assert strpos(`"`r(fn)'"', "build/stata-plus") > 0

capture noisily findfile _fesim_moments.ado
assert _rc == 0
assert strpos(`"`r(fn)'"', "build/stata-plus") > 0

capture noisily findfile _fesim_network.ado
assert _rc == 0
assert strpos(`"`r(fn)'"', "build/stata-plus") > 0

capture noisily findfile _fesim_truth.ado
assert _rc == 0
assert strpos(`"`r(fn)'"', "build/stata-plus") > 0

capture noisily findfile _fesim_load.ado
assert _rc == 0
assert strpos(`"`r(fn)'"', "build/stata-plus") > 0

capture noisily findfile fesim_license.sthlp
assert _rc == 0
assert strpos(`"`r(fn)'"', "build/stata-plus") > 0

capture noisily findfile fesim_run.ado
assert _rc == 0
assert strpos(`"`r(fn)'"', "build/stata-plus") > 0

capture noisily fesim version
assert _rc == 0
assert `"`r(version)'"' == "0.3.0-dev"

capture noisily fesim list
assert _rc == 0
assert r(n_dgps) == 3

capture noisily fesim presets akm
assert _rc == 0
assert `"`r(presets)'"' == "simple stylized germany_chk_2002_2009"

capture noisily fesim describe akmsimple
assert _rc == 0
assert `"`r(dgp)'"' == "akm"
assert `"`r(preset)'"' == "simple"
assert `"`r(config_schema)'"' == "akm_simple_v3"
assert strpos(`"`r(config)'"', "workers=10000") > 0

quietly adopath - `"`repository_root'/build"'
mata: mata clear
mata: mata mlib index
capture noisily fesim, dgp(akmsimple) workers(12) firms(3) periods(2) ///
    seed(12345) truth(none) noreport clear
assert _rc == 0
assert _N == 24
isid workerid time

capture noisily fesim, dgp(akm) preset(germany_chk_2002_2009) ///
    workers(12) firms(3) periods(2) seed(11111) truth(none) noreport clear
assert _rc == 0
assert _N == 24
matrix installed_germany_targets = r(targets)
assert rowsof(installed_germany_targets) == 10
assert installed_germany_targets["cov_alpha_psi_true", "target"] == .0205
isid workerid time

capture noisily fesim, dgp(akmempirical) workers(12) firms(3) periods(2) ///
    seed(54321) truth(none) noreport clear
assert _rc == 0
assert _N == 24
confirm variable unemp_duration
matrix installed_durations = r(durations)
assert rowsof(installed_durations) == 12
isid workerid time
capture noisily fesim, dgp(akmpaygap) preset(simple) workers(40) ///
    firms(8) periods(3) burnin(1) seed(24680) truth(none) noreport clear
assert _rc == 0
assert _N == 120
confirm variable group
matrix installed_paygap = r(decomposition)
assert rowsof(installed_paygap) == 9
assert abs(installed_paygap["adding_up_error", "symmetric"]) < 1e-10
mata: assert(fesim_mata_api_version() == 29)
mata: assert(fesim_bm_schema_version() == 1)
mata: assert(fesim_bm_history_schema_version() == 1)
mata: mata clear
quietly adopath ++ `"`repository_root'/build"'
mata: mata mlib index

quietly cd `"`oldpwd'"'
di as result "FESIM CLEAN INSTALL SMOKE PASS"
