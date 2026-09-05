version 19.0
preserve
fesim, dgp(akmpaygap) preset(cck2016) workers(5000) firms(200) ///
    periods(8) seed(20260904) truth(full) noreport clear
matrix list r(decomposition)
twoway (kdensity lnwage if employed & group==0, lcolor(navy)) ///
    (kdensity lnwage if employed & group==1, lcolor(maroon)), ///
    legend(order(1 "Men" 2 "Women")) ///
    xtitle("Log wage") ytitle("Density") ///
    title("A. Employed wage distributions") name(fesim_gap_wage, replace)
keep if employed
bysort firmid: keep if _n==1
twoway (scatter psi_male_true firm_surplus_true, ///
    mcolor(navy%65) msymbol(Oh)) ///
    (scatter psi_female_true firm_surplus_true, ///
    mcolor(maroon%55) msymbol(Th)), ///
    legend(order(1 "Male schedule" 2 "Female schedule")) ///
    xtitle("Firm surplus index") ytitle("Firm premium (log points)") ///
    title("B. Both schedules at each active firm") ///
    name(fesim_gap_schedule, replace)
graph combine fesim_gap_wage fesim_gap_schedule, ///
    cols(2) xsize(10) ysize(4) name(fesim_paygap, replace)
restore
