version 16.0

mata:

real scalar fesim_emp_handler_schema_version()
{
    return(1)
}

real colvector fesim_emp_truth_targets(
    real scalar worker_sd,
    real scalar firm_sd,
    real scalar error_sd)
{
    if (missing(worker_sd) | missing(firm_sd) | missing(error_sd) | ///
        worker_sd < 0 | firm_sd < 0 | error_sd < 0) {
        _error(3300, "stylized AKM truth targets are invalid")
    }
    return((0 \ worker_sd \ worker_sd ^ 2 \ ///
        0 \ firm_sd \ firm_sd ^ 2 \ ///
        0 \ error_sd \ error_sd ^ 2))
}

real scalar fesim_emp_simulate_to_stata(
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
    string scalar truth,
    real scalar mean_log_wage,
    real scalar worker_sd,
    real scalar firm_sd,
    real scalar error_sd,
    real scalar firm_size_sd,
    real scalar wage_trend,
    real scalar rho_z_alpha,
    real scalar rho_q_psi,
    real scalar kappa_eu,
    real scalar eu_worker,
    real scalar eu_firm,
    real scalar eu_duration,
    real scalar kappa_ee,
    real scalar ee_worker,
    real scalar ee_firm,
    real scalar ee_duration,
    real scalar kappa_ue,
    real scalar ue_worker,
    real scalar ue_duration,
    real scalar theta_sort,
    real scalar theta_quality,
    real scalar theta_up,
    real scalar theta_down,
    string scalar truth_moment_matrix,
    string scalar truth_target_matrix)
{
    struct fesim_destination_tables scalar tables
    struct fesim_empirical_params scalar params
    struct fesim_population scalar population
    struct fesim_rng_state scalar rng_state
    struct fesim_state scalar state
    real scalar alpha_employed_sum
    real scalar alpha_psi_sum
    real scalar alpha_variance
    real scalar block_workers
    real scalar covariance
    real scalar employed_count
    real scalar epsilon_mean
    real scalar epsilon_square_sum
    real scalar epsilon_sum
    real scalar epsilon_variance
    real scalar month
    real scalar months_per_output
    real scalar output_period
    real scalar psi_employed_sum
    real scalar psi_mean
    real scalar psi_square_sum
    real scalar psi_sum
    real scalar psi_variance
    real colvector active_firms
    real colvector active_rows
    real colvector employed_rows
    real colvector interval_transitions
    real colvector truth_moments
    real matrix wage_components

    months_per_output = delta_years / fesim_emp_month_years()
    if (fesim_output_checked_rows(workers, periods) != workers * periods | ///
        missing(firms) | firms < 2 | firms != floor(firms) | ///
        missing(delta_years) | delta_years <= 0 | ///
        abs(months_per_output - floor(months_per_output + .5)) > 1e-10 | ///
        missing(burnin_years) | burnin_years < 0 | ///
        missing(mean_log_wage) | missing(worker_sd) | missing(firm_sd) | ///
        missing(error_sd) | missing(firm_size_sd) | missing(wage_trend) | ///
        worker_sd < 0 | firm_sd < 0 | error_sd < 0 | firm_size_sd < 0 | ///
        missing(rho_z_alpha) | abs(rho_z_alpha) > 1 | ///
        missing(rho_q_psi) | abs(rho_q_psi) > 1 | ///
        (worker_sd == 0 & rho_z_alpha != 0) | ///
        (firm_sd == 0 & rho_q_psi != 0) | ///
        any(missing((kappa_eu, eu_worker, eu_firm, eu_duration, ///
        kappa_ee, ee_worker, ee_firm, ee_duration, kappa_ue, ///
        ue_worker, ue_duration, theta_sort, theta_quality, ///
        theta_up, theta_down))) | ///
        (seed_was_requested != 0 & seed_was_requested != 1) | ///
        strtrim(truth_moment_matrix) == "" | ///
        strtrim(truth_target_matrix) == "") {
        _error(3300, "stylized AKM handler inputs are invalid")
    }
    initial = strlower(strtrim(initial))
    truth = strlower(strtrim(truth))
    if ((initial != "random" & initial != "allunemployed") | ///
        (truth != "none" & truth != "basic" & truth != "full")) {
        _error(3300, "stylized AKM initialization or truth mode is invalid")
    }
    months_per_output = floor(months_per_output + .5)

    rng_state = fesim_rng_init(requested_seed, seed_was_requested)
    population = fesim_emp_generate_population(
        workers, firms, worker_sd, firm_sd, firm_size_sd, ///
        rho_z_alpha, rho_q_psi, rng_state)
    params = fesim_emp_params_build(
        kappa_eu, eu_worker, eu_firm, eu_duration, ///
        kappa_ee, ee_worker, ee_firm, ee_duration, ///
        kappa_ue, ue_worker, ue_duration)
    tables = fesim_destination_build(
        population.firm_id, population.firm_weight, ///
        population.firm_quality, theta_sort, theta_quality, ///
        theta_up, theta_down)
    state = fesim_emp_initialize_state(population, initial, rng_state)
    state = fesim_emp_burn_in(
        state, population, burnin_years, params, tables, rng_state)
    state.ntransitions = J(workers, 1, 0)

    block_workers = fesim_output_default_block(workers, periods)
    active_firms = J(firms, 1, 0)
    employed_count = 0
    epsilon_sum = 0
    epsilon_square_sum = 0
    alpha_employed_sum = 0
    psi_employed_sum = 0
    alpha_psi_sum = 0
    fesim_output_init_emp_panel(
        workers, periods, start_value, time_format, truth)
    for (output_period = 1; output_period <= periods; output_period++) {
        if (output_period > 1) {
            interval_transitions = J(workers, 1, 0)
            for (month = 1; month <= months_per_output; month++) {
                state = fesim_emp_advance(
                    state, population, params, tables, rng_state)
                interval_transitions = interval_transitions :+ ///
                    state.ntransitions
            }
            state.ntransitions = interval_transitions
        }
        wage_components = fesim_akm_wage_components(
            state, population, mean_log_wage, error_sd, wage_trend, ///
            (output_period - 1) * delta_years, rng_state)
        employed_rows = selectindex(state.employed :== 1)
        if (length(employed_rows)) {
            active_firms[state.firm_id[employed_rows]] = ///
                J(length(employed_rows), 1, 1)
            employed_count = employed_count + length(employed_rows)
            epsilon_sum = epsilon_sum + ///
                quadsum(wage_components[employed_rows, 7])
            epsilon_square_sum = epsilon_square_sum + ///
                quadsum(wage_components[employed_rows, 7] :^ 2)
            alpha_employed_sum = alpha_employed_sum + ///
                quadsum(wage_components[employed_rows, 2])
            psi_employed_sum = psi_employed_sum + ///
                quadsum(wage_components[employed_rows, 3])
            alpha_psi_sum = alpha_psi_sum + quadsum( ///
                wage_components[employed_rows, 2] :* ///
                wage_components[employed_rows, 3])
        }
        fesim_output_store_emp_period(
            state, population, wage_components, output_period, periods, ///
            start_value, delta_years, truth)
    }
    fesim_output_finalize_panel(workers, periods, block_workers, truth)
    fesim_output_finalize_emp_panel(truth)

    alpha_variance = fesim_sample_variance(population.worker_value)
    active_rows = selectindex(active_firms :== 1)
    psi_sum = 0
    psi_square_sum = 0
    psi_mean = .
    psi_variance = .
    if (length(active_rows)) {
        psi_sum = quadsum(population.firm_value[active_rows])
        psi_square_sum = quadsum(population.firm_value[active_rows] :^ 2)
        psi_mean = psi_sum / length(active_rows)
        psi_variance = fesim_akm_variance_from_sums(
            length(active_rows), psi_sum, psi_square_sum)
    }
    epsilon_variance = fesim_akm_variance_from_sums(
        employed_count, epsilon_sum, epsilon_square_sum)
    epsilon_mean = .
    if (employed_count) epsilon_mean = epsilon_sum / employed_count
    covariance = .
    if (employed_count >= 2) {
        covariance = (alpha_psi_sum - ///
            alpha_employed_sum * psi_employed_sum / employed_count) / ///
            (employed_count - 1)
    }
    truth_moments = (mean(population.worker_value) \ ///
        sqrt(alpha_variance) \ alpha_variance \ ///
        psi_mean \ sqrt(psi_variance) \ psi_variance \ ///
        epsilon_mean \ sqrt(epsilon_variance) \ epsilon_variance \ ///
        covariance)
    st_matrix(truth_moment_matrix, truth_moments)
    st_matrix(truth_target_matrix, ///
        fesim_emp_truth_targets(worker_sd, firm_sd, error_sd))
    return(rng_state.master_seed)
}

end
