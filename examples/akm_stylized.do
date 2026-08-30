version 19.0
clear all
set more off
set varabbrev off

* Generate an annual panel from a monthly empirical-mobility engine.
fesim, dgp(akmempirical) workers(1000) firms(80) periods(6) ///
    seed(24680) truth(full) connectivity(keep) clear

matrix simulation_parameters = r(parameters)
matrix simulation_moments = r(moments)
matrix simulation_durations = r(durations)
matrix simulation_network = r(network)

describe workerid time firmid employed lnwage tenure unemp_duration ///
    worker_type_true firm_quality_true
summarize employed lnwage tenure unemp_duration
matrix list simulation_durations

* Modify model coefficients only through parameters().
fesim, dgp(akm) preset(stylized) workers(1000) firms(80) periods(6) ///
    seed(24680) truth(none) ///
    parameters(theta_sort .50 eu_duration -.30 ue_duration -.35) ///
    noreport clear
assert `"`r(calibration_class)'"' == "stylized_modified"

di as result "fesim akm/stylized example completed"
