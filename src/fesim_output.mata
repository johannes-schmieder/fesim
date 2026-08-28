version 16.0

mata:

real scalar fesim_output_schema_version()
{
    return(1)
}

real scalar fesim_output_checked_rows(real scalar workers, real scalar periods)
{
    real scalar requested
    real scalar supported

    if (missing(workers) | missing(periods) | workers < 1 | periods < 1 | ///
        workers != floor(workers) | periods != floor(periods)) {
        _error(3300, "workers and periods must be positive integers")
    }
    requested = workers * periods
    supported = min((2147483647, st_numscalar("c(max_N_theory)")))
    if (missing(requested) | requested > supported) {
        _error(3300, "requested panel exceeds the supported observation count")
    }
    return(requested)
}

real scalar fesim_output_default_block(
    real scalar workers,
    real scalar periods)
{
    real scalar requested
    real scalar target_rows

    requested = fesim_output_checked_rows(workers, periods)
    target_rows = 250000
    return(min((workers, max((1, floor(target_rows / periods))))))
}

real scalar fesim_output_final_bytes(
    real scalar workers,
    real scalar periods)
{
    real scalar requested

    requested = fesim_output_checked_rows(workers, periods)
    return(requested * 21)
}

real scalar fesim_output_peak_bytes(
    real scalar workers,
    real scalar periods,
    real scalar block_workers)
{
    real scalar block_rows
    real scalar requested

    requested = fesim_output_checked_rows(workers, periods)
    if (missing(block_workers) | block_workers < 1 | ///
        block_workers != floor(block_workers)) {
        _error(3300, "block_workers must be a positive integer")
    }
    block_workers = min((workers, block_workers))
    block_rows = block_workers * periods
    return(fesim_output_final_bytes(workers, periods) + ///
        block_rows * 40 + workers * 32)
}

real scalar fesim_output_toy_panel(
    real scalar workers,
    real scalar periods,
    real scalar block_workers)
{
    real scalar requested
    real scalar first_worker
    real scalar last_worker
    real scalar workers_in_block
    real scalar rows_in_block
    real scalar first_row
    real scalar last_row
    real colvector offset
    real colvector worker_id
    real colvector time
    real colvector employed
    real colvector firm_id
    real colvector lnwage
    real colvector nonemployed
    real rowvector variable_indices

    requested = fesim_output_checked_rows(workers, periods)
    if (missing(block_workers) | block_workers < 1 | ///
        block_workers != floor(block_workers)) {
        _error(3300, "block_workers must be a positive integer")
    }
    block_workers = min((workers, block_workers))
    if (st_nobs() != 0 | st_nvar() != 0) {
        _error(3300, "toy output writer requires an empty Stata dataset")
    }

    st_addobs(requested)
    variable_indices = st_addvar(("long", "long", "long", "byte", "double"), ///
        ("workerid", "time", "firmid", "employed", "lnwage"))

    for (first_worker = 1; first_worker <= workers; ///
        first_worker = first_worker + block_workers) {
        last_worker = min((workers, first_worker + block_workers - 1))
        workers_in_block = last_worker - first_worker + 1
        rows_in_block = workers_in_block * periods
        first_row = (first_worker - 1) * periods + 1
        last_row = first_row + rows_in_block - 1
        offset = (0::(rows_in_block - 1))
        worker_id = first_worker :+ floor(offset / periods)
        time = 1 :+ mod(offset, periods)
        employed = mod(worker_id + time, 3) :!= 0
        firm_id = 1 :+ mod(worker_id * 7 + time * 3, 97)
        nonemployed = selectindex(employed :== 0)
        if (rows(nonemployed)) firm_id[nonemployed] = J(rows(nonemployed), 1, .)
        lnwage = 2.5 :+ worker_id / 100000 :+ time / 1000
        if (rows(nonemployed)) lnwage[nonemployed] = J(rows(nonemployed), 1, .)

        st_store((first_row::last_row), "workerid", worker_id)
        st_store((first_row::last_row), "time", time)
        st_store((first_row::last_row), "firmid", firm_id)
        st_store((first_row::last_row), "employed", employed)
        st_store((first_row::last_row), "lnwage", lnwage)
    }
    return(requested)
}

end
