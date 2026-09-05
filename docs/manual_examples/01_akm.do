version 19.0
preserve
fesim, dgp(akmsimple) workers(3000) firms(100) periods(8) ///
    seed(20260901) truth(basic) noreport clear
matrix list r(moments)
isid workerid time
histogram lnwage if employed, density color(navy%65) ///
    xtitle("Log wage") title("A. Employed wage distribution") ///
    name(fesim_akm_wages, replace)
keep if employed
collapse (mean) alpha_true psi_true (count) size=workerid, by(firmid)
twoway scatter alpha_true psi_true [aw=size], ///
    mcolor(navy%60) msymbol(Oh) ///
    xtitle("Firm wage effect") ytitle("Mean worker effect at firm") ///
    title("B. Realized worker sorting") name(fesim_akm_sort, replace)
graph combine fesim_akm_wages fesim_akm_sort, ///
    cols(2) xsize(10) ysize(4) name(fesim_akm, replace)
restore
