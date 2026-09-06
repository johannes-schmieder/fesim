version 19.0
preserve
fesim, dgp(blm) workers(6000) firms(120) periods(6) ///
    seed(20260921) truth(full) noreport clear
collapse (mean) lnwage wage_location_true, ///
    by(worker_type_true firm_type_true)
twoway contour lnwage worker_type_true firm_type_true, heatmap ///
    xtitle("Firm class") ytitle("Worker type") ///
    title("Realized mean log earnings") name(blm_cells, replace)
* The score interaction is the part left after removing row/column means.
by worker_type_true: egen double row_mean=mean(wage_location_true)
bysort firm_type_true: egen double col_mean=mean(wage_location_true)
egen double grand_mean=mean(wage_location_true)
generate double interaction=wage_location_true-row_mean-col_mean+grand_mean
twoway contour interaction worker_type_true firm_type_true, heatmap ///
    xtitle("Firm class") ytitle("Worker type") ///
    title("Nonadditive cell location") name(blm_interaction, replace)
graph combine blm_cells blm_interaction, cols(2) ///
    xsize(10) ysize(4.8) name(fesim_blm_interactions, replace)
restore
