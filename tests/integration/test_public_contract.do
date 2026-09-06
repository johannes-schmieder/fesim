version 19.0
clear all
set more off
set varabbrev off
set seed 271828
local caller_rng "`c(rngstate)'"
local families "akm akm akm akmpaygap akmpaygap bm"
local presets "simple stylized germany_chk_2002_2009 simple cck2016 simple"
tempfile common_reference
forvalues route=1/6 {
    local family : word `route' of `families'
    local preset : word `route' of `presets'
    quietly fesim describe `family', preset(`preset')
    local observed "`r(observed_variables)'"
    local basic "`r(truth_basic_variables)'"
    local full "`r(truth_full_variables)'"
    assert rowsof(r(parameters)) > 0
    foreach frequency in year quarter month {
        local scale = cond("`frequency'"=="year",1,cond("`frequency'"=="quarter",4,12))
        local format = cond(`scale'==1,"%ty",cond(`scale'==4,"%tq","%tm"))
        foreach truth in none basic full {
            quietly fesim, dgp(`family') preset(`preset') workers(120) firms(12) ///
                periods(6) frequency(`frequency') truth(`truth') seed(260906) noreport clear
            assert "`c(rngstate)'" == "`caller_rng'"
            assert r(N)==720 & r(N_workers)==120 & r(N_firms)==12
            assert "`r(dgp)'"=="`family'" & "`r(preset)'"=="`preset'"
            matrix current_moments = r(moments)
            matrix current_network = r(network)
            matrix current_leaveout = r(leaveout)
            assert rowsof(current_network)==21 & colsof(current_network)==2
            assert rowsof(current_leaveout)==19 & colsof(current_leaveout)==1
            local columns : colnames current_network
            assert "`columns'"=="generated returned"
            if "`truth'"=="none" {
                matrix reference_moments = current_moments
                matrix reference_network = current_network
                matrix reference_leaveout = current_leaveout
            }
            else {
                mata: assert(mreldif(st_matrix("reference_moments"), st_matrix("current_moments"))==0)
                mata: assert(mreldif(st_matrix("reference_network"), st_matrix("current_network"))==0)
                mata: assert(mreldif(st_matrix("reference_leaveout"), st_matrix("current_leaveout"))==0)
            }
            local expected "`observed'"
            if "`truth'"!="none" local expected "`expected' `basic'"
            if "`truth'"=="full" local expected "`expected' `full'"
            quietly ds
            local actual "`r(varlist)'"
            local absent : list expected - actual
            local extra : list actual - expected
            assert "`absent'`extra'"==""
            foreach name of local actual {
                local label : variable label `name'
                assert "`label'"!=""
            }
            foreach name in workerid time firmid spellid ntransitions {
                local storage : type `name'
                assert "`storage'"=="long"
            }
            foreach name in employed newjob from_unemp to_unemp jobtojob {
                local storage : type `name'
                assert "`storage'"=="byte"
            }
            local storage : type lnwage
            assert "`storage'"=="double"
            local actual_format : format time
            assert "`actual_format'"=="`format'"
            isid workerid time, sort
            by workerid: assert _N==6 & time==time[1]+_n-1
            assert inlist(employed,0,1)
            foreach name in firmid lnwage spellid tenure {
                assert missing(`name') == !employed
            }
            assert inrange(firmid,1,12) & firmid==floor(firmid) if employed
            assert tenure>=0 & tenure<. if employed
            by workerid: assert missing(newjob) & missing(from_unemp) & ///
                missing(jobtojob) & missing(ntransitions) if _n==1
            by workerid: assert missing(to_unemp) if _n==_N
            by workerid: assert from_unemp==(!employed[_n-1] & employed) if _n>1
            by workerid: assert jobtojob==(employed[_n-1] & employed & firmid!=firmid[_n-1]) if _n>1
            by workerid: assert newjob==(employed & (!employed[_n-1] | ///
                firmid!=firmid[_n-1] | spellid!=spellid[_n-1])) if _n>1
            by workerid: assert to_unemp==(employed & !employed[_n+1]) if _n<_N
            foreach item in version dgp dgp_alias preset calibration_class command seed rng ///
                frequency internal_clock jobrule burnin connectivity reference rng_method stata_version truth {
                assert "`: char _dta[fesim_`item']'"!=""
            }
            if "`family'"=="bm" & "`truth'"=="full" {
                assert abs(employment_exposure_true+unemployment_exposure_true-1/`scale')<1e-10
                assert ntransitions_true==n_eu_true+n_ee_true+n_ue_true
                assert lnwage==ln(posted_wage_true) if employed
            }
            keep `observed'
            if "`truth'"=="none" quietly save `common_reference', replace
            else quietly cf _all using `common_reference'
        }
        * Reporting and rerunning cannot perturb economic data.
        quietly fesim, dgp(`family') preset(`preset') workers(120) firms(12) ///
            periods(6) frequency(`frequency') truth(none) seed(260906) report clear
        quietly cf _all using `common_reference'
    }
    * Check nondefault starts and filtering for every preset.
    foreach initial in random allunemployed {
        quietly fesim, dgp(`family') preset(`preset') workers(80) firms(8) ///
            periods(4) initial(`initial') burnin(2) seed(777) noreport clear
        isid workerid time
        bysort workerid (time): assert _N==4
    }
    quietly fesim, dgp(`family') preset(`preset') workers(80) firms(8) ///
        periods(4) connectivity(largest) seed(777) noreport clear
    assert "`: char _dta[fesim_connectivity]'"=="largest"
    isid workerid time
    bysort workerid (time): assert _N==4
    local override "mu 3.1"
    if "`family'"=="akmpaygap" local override "mu_m 3.1"
    if "`family'"=="bm" local override "lambda_e .7"
    quietly fesim, dgp(`family') preset(`preset') workers(80) firms(8) ///
        periods(4) parameters(`override') seed(777) noreport clear
    local expected_class = cond(inlist("`preset'","germany_chk_2002_2009","cck2016"),"targeted_modified","stylized_modified")
    assert "`r(calibration_class)'"=="`expected_class'"
    * An unseeded command consumes exactly one caller master-seed draw.
    local before_unseeded "`c(rngstate)'"
    mata: unused_master = runiformint(1,1,0,2147483647)
    local continuation "`c(rngstate)'"
    set rngstate `before_unseeded'
    quietly fesim, dgp(`family') preset(`preset') workers(80) firms(8) ///
        periods(4) noreport clear
    assert "`c(rngstate)'"=="`continuation'"
    set rngstate `before_unseeded'
}
assert "`c(rngstate)'"=="`caller_rng'"
display "FESIM PUBLIC CROSS-DGP CONTRACT PASS (54 truth/frequency cases)"
