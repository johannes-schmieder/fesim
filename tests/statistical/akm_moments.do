version 16.0
clear all
set more off
set varabbrev off

local workers 40000
local firms 400
local periods 10
local sd_worker .4
local sd_firm .15
local sd_error .2
local p_eu .08
local p_ee .12
local p_ue .6
local sigma_multiplier 8

quietly fesim, dgp(akm) preset(simple) workers(`workers') ///
    firms(`firms') periods(`periods') seed(271828) ///
    parameters(firm_size_sd 0) truth(basic) connectivity(keep) ///
    noreport clear
matrix statistical_moments = r(moments)
matrix statistical_network = r(network)
assert r(N_firms_active) == `firms'

local alpha_mean_bound = `sigma_multiplier' * `sd_worker' / sqrt(`workers')
local alpha_var_bound = `sigma_multiplier' * (`sd_worker' ^ 2) * ///
    sqrt(2 / (`workers' - 1))
assert abs(statistical_moments["alpha_true_mean", "realized"]) < ///
    `alpha_mean_bound'
assert abs(statistical_moments["alpha_true_var", "realized"] - ///
    `sd_worker' ^ 2) < `alpha_var_bound'

local psi_mean_bound = `sigma_multiplier' * `sd_firm' / sqrt(`firms')
local psi_var_bound = `sigma_multiplier' * (`sd_firm' ^ 2) * ///
    sqrt(2 / (`firms' - 1))
assert abs(statistical_moments["psi_true_mean", "realized"]) < ///
    `psi_mean_bound'
assert abs(statistical_moments["psi_true_var", "realized"] - ///
    `sd_firm' ^ 2) < `psi_var_bound'

local employed_observations = ///
    statistical_network["employed_observations", "generated"]
local epsilon_mean_bound = `sigma_multiplier' * `sd_error' / ///
    sqrt(`employed_observations')
local epsilon_var_bound = `sigma_multiplier' * (`sd_error' ^ 2) * ///
    sqrt(2 / (`employed_observations' - 1))
assert abs(statistical_moments["epsilon_true_mean", "realized"]) < ///
    `epsilon_mean_bound'
assert abs(statistical_moments["epsilon_true_var", "realized"] - ///
    `sd_error' ^ 2) < `epsilon_var_bound'

sort workerid time
tempvar origin_employed worker_first
by workerid: generate byte `origin_employed' = employed[_n - 1] if _n > 1
quietly count if employed & !missing(to_unemp)
local eu_risk = r(N)
quietly count if `origin_employed' == 0
local ue_risk = r(N)
quietly count if `origin_employed' == 1
local ee_risk = r(N)
local eu_bound = `sigma_multiplier' * sqrt(`p_eu' * (1 - `p_eu') / ///
    `eu_risk')
local ue_bound = `sigma_multiplier' * sqrt(`p_ue' * (1 - `p_ue') / ///
    `ue_risk')
local ee_bound = `sigma_multiplier' * sqrt(`p_ee' * (1 - `p_ee') / ///
    `ee_risk')
assert abs(statistical_moments["p_eu_observed", "realized"] - ///
    `p_eu') < `eu_bound'
assert abs(statistical_moments["p_ue_observed", "realized"] - ///
    `p_ue') < `ue_bound'
assert abs(statistical_moments["p_ee_observed", "realized"] - ///
    `p_ee') < `ee_bound'

local stationary_employment = `p_ue' / (`p_eu' + `p_ue')
quietly summarize employed if time == 2000, meanonly
local employment_first = r(mean)
local employment_bound = `sigma_multiplier' * ///
    sqrt(`stationary_employment' * (1 - `stationary_employment') / ///
    `workers')
assert abs(`employment_first' - `stationary_employment') < ///
    `employment_bound'

preserve
quietly keep if time == 2000 & employed
quietly count
local initial_employed = r(N)
quietly contract firmid
assert _N == `firms'
local expected_firm_size = `initial_employed' / `firms'
generate double chi_square_piece = ///
    (_freq - `expected_firm_size') ^ 2 / `expected_firm_size'
quietly summarize chi_square_piece, meanonly
local assignment_chi_square = r(sum)
local assignment_bound = (`firms' - 1) + ///
    `sigma_multiplier' * sqrt(2 * (`firms' - 1))
assert `assignment_chi_square' < `assignment_bound'
restore

preserve
quietly by workerid: keep if _n == 1
quietly summarize alpha_true if workerid <= 2500, meanonly
local alpha_small_error = abs(r(mean))
local alpha_large_error = ///
    abs(statistical_moments["alpha_true_mean", "realized"])
assert `alpha_large_error' < `alpha_small_error'
restore

quietly summarize epsilon_true if employed & workerid <= 2500, meanonly
local epsilon_small_error = abs(r(mean))
local epsilon_large_error = ///
    abs(statistical_moments["epsilon_true_mean", "realized"])
assert `epsilon_large_error' < `epsilon_small_error'

quietly summarize employed if time == 2000 & workerid <= 2500, meanonly
local employment_small_error = abs(r(mean) - `stationary_employment')
local employment_large_error = ///
    abs(`employment_first' - `stationary_employment')
assert `employment_large_error' < `employment_small_error'

di as result "FESIM SIMPLE-AKM STATISTICAL MOMENT TESTS PASS"
