version 16.0
clear all
set more off
set varabbrev off

args repository_root
if `"`repository_root'"' == "" local repository_root `"`c(pwd)'"'
adopath ++ `"`repository_root'"'

local target .0205
local tolerance .0015
local common dgp(akm) preset(germany_chk_2002_2009) ///
    workers(100000) firms(10000) periods(8) frequency(year) start(2002) ///
    burnin(5) network(random) connectivity(keep) truth(none) noreport clear

tempfile results
tempname post
postfile `post' byte stage long seed double covariance correlation ///
    using `results', replace

foreach stage in calibration validation {
    if `"`stage'"' == "calibration" ///
        local seeds 31032009 12345 24680 97531 86420
    else local seeds 11111 22222 33333 44444 55555
    local stage_code = cond(`"`stage'"' == "calibration", 1, 2)
    foreach seed of local seeds {
        quietly fesim, `common' seed(`seed')
        matrix moments = r(moments)
        matrix parameters = r(parameters)
        assert reldif(parameters["theta_sort", "value"], 2.2) < 1e-12
        scalar covariance = moments["cov_alpha_psi_true", "realized"]
        scalar correlation = covariance / ///
            (moments["alpha_true_sd", "realized"] * ///
            moments["psi_true_sd", "realized"])
        post `post' (`stage_code') (`seed') (covariance) (correlation)
        noisily display as text "CHK fit stage=`stage' seed=`seed' cov=" ///
            %12.9f covariance " corr=" %12.9f correlation
    }
}
postclose `post'
use `results', clear
label define stage_label 1 "calibration" 2 "validation"
label values stage stage_label

foreach stage_code in 1 2 {
    if `stage_code' == 1 local stage_name "calibration"
    else local stage_name "validation"
    quietly summarize covariance if stage == `stage_code', meanonly
    assert r(N) == 5
    assert abs(r(mean) - `target') <= `tolerance'
    noisily display as result "CHK `stage_name'" ///
        " mean covariance=" %12.9f r(mean) ///
        " target=" %9.6f `target'
}

display as result "FESIM GERMANY CHK CALIBRATION VALIDATION PASS"
exit 0
