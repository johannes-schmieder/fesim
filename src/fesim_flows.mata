version 16.0

mata:

real scalar fesim_flow_schema_version()
{
    return(1)
}

real matrix fesim_finalize_flows(
    real matrix observed,
    real scalar periods)
{
    real scalar N
    real scalar workers
    real scalar worker
    real scalar first_row
    real scalar last_row
    real scalar row
    real scalar current_employed
    real scalar previous_employed
    real colvector expected_worker
    real colvector expected_period
    real colvector employed_rows
    real colvector nonemployed_rows
    real matrix flows

    N = rows(observed)
    if (missing(periods) | periods < 1 | periods != floor(periods) | ///
        N < 1 | cols(observed) != 8 | mod(N, periods) != 0) {
        _error(3300, "flow input must contain complete worker histories")
    }
    workers = N / periods
    if (missing(observed[1, 1]) | observed[1, 1] < 1 | ///
        observed[1, 1] != floor(observed[1, 1])) {
        _error(3300, "flow input has an invalid first worker identifier")
    }
    expected_worker = observed[1, 1] :+ floor((0::(N - 1)) / periods)
    expected_period = 1 :+ mod((0::(N - 1)), periods)
    if (any(observed[, 1] :!= expected_worker) | ///
        any(observed[, 2] :!= expected_period)) {
        _error(3300, "flow input must be worker-major with complete periods")
    }
    if (any(observed[, 4] :!= 0 :& observed[, 4] :!= 1)) {
        _error(3300, "flow input employment indicators must be zero or one")
    }

    employed_rows = selectindex(observed[, 4] :== 1)
    nonemployed_rows = selectindex(observed[, 4] :== 0)
    if (length(employed_rows) & ///
        (any(missing(observed[employed_rows, 3])) | ///
        any(observed[employed_rows, 3] :< 1) | ///
        any(observed[employed_rows, 3] :!= floor(observed[employed_rows, 3])) | ///
        any(missing(observed[employed_rows, 6])) | ///
        any(observed[employed_rows, 6] :< 1) | ///
        any(observed[employed_rows, 6] :!= floor(observed[employed_rows, 6])))) {
        _error(3300, "employed flow input requires valid firm and spell identifiers")
    }
    if (length(nonemployed_rows) & ///
        (any(!missing(observed[nonemployed_rows, 3])) | ///
        any(!missing(observed[nonemployed_rows, 6])))) {
        _error(3300, "nonemployed flow input requires missing firm and spell identifiers")
    }
    if (any(missing(observed[, 8])) | any(observed[, 8] :< 0) | ///
        any(observed[, 8] :!= floor(observed[, 8]))) {
        _error(3300, "latent transition counts must be nonnegative integers")
    }

    flows = J(N, 5, .)
    for (worker = 1; worker <= workers; worker++) {
        first_row = (worker - 1) * periods + 1
        last_row = worker * periods

        for (row = first_row + 1; row <= last_row; row++) {
            current_employed = observed[row, 4]
            previous_employed = observed[row - 1, 4]
            if (!current_employed) {
                flows[row, 1] = 0
            }
            else if (!previous_employed) {
                flows[row, 1] = 1
            }
            else {
                flows[row, 1] = observed[row, 3] != observed[row - 1, 3] | ///
                    observed[row, 6] != observed[row - 1, 6]
            }
            flows[row, 2] = !previous_employed & current_employed
            flows[row, 4] = previous_employed & current_employed & ///
                observed[row, 3] != observed[row - 1, 3]
            flows[row, 5] = observed[row, 8]
        }
        for (row = first_row; row < last_row; row++) {
            flows[row, 3] = observed[row, 4] & !observed[row + 1, 4]
        }
    }
    return(flows)
}

end
