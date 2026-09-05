version 16.0

mata:

real scalar fesim_bm_handler_version()
{
    return(1)
}

real scalar fesim_bm_simulate_to_stata(
    real scalar workers, real scalar firms, real scalar periods,
    real scalar start_value, string scalar time_format,
    string scalar frequency, real scalar seed, real scalar requested_seed,
    string scalar initial, real scalar burnin, string scalar truth,
    real rowvector primitives, real scalar random_firms,
    string scalar solver_name, string scalar firms_name,
    string scalar timing_name, real rowvector timers,
    | real scalar block_workers, real scalar max_events)
{
    struct fesim_bm_solution scalar solution
    struct fesim_bm_firms scalar universe
    struct fesim_bm_state scalar state
    struct fesim_bm_history scalar history
    struct fesim_bm_panel scalar panel
    struct fesim_bm_draw_buffer scalar draws
    struct fesim_rng_state scalar rng
    real scalar first, last, horizon, tolerance, events, written
    real scalar solve_time, simulation_time, peak_events, peak_rows
    real matrix firm_table, firm_summary
    real colvector selected, output_rows
    string rowvector hidden

    tolerance = 1e-9
    horizon = periods * fesim_time_delta_years(frequency)
    if (args() < 18) block_workers = min((10000,
        max((1, floor(100000 / periods))),
        max((1, floor(100000 /
            (1 + horizon * max((primitives[3], primitives[4] + primitives[5]))))))))
    if (args() < 19) max_events = 10000000
    if (missing(block_workers) | block_workers < 1 |
        block_workers != floor(block_workers) | missing(max_events) |
        max_events < 1 | max_events > 10000000 |
        max_events != floor(max_events) | cols(primitives) != 6 |
        (random_firms != 0 & random_firms != 1) | cols(timers) != 3) {
        _error(3300, "BM public handler controls are invalid")
    }
    fesim_runtime_start(timers[2])
    solution = fesim_bm_solve(primitives[1], primitives[2], primitives[3],
        primitives[4], primitives[5], primitives[6], 1001, 4000, tolerance)
    solve_time = fesim_runtime_stop(timers[2])
    fesim_runtime_start(timers[3])
    rng = fesim_rng_init(seed, requested_seed)
    universe = fesim_bm_construct_firms(solution, firms,
        random_firms ? "random" : "quantile", rng, tolerance)
    state = fesim_bm_initialize_state(solution, universe, workers,
        initial, rng, tolerance)
    state = fesim_bm_burn_in(solution, universe, state, burnin,
        max_events, rng, tolerance)
    draws = fesim_bm_draw_buffer_init()
    simulation_time = fesim_runtime_stop(timers[3])
    last = 0
    events = 0
    peak_events = 0
    peak_rows = 0
    hidden = ("_bm_eu", "_bm_ee", "_bm_ue", "_bm_e", "_bm_u")
    for (first = 1; first <= workers; first = last + 1) {
        last = min((workers, first + block_workers - 1))
        selected = first::last
        fesim_runtime_start(timers[3])
        history = fesim_bm_events_buffered(solution, universe,
            state.employed[selected], state.firm_id[selected],
            state.spell_id[selected], state.tenure[selected],
            state.unemployment_duration[selected], horizon, 1,
            max_events, rng, tolerance, draws)
        events = events + history.total_events
        if (events > max_events) {
            _error(430, "BM retained simulation exceeded the 10-million event budget")
        }
        simulation_time = simulation_time + fesim_runtime_stop(timers[3])
        peak_events = max((peak_events, history.total_events))
        panel = fesim_bm_aggregate_history(solution, universe, history,
            frequency, periods, tolerance)
        peak_rows = max((peak_rows, rows(panel.worker_id)))
        written = fesim_bm_output_panel(solution, universe, panel,
            start_value, time_format, truth, first - 1, workers)
        if (first == 1) st_addvar(J(1, 5, "double"), hidden)
        output_rows = ((first - 1) * periods + 1)::(last * periods)
        st_store(output_rows, hidden, (panel.n_eu, panel.n_ee, panel.n_ue,
            panel.employment_exposure, panel.unemployment_exposure))
    }
    st_matrix(solver_name, fesim_bm_solver_diagnostics(solution, universe))
    st_matrixrowstripe(solver_name, (J(22, 1, ""),
        fesim_bm_solver_diagnostic_names()'))
    st_matrixcolstripe(solver_name, ("", "value"))
    /* Compact firm-level summaries are independent of Stata matrix-size limits. */
    firm_table = fesim_bm_firm_diagnostics(solution, universe, workers)
    firm_summary = (mean(firm_table)', colmin(firm_table)', colmax(firm_table)')
    st_matrix(firms_name, firm_summary)
    st_matrixrowstripe(firms_name, (J(10, 1, ""),
        fesim_bm_firm_diagnostic_names()'))
    st_matrixcolstripe(firms_name, (J(3, 1, ""), ("mean" \ "min" \ "max")))
    st_matrix(timing_name, (solve_time, simulation_time, events,
        peak_events, peak_rows, block_workers))
    return(rng.master_seed)
}

void fesim_bm_results_to_stata(
    string scalar solver_name, string scalar flow_name,
    real scalar delta_years, real scalar observed_ue,
    real scalar observed_eu, real scalar observed_ee)
{
    real rowvector counts
    real matrix report
    real scalar first, last, N, unemployed
    last = 0
    N = st_nobs()
    counts = J(1, 5, 0)
    unemployed = 0
    for (first = 1; first <= N; first = last + 1) {
        last = min((N, first + 99999))
        counts = counts + colsum(st_data(first::last,
            ("_bm_eu", "_bm_ee", "_bm_ue", "_bm_e", "_bm_u")))
        unemployed = unemployed + sum(st_data(first::last, "employed") :== 0)
    }
    report = J(4, 4, .)
    report[, 1] = st_matrix(solver_name)[(10 \ 3 \ 5 \ 13), 1]
    report[1, 2] = counts[5] / (counts[4] + counts[5])
    report[1, 3] = unemployed / N
    if (counts[5] > 0) report[2, 2] = counts[3] / counts[5]
    if (counts[4] > 0) report[3..4, 2] = counts[1..2]' / counts[4]
    report[2..4, 3] = (observed_ue \ observed_eu \ observed_ee)
    report[2..4, 4] = report[2..4, 3] / delta_years
    st_matrix(flow_name, report)
    st_matrixrowstripe(flow_name, (J(4, 1, ""),
        ("unemployment_share" \ "ue" \ "eu" \ "ee")))
    st_matrixcolstripe(flow_name, (J(4, 1, ""),
        ("theory" \ "event" \ "observed" \ "observed_per_year")))
}

end
