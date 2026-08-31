version 16.0
clear all
set more off
set varabbrev off

args repository_root
if `"`repository_root'"' == "" {
    di as error "test_calibration_registry.do requires the repository root"
    exit 198
}

quietly import delimited using ///
    `"`repository_root'/calibrations/presets.csv"', clear varnames(1) stringcols(_all)

generate double value_numeric = real(value)
assert !missing(value_numeric)
isid dgp preset parameter
assert _N == 55
assert status == "stylized" if inlist(preset, "simple", "stylized")
assert status == "targeted" if preset == "germany_chk_2002_2009"
assert source_key == "fesim_d015" if preset == "simple"
assert source_key == "fesim_d026" if preset == "stylized"

forvalues row = 1/`=_N' {
    local row_dgp `"`=dgp[`row']'"'
    local row_preset `"`=preset[`row']'"'
    local row_parameter `"`=parameter[`row']'"'
    capture quietly fesim_registry, action(parameter) dgp(`row_dgp') ///
        preset(`row_preset') parameter(`row_parameter')
    local lookup_rc = _rc
    if `lookup_rc' {
        di as error "registry lookup failed for `row_dgp'/`row_preset' `row_parameter'"
        exit `lookup_rc'
    }
    local registered_default = r(default_value)
    if reldif(value_numeric[`row'], `registered_default') >= 1e-12 {
        di as error "calibration default mismatch for `row_dgp'/`row_preset' `row_parameter'"
        exit 459
    }
}

foreach preset in simple stylized germany_chk_2002_2009 {
    quietly fesim_registry, action(parameters) dgp(akm) preset(`preset')
    local model_parameters `"`r(model_parameters)'"'
    local expected : word count `model_parameters'
    quietly count if dgp == "akm" & preset == "`preset'"
    assert r(N) == `expected'
    foreach parameter of local model_parameters {
        quietly count if dgp == "akm" & preset == "`preset'" & ///
            parameter == "`parameter'"
        assert r(N) == 1
    }
}

quietly import delimited using ///
    `"`repository_root'/calibrations/targets.csv"', clear varnames(1) ///
    stringcols(_all)
assert _N == 5
isid dgp preset moment
assert dgp == "akm"
assert preset == "germany_chk_2002_2009"
assert real(value) == .357 if moment == "alpha_true_sd"
assert real(value) == .230 if moment == "psi_true_sd"
assert real(value) == .135 if moment == "epsilon_true_sd"
assert real(value) == .0205 if moment == "cov_alpha_psi_true"
assert real(value) == .249 if moment == "corr_alpha_psi_source"
assert role == "runtime_target" if moment != "corr_alpha_psi_source"
assert role == "source_crosscheck" if moment == "corr_alpha_psi_source"

quietly import delimited using ///
    `"`repository_root'/calibrations/germany_chk_2002_2009_results.csv"', ///
    clear varnames(1) stringcols(_all)
assert _N == 30
isid stage seed theta_sort
generate double theta_numeric = real(theta_sort)
generate double covariance_numeric = real(cov_alpha_psi_true)
quietly summarize covariance_numeric if stage == "calibration" & ///
    abs(theta_numeric - 2.2) < 1e-12, meanonly
assert r(N) == 5
assert reldif(r(mean), .0206703882) < 1e-10
quietly summarize covariance_numeric if stage == "validation" & ///
    abs(theta_numeric - 2.2) < 1e-12, meanonly
assert r(N) == 5
assert reldif(r(mean), .0200683908) < 1e-10
assert abs(r(mean) - .0205) <= .0015

di as result "FESIM CALIBRATION-REGISTRY CONSISTENCY TESTS PASS"
