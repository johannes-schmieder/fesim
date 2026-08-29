version 16.0
clear all
set more off
set varabbrev off

local workers 30000
local firms 300
local periods 8
local sd_worker .4
local sd_firm .15
local sigma_multiplier 10

quietly fesim, dgp(akm) preset(simple) workers(`workers') ///
    firms(`firms') periods(`periods') seed(1618033) ///
    parameters(firm_size_sd 0) truth(basic) connectivity(keep) ///
    noreport clear
matrix exogeneity_moments = r(moments)
local ever_employed = exogeneity_moments["N_movers", "realized"] + ///
    exogeneity_moments["N_stayers", "realized"]
local sorting_bound = `sigma_multiplier' * `sd_worker' * `sd_firm' / ///
    sqrt(`ever_employed')
assert abs(exogeneity_moments["cov_alpha_psi_true", "realized"]) < ///
    `sorting_bound'

quietly correlate alpha_true psi_true if time == 2000 & employed, covariance
matrix initial_covariance = r(C)
local initial_employed = r(N)
local initial_sorting_bound = `sigma_multiplier' * `sd_worker' * ///
    `sd_firm' / sqrt(`initial_employed')
assert abs(initial_covariance[1, 2]) < `initial_sorting_bound'

foreach mobility_variable in from_unemp jobtojob newjob to_unemp ///
    ntransitions tenure {
    quietly correlate epsilon_true `mobility_variable' ///
        if employed & !missing(`mobility_variable')
    matrix shock_mobility_correlation = r(C)
    local correlation_N = r(N)
    local correlation_bound = `sigma_multiplier' / sqrt(`correlation_N')
    assert abs(shock_mobility_correlation[1, 2]) < `correlation_bound'
}

di as result "FESIM SIMPLE-AKM EXOGENEITY TESTS PASS"
