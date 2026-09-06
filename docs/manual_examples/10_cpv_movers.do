version 19.0
preserve
fesim, dgp(cpv) preset(heterogeneous) workers(5000) firms(100) ///
    periods(10) seed(20260911) truth(full) noreport clear
* Official Stata AKM-style projection; not structural productivity recovery.
areg lnwage i.firmid i.time if employed, absorb(workerid)
* Select the first observed interval with exactly one direct EE and no EU/UE.
generate double move_time=time if jobtojob==1 & n_ee_true==1 & ///
    n_eu_true==0 & n_ue_true==0
by workerid: egen double first_move=min(move_time)
generate double event_time=time-first_move
by workerid: egen byte destination=max(cond(event_time==0, ///
    ceil(4*firmid/100),.))
keep if inrange(event_time,-2,2) & employed
by workerid: keep if _N==5
assert _N>0
collapse (mean) lnwage (count) workers=workerid, by(event_time destination)
list event_time destination workers, noobs sepby(destination)
twoway (connected lnwage event_time if destination==1, lcolor(gs7)) ///
    (connected lnwage event_time if destination==2, lcolor(teal)) ///
    (connected lnwage event_time if destination==3, lcolor(navy)) ///
    (connected lnwage event_time if destination==4, lcolor(maroon)), ///
    xline(-.5, lpattern(dash) lcolor(gs10)) xlabel(-2(1)2) ///
    legend(order(1 "Destination Q1" 2 "Destination Q2" ///
    3 "Destination Q3" 4 "Destination Q4") cols(2) size(small)) ///
    xtitle("Years relative to first selected direct move") ///
    ytitle("Mean log wage") ///
    note("Balanced employed windows; descriptive selected-mover averages.") ///
    xsize(9) ysize(5) name(fesim_cpv_movers, replace)
restore
