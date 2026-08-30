version 16.0
clear all
set more off
set varabbrev off

* Sorting comparison: identical primitives and hazards, only theta_sort changes.
local sorting_common workers(5000) firms(100) periods(6) frequency(year) ///
    seed(86420) truth(full) noreport clear ///
    parameters(rho_z_alpha .8 rho_q_psi .8 eu_worker 0 eu_firm 0 ///
    eu_duration 0 ee_worker 0 ee_firm 0 ee_duration 0 ue_worker 0 ///
    ue_duration 0 theta_quality 0 theta_up 0 theta_down 0

quietly fesim, dgp(akmempirical) `sorting_common' theta_sort 0)
matrix unsorted_moments = r(moments)
scalar unsorted_covariance = ///
    unsorted_moments["cov_alpha_psi_true", "realized"]

quietly fesim, dgp(akmempirical) `sorting_common' theta_sort 1)
matrix sorted_moments = r(moments)
scalar sorted_covariance = ///
    sorted_moments["cov_alpha_psi_true", "realized"]

assert abs(unsorted_covariance) < .01
assert sorted_covariance - unsorted_covariance > .02

* The finite types attenuate the latent worker correlation; both realized
* correlations must nevertheless be strong and have the registered sign.
egen byte worker_tag = tag(workerid)
quietly correlate alpha_true worker_type_true if worker_tag
matrix worker_correlation = r(C)
assert inrange(worker_correlation[1, 2], .65, .85)

egen byte firm_tag = tag(firmid) if employed
quietly correlate psi_true firm_quality_true if firm_tag
matrix firm_correlation = r(C)
assert inrange(firm_correlation[1, 2], .65, .95)

* Negative duration slopes lower exit/finding hazards as spells age. Holding
* every other heterogeneity and destination term at zero must lengthen both
* retained employment and unemployment durations in this fixed-seed design.
local duration_common workers(5000) firms(100) periods(8) frequency(year) ///
    seed(97531) truth(none) noreport clear ///
    parameters(rho_z_alpha 0 rho_q_psi 0 eu_worker 0 eu_firm 0 ///
    ee_worker 0 ee_firm 0 ue_worker 0 theta_sort 0 theta_quality 0 ///
    theta_up 0 theta_down 0

quietly fesim, dgp(akmempirical) `duration_common' ///
    eu_duration 0 ee_duration 0 ue_duration 0)
matrix flat_durations = r(durations)

quietly fesim, dgp(akmempirical) `duration_common' ///
    eu_duration -.4 ee_duration -.4 ue_duration -.5)
matrix dependent_durations = r(durations)

assert dependent_durations["tenure_years_mean", "realized"] > ///
    1.25 * flat_durations["tenure_years_mean", "realized"]
assert dependent_durations["unemployment_duration_years_mean", ///
    "realized"] > 1.5 * ///
    flat_durations["unemployment_duration_years_mean", "realized"]

di as result "FESIM STYLIZED-AKM MOBILITY STATISTICAL TESTS PASS"
