version 19.0
preserve
fesim, dgp(blm) preset(dynamic) workers(4000) firms(80) ///
    periods(10) seed(20260924) truth(full) connectivity(largest) noreport clear
* An additive projection of nonadditive earnings, using official Stata.
areg lnwage i.firmid i.time, absorb(workerid)
generate double move_time=time if jobtojob==1
by workerid: egen double first_move=min(move_time)
generate double event_time=time-first_move
by workerid: egen byte destination=max(cond(event_time==0, ///
    ceil(firm_type_true/4),.))
keep if inrange(event_time,-2,2)
by workerid: keep if _N==5
assert _N>0
collapse (mean) lnwage (count) workers=workerid, by(event_time destination)
list event_time destination workers, noobs sepby(destination)
twoway (connected lnwage event_time if destination==1, lcolor(teal)) ///
    (connected lnwage event_time if destination==2, lcolor(navy)) ///
    (connected lnwage event_time if destination==3, lcolor(maroon)), ///
    xline(-.5, lpattern(dash) lcolor(gs10)) xlabel(-2(1)2) ///
    legend(order(1 "Destination classes 1-4" 2 "Classes 5-8" ///
    3 "Classes 9-10") cols(1) size(small)) ///
    xtitle("Years relative to first observed move") ytitle("Mean log earnings") ///
    note("Balanced windows; annual intervals may contain several monthly moves.") ///
    xsize(9) ysize(5) name(fesim_blm_movers, replace)
restore
