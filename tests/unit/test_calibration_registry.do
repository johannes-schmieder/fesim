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
assert _N == 32
assert status == "stylized"
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

foreach preset in simple stylized {
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

di as result "FESIM CALIBRATION-REGISTRY CONSISTENCY TESTS PASS"
