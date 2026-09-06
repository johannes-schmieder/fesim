version 19.0
preserve
foreach sign in positive negative {
    local sorting=cond("`sign'"=="positive",1,-1)
    fesim, dgp(blm) workers(12000) firms(120) periods(1) ///
        seed(20260922) truth(full) parameters(sorting `sorting') noreport clear
    contract worker_type_true firm_type_true
    bysort worker_type_true: egen double total=total(_freq)
    generate double share=_freq/total
    twoway contour share worker_type_true firm_type_true, heatmap ///
        xtitle("Firm class") ytitle("Worker type") ///
        title("`sign' sorting") name(blm_`sign', replace)
}
graph combine blm_positive blm_negative, cols(2) ///
    xsize(10) ysize(4.8) name(fesim_blm_sorting, replace)
restore
