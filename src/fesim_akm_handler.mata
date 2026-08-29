version 16.0

mata:

real scalar fesim_akm_handler_schema_version()
{
    return(1)
}

real scalar fesim_akm_simulate_to_stata(
    real scalar workers,
    real scalar firms,
    real scalar periods,
    real scalar start_value,
    string scalar time_format,
    real scalar delta_years,
    real scalar requested_seed,
    real scalar seed_was_requested,
    string scalar initial,
    real scalar burnin,
    string scalar truth,
    real scalar mean_log_wage,
    real scalar worker_sd,
    real scalar firm_sd,
    real scalar error_sd,
    real scalar firm_size_sd,
    real scalar annual_eu,
    real scalar annual_ee,
    real scalar annual_ue,
    real scalar wage_trend)
{
    struct fesim_population scalar population
    struct fesim_rng_state scalar rng_state
    struct fesim_state scalar state
    real scalar block_workers
    real scalar output_period
    real matrix wage_components

    if (fesim_output_checked_rows(workers, periods) != workers * periods | ///
        missing(firms) | firms < 1 | firms != floor(firms) | ///
        missing(delta_years) | delta_years <= 0 | ///
        missing(burnin) | burnin < 0 | burnin != floor(burnin) | ///
        missing(mean_log_wage) | missing(worker_sd) | missing(firm_sd) | ///
        missing(error_sd) | missing(firm_size_sd) | ///
        missing(annual_eu) | missing(annual_ee) | missing(annual_ue) | ///
        missing(wage_trend) | worker_sd < 0 | firm_sd < 0 | ///
        error_sd < 0 | firm_size_sd < 0 | ///
        annual_eu < 0 | annual_eu > 1 | annual_ee < 0 | ///
        annual_ee > 1 | annual_ue < 0 | annual_ue > 1 | ///
        annual_eu + annual_ee >= 1 | ///
        (firms == 1 & annual_ee > 0) | ///
        (seed_was_requested != 0 & seed_was_requested != 1)) {
        _error(3300, "simple AKM handler inputs are invalid")
    }

    rng_state = fesim_rng_init(requested_seed, seed_was_requested)
    population = fesim_akm_generate_population(
        workers, firms, worker_sd, firm_sd, firm_size_sd, rng_state)
    state = fesim_akm_initialize_state(
        population, initial, delta_years, annual_eu, annual_ee, ///
        annual_ue, rng_state)
    state = fesim_akm_burn_in(
        state, population, burnin, delta_years, annual_eu, annual_ee, ///
        annual_ue, rng_state)

    block_workers = fesim_output_default_block(workers, periods)
    fesim_output_initialize_panel(
        workers, periods, start_value, time_format, truth)
    for (output_period = 1; output_period <= periods; output_period++) {
        if (output_period > 1) {
            state = fesim_akm_advance(
                state, population, delta_years, annual_eu, annual_ee, ///
                annual_ue, rng_state)
        }
        wage_components = fesim_akm_wage_components(
            state, population, mean_log_wage, error_sd, wage_trend, ///
            (output_period - 1) * delta_years, rng_state)
        fesim_output_store_akm_period(
            state, population, wage_components, output_period, periods, ///
            start_value, truth)
    }
    fesim_output_finalize_panel(workers, periods, block_workers, truth)
    return(rng_state.master_seed)
}

end
