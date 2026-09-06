version 19.0
preserve
fesim, dgp(cpv) workers(1000) firms(100) periods(120) ///
    frequency(month) seed(20260908) truth(full) ///
    parameters(beta .15) noreport clear
generate double year=(time-tm(2000m1)+1)/12
by workerid: generate byte cut=jobtojob==1 & n_ee_true==1 & ///
    n_eu_true==0 & n_ue_true==0 & lnwage<lnwage[_n-1]
by workerid: generate byte raise=_n>1 & employed & ///
    spellid==spellid[_n-1] & lnwage>lnwage[_n-1]+1e-12
by workerid: egen byte has_cut=max(cut)
by workerid: egen byte has_raise=max(raise)
quietly levelsof workerid if has_cut & has_raise, local(candidates)
local first : word 1 of `candidates'
local second : word 2 of `candidates'
assert "`second'"!=""
generate double wage=cond(employed,contract_wage_true,0)
local panel=0
foreach id in `first' `second' {
    local ++panel
    quietly levelsof year if workerid==`id' & newjob==1, local(boundaries)
    twoway (connected wage year if workerid==`id', ///
        msize(vtiny) lcolor(navy) mcolor(navy)) ///
        (scatter wage year if workerid==`id' & raise, ///
        msymbol(T) mcolor(orange)) ///
        (scatter wage year if workerid==`id' & cut, ///
        msymbol(D) mcolor(maroon)), ///
        xline(`boundaries', lcolor(gs12) lpattern(dot)) ///
        title("Worker `id'") xtitle("Years") ytitle("Contract wage") ///
        legend(order(1 "Monthly wage" 2 "Within-job raise" ///
        3 "Wage cut on direct move") cols(1) size(small)) ///
        name(fesim_cpv_path`panel', replace)
}
graph combine fesim_cpv_path1 fesim_cpv_path2, cols(2) ///
    note("Dotted lines mark observed new jobs. Zero denotes unemployment.") ///
    xsize(10) ysize(5) name(fesim_cpv_paths, replace)
restore
