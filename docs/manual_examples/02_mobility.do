version 19.0
preserve
fesim, dgp(akmempirical) workers(3000) firms(100) periods(8) ///
    seed(20260902) truth(full) noreport clear
matrix list r(durations)
histogram ntransitions if !missing(ntransitions), discrete percent ///
    color(navy%65) xtitle("Latent monthly transitions per annual interval") ///
    title("A. Stylized mobility") name(fesim_emp_moves, replace)
fesim, dgp(akm) preset(germany_chk_2002_2009) ///
    workers(5000) firms(500) periods(8) seed(20260903) ///
    truth(full) noreport clear
matrix list r(targets)
keep if employed
collapse (mean) alpha_true psi_true (count) size=workerid, by(firmid)
twoway scatter alpha_true psi_true [aw=size], ///
    msymbol(Oh) mcolor(maroon%55) ///
    xtitle("Firm wage effect") ytitle("Mean worker effect at firm") ///
    title("B. Germany-targeted sorting") name(fesim_emp_sort, replace)
graph combine fesim_emp_moves fesim_emp_sort, ///
    cols(2) xsize(10) ysize(4) name(fesim_mobility, replace)
restore
