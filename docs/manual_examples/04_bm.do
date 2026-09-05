version 19.0
preserve
fesim, dgp(bm) workers(10000) firms(100) periods(5) ///
    seed(20260905) truth(full) noreport clear
matrix list r(solver)
matrix list r(bm_flows)
matrix list r(bm_firms)
keep if employed & time==2004
collapse (count) size=workerid (first) posted_wage_true ///
    expected_firm_mass_true offer_quantile_true, by(firmid)
assert _N==100
sort posted_wage_true
generate double worker_cdf = sum(size)
replace worker_cdf = worker_cdf / worker_cdf[_N]
generate double offer_cdf = _n / _N
generate double G = .2*offer_quantile_true / ///
    (.2+.5*(1-offer_quantile_true))
twoway (line offer_cdf posted_wage_true, lcolor(gs8) lpattern(dash)) ///
    (line worker_cdf posted_wage_true, lcolor(navy)) ///
    (line G posted_wage_true, lcolor(maroon) lpattern(shortdash)), ///
    legend(order(1 "Finite firm offers" 2 "Simulated workers" ///
    3 "Continuum worker CDF") cols(1) size(small)) ///
    xtitle("Posted wage (level)") ytitle("Cumulative share") ///
    title("A. Firm and worker wage distributions") ///
    name(fesim_bm_cdf, replace)
generate double expected_size = 10000*expected_firm_mass_true
twoway (scatter size posted_wage_true, mcolor(navy%65) msymbol(Oh)) ///
    (line expected_size posted_wage_true, lcolor(maroon)), ///
    legend(order(1 "Simulated" 2 "Finite stationary expectation")) ///
    xtitle("Posted wage (level)") ytitle("Workers at final snapshot") ///
    title("B. Higher wages attract larger workforces") ///
    name(fesim_bm_size, replace)
graph combine fesim_bm_cdf fesim_bm_size, ///
    cols(2) xsize(10) ysize(4.5) name(fesim_bm, replace)
restore
