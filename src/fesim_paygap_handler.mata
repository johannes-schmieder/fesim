version 16.0

mata:

real scalar fesim_paygap_handler_version()
{
    return(1)
}

real scalar fesim_paygap_simulate_to_stata(
    real scalar workers,
    real scalar firms,
    real scalar periods,
    real scalar start_value,
    string scalar time_format,
    real scalar delta_years,
    real scalar requested_seed,
    real scalar seed_was_requested,
    string scalar initial,
    real scalar burnin_years,
    real scalar female_share,
    real scalar mu_male,
    real scalar mu_female,
    real scalar worker_sd_male,
    real scalar worker_sd_female,
    real scalar premium_intercept_male,
    real scalar premium_intercept_female,
    real scalar premium_loading_male,
    real scalar premium_loading_female,
    real scalar premium_deviation_sd_male,
    real scalar premium_deviation_sd_female,
    real scalar error_sd_male,
    real scalar error_sd_female,
    real scalar firm_size_sd,
    real scalar p_eu_male,
    real scalar p_ee_male,
    real scalar p_ue_male,
    real scalar p_eu_female,
    real scalar p_ee_female,
    real scalar p_ue_female,
    real scalar group_sort_male,
    real scalar group_sort_female,
    real scalar worker_sort_male,
    real scalar worker_sort_female,
    real scalar wage_trend_male,
    real scalar wage_trend_female)
{
    struct fesim_population scalar population
    struct fesim_rng_state scalar rng_state
    struct fesim_state scalar state
    real scalar block_workers
    real scalar burnin_periods
    real scalar output_period
    real scalar output_rows
    real matrix wage_components
    real matrix weights

    burnin_periods = burnin_years / delta_years
    if (fesim_output_checked_rows(workers, periods) != workers * periods | ///
        missing(firms) | firms < 2 | firms != floor(firms) | ///
        missing(delta_years) | delta_years <= 0 | ///
        missing(burnin_years) | burnin_years < 0 | ///
        abs(burnin_periods - floor(burnin_periods + .5)) > 1e-10 | ///
        missing(female_share) | female_share <= 0 | female_share >= 1 | ///
        any(missing((mu_male, mu_female, worker_sd_male, ///
        worker_sd_female, premium_intercept_male, ///
        premium_intercept_female, premium_loading_male, ///
        premium_loading_female, premium_deviation_sd_male, ///
        premium_deviation_sd_female, error_sd_male, error_sd_female, ///
        firm_size_sd, p_eu_male, p_ee_male, p_ue_male, ///
        p_eu_female, p_ee_female, p_ue_female, group_sort_male, ///
        group_sort_female, worker_sort_male, worker_sort_female, ///
        wage_trend_male, wage_trend_female))) | ///
        worker_sd_male < 0 | worker_sd_female < 0 | ///
        premium_deviation_sd_male < 0 | ///
        premium_deviation_sd_female < 0 | error_sd_male < 0 | ///
        error_sd_female < 0 | firm_size_sd < 0 | ///
        p_eu_male < 0 | p_eu_male > 1 | p_ee_male < 0 | ///
        p_ee_male > 1 | p_ue_male < 0 | p_ue_male > 1 | ///
        p_eu_female < 0 | p_eu_female > 1 | p_ee_female < 0 | ///
        p_ee_female > 1 | p_ue_female < 0 | p_ue_female > 1 | ///
        p_eu_male + p_ee_male >= 1 | ///
        p_eu_female + p_ee_female >= 1 | ///
        (seed_was_requested != 0 & seed_was_requested != 1)) {
        _error(3300, "pay-gap handler inputs are invalid")
    }
    initial = strlower(strtrim(initial))
    if (initial != "random" & initial != "allunemployed") {
        _error(3300, "pay-gap initialization is invalid")
    }
    burnin_periods = floor(burnin_periods + .5)

    rng_state = fesim_rng_init(requested_seed, seed_was_requested)
    population = fesim_paygap_gen_population(
        workers, firms, female_share, worker_sd_male, worker_sd_female, ///
        premium_intercept_male, premium_intercept_female, ///
        premium_loading_male, premium_loading_female, ///
        premium_deviation_sd_male, premium_deviation_sd_female, ///
        firm_size_sd, rng_state)
    weights = fesim_paygap_destination_weights(
        population, group_sort_male, group_sort_female, ///
        worker_sort_male, worker_sort_female)
    state = fesim_paygap_initialize_state(
        population, weights, initial, rng_state)
    state = fesim_paygap_burn_in(
        state, population, weights, burnin_periods, delta_years, ///
        p_eu_male, p_ee_male, p_ue_male, p_eu_female, p_ee_female, ///
        p_ue_female, rng_state)
    state.ntransitions = J(workers, 1, 0)

    block_workers = fesim_output_default_block(workers, periods)
    output_rows = fesim_output_init_paygap_panel(
        workers, periods, start_value, time_format)
    for (output_period = 1; output_period <= periods; output_period++) {
        if (output_period > 1) {
            state = fesim_paygap_advance(
                state, population, weights, delta_years, ///
                p_eu_male, p_ee_male, p_ue_male, ///
                p_eu_female, p_ee_female, p_ue_female, rng_state)
        }
        wage_components = fesim_paygap_wage_components(
            state, population, mu_male, mu_female, error_sd_male, ///
            error_sd_female, wage_trend_male, wage_trend_female, ///
            (output_period - 1) * delta_years, rng_state)
        fesim_output_store_paygap_period(
            state, population, wage_components, output_period, periods, ///
            start_value)
    }
    output_rows = fesim_output_finalize_panel(
        workers, periods, block_workers, "full")
    fesim_output_finalize_pg_panel()
    return(rng_state.master_seed)
}

end
