version 19.0
preserve
fesim, dgp(cpv) preset(heterogeneous) workers(6000) firms(100) ///
    periods(3) seed(20260909) truth(full) noreport clear
keep if employed & time==2002
graph box contract_wage_true if mod(firmid,10)==0, ///
    over(firmid, label(labsize(small))) nooutsides ///
    title("A. Wage dispersion within selected firms") ///
    ytitle("Contract wage") name(fesim_cpv_box, replace)
generate double efficiency_wage=contract_wage_true/worker_ability_true
twoway scatter efficiency_wage firm_productivity_true, ///
    msymbol(Oh) msize(vtiny) mcolor(navy%25) ///
    title("B. Dispersion after removing worker ability") ///
    xtitle("Firm productivity per efficiency unit") ///
    ytitle("Wage / worker ability") name(fesim_cpv_normalized, replace)
graph combine fesim_cpv_box fesim_cpv_normalized, cols(2) ///
    xsize(10) ysize(4.5) name(fesim_cpv_dispersion, replace)
restore
