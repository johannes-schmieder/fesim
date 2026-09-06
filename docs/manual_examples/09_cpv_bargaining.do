version 19.0
preserve
tempfile comparisons
foreach beta in 0 .5 1 {
    fesim, dgp(cpv) workers(4000) firms(100) periods(5) ///
        seed(20260910) truth(full) parameters(beta `beta') noreport clear
    matrix list r(cpv_flows)
    keep if employed & time==2004
    generate double bargaining=`beta'
    keep bargaining firmid firm_productivity_true contract_wage_true
    if `beta'!=0 append using `comparisons'
    save `comparisons', replace
}
twoway (kdensity contract_wage_true if bargaining==0, lcolor(maroon)) ///
    (kdensity contract_wage_true if bargaining==.5, lcolor(navy)) ///
    (kdensity contract_wage_true if bargaining==1, lcolor(teal)), ///
    legend(order(1 "Beta = 0" 2 "Beta = 0.5" 3 "Beta = 1") cols(1)) ///
    title("A. Worker wage distributions") xtitle("Contract wage") ///
    ytitle("Kernel density") name(fesim_cpv_density, replace)
collapse (mean) contract_wage_true (first) firm_productivity_true, ///
    by(bargaining firmid)
twoway (line contract_wage_true firm_productivity_true if bargaining==0, ///
    sort lcolor(maroon)) (line contract_wage_true firm_productivity_true ///
    if bargaining==.5, sort lcolor(navy)) ///
    (line contract_wage_true firm_productivity_true if bargaining==1, ///
    sort lcolor(teal)), legend(order(1 "Beta = 0" 2 "Beta = 0.5" ///
    3 "Beta = 1") cols(1)) title("B. Mean wages at each firm") ///
    xtitle("Firm productivity") ytitle("Mean contract wage") ///
    name(fesim_cpv_mean, replace)
graph combine fesim_cpv_density fesim_cpv_mean, cols(2) ///
    xsize(10) ysize(4.5) name(fesim_cpv_bargaining, replace)
restore
