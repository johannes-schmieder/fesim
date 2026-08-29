version 16.0
clear all
set more off
set varabbrev off

set rng mt64
set seed 16180339
local rng_before `"`c(rngstate)'"'

input long workerid long time long firmid byte employed double lnwage ///
    byte newjob byte from_unemp byte to_unemp byte jobtojob long ntransitions
1 1 1 1 1 . . 0 . .
1 2 1 1 2 0 0 0 0 0
1 3 2 1 3 1 0 . 1 1
2 1 2 1 2 . . 0 . .
2 2 2 1 2 0 0 0 0 0
2 3 2 1 2 0 0 . 0 0
3 1 . 0 . . . 0 . .
3 2 1 1 4 1 1 1 0 1
3 3 . 0 . 0 0 . 0 1
4 1 . 0 . . . 0 . .
4 2 . 0 . 0 0 0 0 0
4 3 . 0 . 0 0 . 0 0
end

mata:
assert(fesim_moment_schema_version() == 1)
assert(fesim_truth_moment_names() ==
    ("alpha_true_mean", "alpha_true_sd", "alpha_true_var", ///
    "psi_true_mean", "psi_true_sd", "psi_true_var", ///
    "epsilon_true_mean", "epsilon_true_sd", "epsilon_true_var", ///
    "cov_alpha_psi_true"))
truth_values = fesim_truth_moments((-1 \ 0 \ 1 \ 2), (-.5 \ .5), ///
    (-1 \ 0 \ 1), (0 \ 1 \ 2), (-1 \ 0 \ 1))
st_matrix("truth_moments", truth_values)
end
matrix rownames truth_moments = alpha_true_mean alpha_true_sd ///
    alpha_true_var psi_true_mean psi_true_sd psi_true_var ///
    epsilon_true_mean epsilon_true_sd epsilon_true_var cov_alpha_psi_true
matrix colnames truth_moments = realized

assert reldif(truth_moments[1, 1], .5) < 1e-12
assert reldif(truth_moments[2, 1], sqrt(5 / 3)) < 1e-12
assert reldif(truth_moments[3, 1], 5 / 3) < 1e-12
assert truth_moments[4, 1] == 0
assert reldif(truth_moments[5, 1], sqrt(.5)) < 1e-12
assert truth_moments[6, 1] == .5
assert truth_moments[7, 1] == 0
assert truth_moments[8, 1] == 1
assert truth_moments[9, 1] == 1
assert truth_moments[10, 1] == 1

matrix targets = (.5 \ 2 \ 0)
matrix rownames targets = employment_rate lnwage_mean p_ee_observed
matrix colnames targets = target

quietly datasignature set, reset
quietly _fesim_moments, firms(3) truthmoments(truth_moments) ///
    targets(targets)
scalar moment_N = r(N)
scalar moment_N_workers = r(N_workers)
scalar moment_N_firms = r(N_firms)
scalar moment_N_firms_active = r(N_firms_active)
scalar moment_periods = r(periods)
scalar moment_employment_rate = r(employment_rate)
scalar moment_p_eu = r(p_eu_realized)
scalar moment_p_ue = r(p_ue_realized)
scalar moment_p_ee = r(p_ee_realized)
scalar moment_N_movers = r(N_movers)
scalar moment_N_stayers = r(N_stayers)
scalar moment_N_never_employed = r(N_never_employed)
matrix moments = r(moments)
matrix target_table = r(targets)
quietly datasignature confirm
assert `"`c(rngstate)'"' == `"`rng_before'"'

assert moment_N == 12
assert moment_N_workers == 4
assert moment_N_firms == 3
assert moment_N_firms_active == 2
assert moment_periods == 3
assert reldif(moment_employment_rate, 7 / 12) < 1e-12
assert reldif(moment_p_eu, 1 / 5) < 1e-12
assert reldif(moment_p_ue, 1 / 3) < 1e-12
assert reldif(moment_p_ee, 1 / 5) < 1e-12
assert moment_N_movers == 1
assert moment_N_stayers == 2
assert moment_N_never_employed == 1

assert rowsof(moments) == 38
assert colsof(moments) == 1
assert moments["N", 1] == 12
assert reldif(moments["mean_ntransitions", 1], 3 / 8) < 1e-12
assert reldif(moments["lnwage_mean", 1], 16 / 7) < 1e-12
assert reldif(moments["lnwage_sd", 1], sqrt(19 / 21)) < 1e-12
assert moments["lnwage_p10", 1] == 1
assert moments["lnwage_p50", 1] == 2
assert moments["lnwage_p90", 1] == 4
assert moments["N_active_firm_periods", 1] == 5
assert reldif(moments["firm_size_mean", 1], 7 / 5) < 1e-12
assert reldif(moments["firm_size_sd", 1], sqrt(.3)) < 1e-12
assert moments["firm_size_p10", 1] == 1
assert moments["firm_size_p50", 1] == 1
assert moments["firm_size_p90", 1] == 2
assert moments["firm_size_p99", 1] == 2
assert reldif(moments["firm_hhi_mean", 1], 37 / 54) < 1e-12
assert moments["N_movers", 1] == 1
assert moments["N_stayers", 1] == 2
assert moments["N_never_employed", 1] == 1
assert reldif(moments["mover_share", 1], 1 / 3) < 1e-12
assert reldif(moments["stayer_share", 1], 2 / 3) < 1e-12
assert reldif(moments["alpha_true_var", 1], 5 / 3) < 1e-12
assert moments["cov_alpha_psi_true", 1] == 1

assert rowsof(target_table) == 3
assert colsof(target_table) == 4
assert target_table["employment_rate", "target"] == .5
assert reldif(target_table["employment_rate", "realized"], 7 / 12) < 1e-12
assert reldif(target_table["employment_rate", "difference"], 1 / 12) < 1e-12
assert reldif(target_table["employment_rate", "relative_difference"], 1 / 6) < 1e-12
assert reldif(target_table["lnwage_mean", "difference"], 2 / 7) < 1e-12
assert missing(target_table["p_ee_observed", "relative_difference"])

matrix bad_targets = (1)
matrix rownames bad_targets = undefined_moment
quietly datasignature set, reset
capture _fesim_moments, firms(3) targets(bad_targets)
assert _rc == 198
quietly datasignature confirm
assert `"`c(rngstate)'"' == `"`rng_before'"'

matrix bad_truth = J(10, 1, 0)
matrix rownames bad_truth = wrong1 wrong2 wrong3 wrong4 wrong5 ///
    wrong6 wrong7 wrong8 wrong9 wrong10
quietly datasignature set, reset
capture _fesim_moments, firms(3) truthmoments(bad_truth)
assert _rc == 198
quietly datasignature confirm
assert `"`c(rngstate)'"' == `"`rng_before'"'

capture mata: fesim_truth_moments((1), (1), J(0, 1, .), ///
    J(0, 1, .), J(0, 1, .))
assert _rc == 3300
assert `"`c(rngstate)'"' == `"`rng_before'"'

clear
input long workerid long time long firmid byte employed double lnwage ///
    byte newjob byte from_unemp byte to_unemp byte jobtojob long ntransitions
1 1 . 0 . . . 0 . .
1 2 . 0 . 0 0 . 0 0
2 1 . 0 . . . 0 . .
2 2 . 0 . 0 0 . 0 0
end
quietly datasignature set, reset
quietly _fesim_moments, firms(2)
scalar unemployed_p_eu = r(p_eu_realized)
scalar unemployed_p_ue = r(p_ue_realized)
scalar unemployed_p_ee = r(p_ee_realized)
matrix unemployed_moments = r(moments)
quietly datasignature confirm
assert missing(unemployed_p_eu)
assert unemployed_p_ue == 0
assert missing(unemployed_p_ee)
assert unemployed_moments["N_firms_active", 1] == 0
assert missing(unemployed_moments["lnwage_mean", 1])
assert unemployed_moments["N_active_firm_periods", 1] == 0
assert missing(unemployed_moments["firm_hhi_mean", 1])
assert unemployed_moments["N_never_employed", 1] == 2
assert missing(unemployed_moments["mover_share", 1])
assert missing(unemployed_moments["stayer_share", 1])
assert `"`c(rngstate)'"' == `"`rng_before'"'

di as result "FESIM COMMON MOMENT ENGINE TESTS PASS"
