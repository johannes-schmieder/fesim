version 19.0
preserve
fesim, dgp(bm) workers(4000) firms(100) periods(5) ///
    frequency(year) seed(20260907) truth(none) noreport clear
matrix annual = r(bm_flows)
fesim, dgp(bm) workers(4000) firms(100) periods(60) ///
    frequency(month) seed(20260907) truth(none) noreport clear
matrix monthly = r(bm_flows)
assert reldif(annual[2,2],monthly[2,2])<1e-10
assert reldif(annual[3,2],monthly[3,2])<1e-10
assert reldif(annual[4,2],monthly[4,2])<1e-10
matrix comparisons = (annual[2..4,1], annual[2..4,2], ///
    annual[2..4,4], monthly[2..4,4])
matrix colnames comparisons = theory event annual_endpoint monthly_endpoint
clear
svmat double comparisons, names(col)
generate byte flow = _n
label define fesim_flow 1 "UE" 2 "EU" 3 "EE", replace
label values flow fesim_flow
graph bar theory event annual_endpoint monthly_endpoint, over(flow) ///
    bar(1,color(gs10)) bar(2,color(navy)) ///
    bar(3,color(maroon)) bar(4,color(teal)) ///
    legend(order(1 "Finite stationary hazard" 2 "Exact event / exposure" ///
    3 "Annual endpoint probability" 4 "Monthly endpoint probability x 12") ///
    cols(2) size(small)) ytitle("Rate or probability per year") ///
    xsize(10) ysize(5) name(fesim_bm_flows, replace)
matrix drop annual monthly comparisons
restore
