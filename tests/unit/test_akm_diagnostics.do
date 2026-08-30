version 16.0
clear all
set more off
set varabbrev off

mata:
assert(fesim_akm_handler_schema_version() == 3)
diagnostic_targets = fesim_akm_truth_targets(.4, .15, .2)
assert(mreldif(diagnostic_targets, ///
    (0 \ .4 \ .16 \ 0 \ .15 \ .0225 \ 0 \ .2 \ .04 \ 0)) < 1e-15)
assert(fesim_akm_variance_from_sums(4, 2, 6) == 5 / 3)
assert(missing(fesim_akm_variance_from_sums(1, 2, 4)))
assert(missing(fesim_akm_variance_from_sums(0, 0, 0)))
end

capture mata: fesim_akm_truth_targets(-1, .15, .2)
assert _rc == 3300
capture mata: fesim_akm_variance_from_sums(3, 0, -1)
assert _rc == 3300

di as result "FESIM SIMPLE-AKM DIAGNOSTIC HELPERS PASS"
