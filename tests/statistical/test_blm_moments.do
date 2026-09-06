version 19.0
clear all
set more off
set seed 91256
local caller "`c(rngstate)'"
* First retained month gives independent workers; eight-sigma bounds are
* conservative over these fixed, registered moment checks.
matrix SD=(.1,.2,.3\.2,.4,.1\.3,.1,.2)
foreach preset in static dynamic {
    quietly fesim, dgp(blm) preset(`preset') workers(60000) firms(30) periods(1) ///
        frequency(month) burnin(0) seed(95272) truth(full) parameters(worker_types 3 firm_types 3 sd_matrix SD) clear noreport
    matrix MU=r(blm_mean)
    matrix CELLS=r(blm_cells)
    forvalues l=1/3 {
        forvalues k=1/3 {
            quietly count if worker_type_true==`l' & firm_type_true==`k'
            local n=r(N)
            assert `n'>3000
            local row=(`l'-1)*3+`k'
            if "`preset'"=="static" {
                assert abs(CELLS[`row',2]-MU[`l',`k'])<8*SD[`l',`k']/sqrt(`n')
                assert abs(CELLS[`row',3]-SD[`l',`k'])<8*SD[`l',`k']/sqrt(2*(`n'-1))
            }
        }
    }
    generate double z=epsilon_true/innovation_sd_true
    quietly summarize z
    assert abs(r(mean))<8/sqrt(r(N))
    assert abs(r(sd)-1)<8/sqrt(2*(r(N)-1))
    generate double error_move=moved_month_true-move_probability_true
    generate double var_move=move_probability_true*(1-move_probability_true)
    quietly summarize var_move, meanonly
    local variance=r(sum)
    quietly summarize error_move, meanonly
    assert abs(r(sum))<8*sqrt(`variance')
    * Fresh innovations are independent of previous earnings and selected moves.
    quietly correlate z lag_lnwage_true
    assert abs(r(rho))<8/sqrt(_N)
    quietly correlate z moved_month_true
    assert abs(r(rho))<8/sqrt(_N)
    * Static earnings shocks cannot predict this month's event conditional on types.
    if "`preset'"=="static" {
        generate double olderror=lag_lnwage_true-3
        quietly regress error_move olderror i.worker_type_true#i.lag_firm_type_true
        assert abs(_b[olderror]/_se[olderror])<8
    }
    else {
        generate double deviation=lag_lnwage_true-3
        quietly regress moved_month_true deviation i.worker_type_true#i.lag_firm_type_true
        assert _b[deviation]<0
    }
}
* Positive and negative sorting recipes reverse type/class association.
foreach sorting in -1 1 {
    quietly fesim, dgp(blm) workers(20000) firms(60) periods(1) burnin(20) ///
        seed(63721) truth(basic) parameters(worker_types 3 firm_types 3 sorting `sorting') clear noreport
    quietly correlate worker_type_true firm_type_true
    assert `sorting'*r(rho)>.3
}
assert "`c(rngstate)'"=="`caller'"
display "FESIM BLM STATISTICAL MOMENTS PASS"
