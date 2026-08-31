version 16.0
clear all
set more off
set varabbrev off

set obs 8
generate long workerid = ceil(_n / 2)
generate int time = mod(_n - 1, 2) + 2002
generate byte group = workerid > 2
generate byte employed = 1
generate double alpha_true = cond(inlist(workerid, 1, 3), .2, -.2)
generate double firm_surplus_true = cond(group, -1, 1)
generate double psi_male_true = 1 + .5 * firm_surplus_true
generate double psi_female_true = .7 + .2 * firm_surplus_true
generate double psi_true = cond(group, psi_female_true, psi_male_true)
generate double time_true = 0
generate double epsilon_true = 0
generate double lnwage = 3 - .5 * group + alpha_true + psi_true
generate byte from_unemp = .
generate byte to_unemp = .
generate byte jobtojob = .

tempname truth group_moments group_targets decomposition targets
mata: fesim_paygap_results_to_stata(2, 3, 2.5, "simple", ///
    "`truth'", "`group_moments'", "`group_targets'", ///
    "`decomposition'", "`targets'")
matrix rownames `decomposition' = total_gap intercept worker_composition ///
    firm_total sorting premium_schedule time residual adding_up_error
matrix colnames `decomposition' = male_reference female_reference symmetric
matrix baseline = `decomposition'

assert abs(baseline["total_gap", "male_reference"] - 1.5) < 1e-12
assert abs(baseline["intercept", "male_reference"] - .5) < 1e-12
assert abs(baseline["worker_composition", "male_reference"]) < 1e-12
assert abs(baseline["firm_total", "male_reference"] - 1) < 1e-12
assert abs(baseline["sorting", "male_reference"] - 1) < 1e-12
assert abs(baseline["premium_schedule", "male_reference"]) < 1e-12
assert abs(baseline["sorting", "female_reference"] - .4) < 1e-12
assert abs(baseline["premium_schedule", "female_reference"] - .6) < 1e-12
assert abs(baseline["sorting", "symmetric"] - .7) < 1e-12
assert abs(baseline["premium_schedule", "symmetric"] - .3) < 1e-12
forvalues column = 1/3 {
    assert abs(baseline[9, `column']) < 1e-12
}

replace psi_male_true = 1
replace psi_female_true = .7
replace psi_true = cond(group, psi_female_true, psi_male_true)
replace lnwage = 3 - .5 * group + alpha_true + psi_true
mata: fesim_paygap_results_to_stata(2, 3, 2.5, "simple", ///
    "`truth'", "`group_moments'", "`group_targets'", ///
    "`decomposition'", "`targets'")
assert abs(`decomposition'[5, 1]) < 1e-12
assert abs(`decomposition'[5, 2]) < 1e-12
assert abs(`decomposition'[6, 1] - .3) < 1e-12
assert abs(`decomposition'[6, 2] - .3) < 1e-12

replace psi_male_true = 1 + .5 * firm_surplus_true
replace psi_female_true = psi_male_true
replace psi_true = psi_male_true
replace lnwage = 3 - .5 * group + alpha_true + psi_true
mata: fesim_paygap_results_to_stata(2, 3, 2.5, "simple", ///
    "`truth'", "`group_moments'", "`group_targets'", ///
    "`decomposition'", "`targets'")
assert abs(`decomposition'[6, 1]) < 1e-12
assert abs(`decomposition'[6, 2]) < 1e-12
assert abs(`decomposition'[5, 1] - 1) < 1e-12
assert abs(`decomposition'[5, 2] - 1) < 1e-12

replace firm_surplus_true = 0
replace psi_male_true = .8
replace psi_female_true = .8
replace psi_true = .8
replace lnwage = 3 + alpha_true + psi_true
mata: fesim_paygap_results_to_stata(2, 3, 3, "simple", ///
    "`truth'", "`group_moments'", "`group_targets'", ///
    "`decomposition'", "`targets'")
assert abs(`decomposition'[1, 1]) < 1e-12
assert abs(`decomposition'[2, 1]) < 1e-12
assert abs(`decomposition'[3, 1]) < 1e-12
assert abs(`decomposition'[4, 1]) < 1e-12
assert abs(`decomposition'[9, 1]) < 1e-12

replace firm_surplus_true = cond(group, -1, 1)
replace psi_male_true = 3 + .5 * firm_surplus_true
replace psi_female_true = 2.7 + .2 * firm_surplus_true
replace psi_true = cond(group, psi_female_true, psi_male_true)
replace lnwage = 1 - .5 * group + alpha_true + psi_true
mata: fesim_paygap_results_to_stata(2, 1, .5, "simple", ///
    "`truth'", "`group_moments'", "`group_targets'", ///
    "`decomposition'", "`targets'")
matrix shifted = `decomposition'
assert mreldif(baseline, shifted) < 1e-12

di as result "FESIM PAY-GAP DECOMPOSITION TESTS PASS"
