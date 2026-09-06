version 19.0
preserve
fesim, dgp(blm) preset(dynamic) workers(1000) firms(120) ///
    periods(60) frequency(month) seed(20260923) truth(full) noreport clear
bysort workerid: egen double moves=total(n_ee_true)
quietly summarize workerid if moves>=2, meanonly
keep if workerid==r(min)
twoway (line lnwage time, lcolor(navy)) ///
    (line conditional_mean_true time, lcolor(maroon)) ///
    (scatter lnwage time if moved_month_true, msymbol(O) mcolor(teal)), ///
    legend(order(1 "Log earnings" 2 "Conditional mean" 3 "Firm move") ///
    cols(1) size(small)) xtitle("") ytitle("Log earnings") ///
    name(blm_wage_path, replace)
twoway (line move_probability_true time, lcolor(navy)), ///
    xtitle("Month") ytitle("Move probability") ///
    note("Probability uses previous month's earnings, before the fresh shock.") ///
    name(blm_move_path, replace)
graph combine blm_wage_path blm_move_path, cols(1) ///
    xsize(9) ysize(7) name(fesim_blm_dynamics, replace)
restore
