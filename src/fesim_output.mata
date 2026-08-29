version 16.0

mata:

real scalar fesim_output_schema_version()
{
    return(3)
}

real scalar fesim_output_lifecycle_panel(
    struct fesim_results scalar results,
    real scalar start_value,
    string scalar time_format,
    string scalar truth,
    real scalar block_workers,
    real scalar fail_after_block)
{
    real scalar first_worker
    real scalar last_worker
    real scalar first_row
    real scalar last_row
    real scalar block_number
    real colvector rows_to_write
    real matrix block
    real matrix flows
    real colvector time_value
    real colvector employed_rows
    real colvector alpha_true
    real colvector psi_true
    real colvector zero_true
    real colvector lnwage_true
    real rowvector variable_indices
    real rowvector truth_indices

    fesim_results_validate(results)
    truth = strlower(strtrim(truth))
    if (truth != "none" & truth != "basic" & truth != "full") {
        _error(3300, "truth must be none, basic, or full")
    }
    if (missing(start_value) | ///
        (time_format != "%ty" & time_format != "%tq" & ///
        time_format != "%tm")) {
        _error(3300, "output start value or time format is invalid")
    }
    if (missing(block_workers) | block_workers < 1 | ///
        block_workers != floor(block_workers)) {
        _error(3300, "block_workers must be a positive integer")
    }
    if (missing(fail_after_block) | fail_after_block < 0 | ///
        fail_after_block != floor(fail_after_block)) {
        _error(3300, "fail_after_block must be a nonnegative integer")
    }
    if (st_nobs() != 0 | st_nvar() != 0) {
        _error(3300, "lifecycle output writer requires an empty Stata dataset")
    }

    block_workers = min((results.workers, block_workers))
    /* Validate every complete worker block before mutating Stata data. */
    for (first_worker = 1; first_worker <= results.workers; ///
        first_worker = first_worker + block_workers) {
        last_worker = min((results.workers, first_worker + block_workers - 1))
        first_row = (first_worker - 1) * results.periods + 1
        last_row = last_worker * results.periods
        rows_to_write = (first_row::last_row)
        block = results.observed[rows_to_write, ]
        flows = fesim_finalize_flows(block, results.periods)
    }

    st_addobs(results.N)
    variable_indices = st_addvar(("long", "long", "long", "byte", "double", "long", ///
        "double", "byte", "byte", "byte", "byte", "long"), ///
        ("workerid", "time", "firmid", "employed", "lnwage", ///
        "spellid", "tenure", "newjob", "from_unemp", "to_unemp", ///
        "jobtojob", "ntransitions"))
    if (truth != "none") {
        truth_indices = st_addvar(J(1, 7, "double"), ///
            ("alpha_true", "psi_true", "time_true", "xb_true", ///
            "match_true", "epsilon_true", "lnwage_true"))
    }

    block_number = 0
    for (first_worker = 1; first_worker <= results.workers; ///
        first_worker = first_worker + block_workers) {
        block_number = block_number + 1
        last_worker = min((results.workers, first_worker + block_workers - 1))
        first_row = (first_worker - 1) * results.periods + 1
        last_row = last_worker * results.periods
        rows_to_write = (first_row::last_row)
        block = results.observed[rows_to_write, ]
        flows = fesim_finalize_flows(block, results.periods)
        time_value = start_value :+ block[, 2] :- 1

        st_store(rows_to_write, "workerid", block[, 1])
        st_store(rows_to_write, "time", time_value)
        st_store(rows_to_write, "firmid", block[, 3])
        st_store(rows_to_write, "employed", block[, 4])
        st_store(rows_to_write, "lnwage", block[, 5])
        st_store(rows_to_write, "spellid", block[, 6])
        st_store(rows_to_write, "tenure", block[, 7])
        st_store(rows_to_write, "newjob", flows[, 1])
        st_store(rows_to_write, "from_unemp", flows[, 2])
        st_store(rows_to_write, "to_unemp", flows[, 3])
        st_store(rows_to_write, "jobtojob", flows[, 4])
        st_store(rows_to_write, "ntransitions", flows[, 5])

        if (truth != "none") {
            alpha_true = block[, 1] / 100
            psi_true = J(rows(block), 1, .)
            zero_true = J(rows(block), 1, .)
            lnwage_true = J(rows(block), 1, .)
            employed_rows = selectindex(block[, 4] :== 1)
            if (length(employed_rows)) {
                psi_true[employed_rows] = block[employed_rows, 3] / 10
                zero_true[employed_rows] = J(length(employed_rows), 1, 0)
                lnwage_true[employed_rows] = block[employed_rows, 5]
            }
            st_store(rows_to_write, "alpha_true", alpha_true)
            st_store(rows_to_write, "psi_true", psi_true)
            st_store(rows_to_write, "time_true", J(rows(block), 1, 0))
            st_store(rows_to_write, "xb_true", zero_true)
            st_store(rows_to_write, "match_true", zero_true)
            st_store(rows_to_write, "epsilon_true", zero_true)
            st_store(rows_to_write, "lnwage_true", lnwage_true)
        }

        if (fail_after_block > 0 & block_number == fail_after_block) {
            stata("clear", 1)
            _error(3300, "injected lifecycle output failure")
        }
    }

    st_varlabel("workerid", "Worker identifier")
    st_varlabel("time", "Output period")
    st_varlabel("firmid", "Observed employer identifier")
    st_varlabel("employed", "Employed at observation time")
    st_varlabel("lnwage", "Observed log wage")
    st_varlabel("spellid", "Worker-specific job-spell identifier")
    st_varlabel("tenure", "Tenure in output-period units")
    st_varlabel("newjob", "New observed job")
    st_varlabel("from_unemp", "Observed nonemployment-to-employment transition")
    st_varlabel("to_unemp", "Observed employment-to-nonemployment transition")
    st_varlabel("jobtojob", "Observed direct employer-to-employer transition")
    st_varlabel("ntransitions", "Latent transitions since prior observation")
    if (truth != "none") {
        st_varlabel("alpha_true", "True worker effect")
        st_varlabel("psi_true", "True observed-firm effect")
        st_varlabel("time_true", "True deterministic time component")
        st_varlabel("xb_true", "True observable contribution")
        st_varlabel("match_true", "True match contribution")
        st_varlabel("epsilon_true", "True idiosyncratic wage shock")
        st_varlabel("lnwage_true", "True latent log wage")
    }
    st_varformat("time", time_format)
    stata("sort workerid time", 1)
    stata("isid workerid time", 1)
    return(results.N)
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
        if (length(nonemployed)) firm_id[nonemployed] = J(length(nonemployed), 1, .)
        lnwage = 2.5 :+ worker_id / 100000 :+ time / 1000
        if (length(nonemployed)) lnwage[nonemployed] = J(length(nonemployed), 1, .)

        st_store((first_row::last_row), "workerid", worker_id)
        st_store((first_row::last_row), "time", time)
        st_store((first_row::last_row), "firmid", firm_id)
        st_store((first_row::last_row), "employed", employed)
        st_store((first_row::last_row), "lnwage", lnwage)
    }
    return(requested)
}

end
