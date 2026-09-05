version 19.0
preserve
fesim, dgp(bm) workers(300) firms(100) periods(60) ///
    frequency(month) start(2000m1) seed(20260906) ///
    truth(full) noreport clear
keep if workerid<=4
generate double year = (time-tm(2000m1)+1)/12
generate double plotted_wage = posted_wage_true
replace plotted_wage = 0 if !employed
twoway connected plotted_wage year, sort msymbol(o) msize(vsmall) ///
    lcolor(navy) mcolor(navy) ///
    by(workerid, cols(2) note("Zero denotes unemployment, not a wage.")) ///
    xtitle("Years since retained-sample boundary") ///
    ytitle("Posted wage (level)") ylabel(0 .4 .6 .8 1) ///
    xsize(10) ysize(6) name(fesim_bm_paths, replace)
restore
