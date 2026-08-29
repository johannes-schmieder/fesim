version 16.0
clear all
set more off
set varabbrev off

local expected_signature_year "24:19(62576):2121982595:1533466739"
local expected_signature_quarter "24:19(62576):1654952075:1094691667"
local expected_signature_month "24:19(62576):135783415:3123156782"
local expected_components_year 1
local expected_components_quarter 2
local expected_components_month 1
local expected_employment_year .91666666666666663
local expected_employment_quarter .875
local expected_employment_month 1
local expected_wage_year 3.0711870605845788
local expected_wage_quarter 3.0616467484169001
local expected_wage_month 3.077541244164296
local expected_network_share_year 1
local expected_network_share_quarter .80952380952380953
local expected_network_share_month 1

foreach frequency in year quarter month {
    local start = cond("`frequency'" == "year", "2000", ///
        cond("`frequency'" == "quarter", "2000q1", "2000m1"))
    local expected_format = cond("`frequency'" == "year", "%ty", ///
        cond("`frequency'" == "quarter", "%tq", "%tm"))
    local options workers(6) firms(3) periods(4) ///
        frequency(`frequency') start(`start') seed(314159) ///
        initial(stationary) truth(basic) connectivity(keep) ///
        noreport clear

    quietly fesim, dgp(akm) preset(simple) `options'
    local first_components = r(components)
    matrix first_moments = r(moments)
    matrix first_targets = r(targets)
    matrix first_network = r(network)
    quietly datasignature
    local first_signature `"`r(datasignature)'"'
    assert `"`first_signature'"' == `"`expected_signature_`frequency''"'
    assert `first_components' == `expected_components_`frequency''
    assert first_moments["employment_rate", "realized"] == ///
        `expected_employment_`frequency''
    assert first_moments["lnwage_mean", "realized"] == ///
        `expected_wage_`frequency''
    assert first_network["largest_observation_share", "generated"] == ///
        `expected_network_share_`frequency''
    local time_format : format time
    assert `"`time_format'"' == `"`expected_format'"'
    tempfile reference
    quietly save `reference'

    quietly fesim, dgp(akm) preset(simple) `options'
    matrix repeated_moments = r(moments)
    matrix repeated_targets = r(targets)
    matrix repeated_network = r(network)
    quietly datasignature
    assert `"`r(datasignature)'"' == `"`first_signature'"'
    quietly cf _all using `reference'
    mata: assert(st_matrix("first_moments") == ///
        st_matrix("repeated_moments"))
    mata: assert(st_matrix("first_targets") == ///
        st_matrix("repeated_targets"))
    mata: assert(st_matrix("first_network") == ///
        st_matrix("repeated_network"))

    clear all
    discard
    set more off
    set varabbrev off
    quietly fesim, dgp(akm) preset(simple) `options'
    quietly datasignature
    assert `"`r(datasignature)'"' == `"`first_signature'"'
    quietly cf _all using `reference'

    quietly fesim, dgp(akmsimple) `options'
    quietly datasignature
    assert `"`r(datasignature)'"' == `"`first_signature'"'
    quietly cf _all using `reference'
}

di as result "FESIM FROZEN TINY AKM REGRESSION TESTS PASS"
