version 16.0
clear all
set more off
set varabbrev off

tempname master truth group_moments group_targets decomposition targets
quietly mata: st_numscalar("`master'", fesim_paygap_simulate_to_stata( ///
    100000, 1000, 8, 2002, "%ty", 1, 13579, 1, "random", 5, ///
    .46, 3, 2.815, .420, .400, .113, .099, .247, .12567, ///
    0, .171976891180182, .143, .125, 1, ///
    .08, .12, .60, .08, .12, .60, .142, 0, .18, .273, .05, .05))
mata: fesim_paygap_results_to_stata(8, 3, 2.815, "cck2016", ///
    "`truth'", "`group_moments'", "`group_targets'", ///
    "`decomposition'", "`targets'")
matrix rownames `group_moments' = N_workers N_employed employment_rate ///
    lnwage_mean lnwage_sd alpha_mean alpha_sd premium_mean premium_sd ///
    epsilon_mean epsilon_sd corr_alpha_premium surplus_mean surplus_sd ///
    p_eu_realized p_ue_realized p_ee_realized
matrix colnames `group_moments' = men women
matrix rownames `group_targets' = N_workers N_employed employment_rate ///
    lnwage_mean lnwage_sd alpha_mean alpha_sd premium_mean premium_sd ///
    epsilon_mean epsilon_sd corr_alpha_premium surplus_mean surplus_sd ///
    p_eu_realized p_ue_realized p_ee_realized
matrix colnames `group_targets' = men women
matrix rownames `decomposition' = total_gap intercept worker_composition ///
    firm_total sorting premium_schedule time residual adding_up_error
matrix colnames `decomposition' = male_reference female_reference symmetric
matrix rownames `targets' = total_gap intercept worker_composition ///
    firm_total sorting premium_schedule time residual adding_up_error
matrix colnames `targets' = male_reference female_reference symmetric

foreach group in men women {
    assert abs(`group_moments'["lnwage_sd", "`group'"] - ///
        `group_targets'["lnwage_sd", "`group'"]) < .025
    assert abs(`group_moments'["alpha_sd", "`group'"] - ///
        `group_targets'["alpha_sd", "`group'"]) < .01
    assert abs(`group_moments'["premium_mean", "`group'"] - ///
        `group_targets'["premium_mean", "`group'"]) < .04
    assert abs(`group_moments'["premium_sd", "`group'"] - ///
        `group_targets'["premium_sd", "`group'"]) < .025
    assert abs(`group_moments'["epsilon_sd", "`group'"] - ///
        `group_targets'["epsilon_sd", "`group'"]) < .01
    assert abs(`group_moments'["corr_alpha_premium", "`group'"] - ///
        `group_targets'["corr_alpha_premium", "`group'"]) < .03
}
assert abs(`decomposition'["total_gap", "male_reference"] - ///
    `targets'["total_gap", "male_reference"]) < .03
assert abs(`decomposition'["firm_total", "male_reference"] - ///
    `targets'["firm_total", "male_reference"]) < .02
assert abs(`decomposition'["sorting", "male_reference"] - ///
    `targets'["sorting", "male_reference"]) < .01
assert abs(`decomposition'["premium_schedule", "male_reference"] - ///
    `targets'["premium_schedule", "male_reference"]) < .02
forvalues column = 1/3 {
    assert abs(`decomposition'[9, `column']) < 1e-10
}

di as result "FESIM CCK-INSPIRED PAY-GAP MOMENT TESTS PASS"
