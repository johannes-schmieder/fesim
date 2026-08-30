version 16.0

mata:

real scalar fesim_akm_handler_schema_version()
{
    return(4)
}

real scalar fesim_akm_variance_from_sums(
    real scalar count,
    real scalar value_sum,
    real scalar square_sum)
{
    real scalar variance

    if (count < 2) return(.)
    variance = (square_sum - value_sum ^ 2 / count) / (count - 1)
    if (variance < 0 & abs(variance) < 1e-12) variance = 0
    if (variance < 0 | missing(variance)) {
        _error(3300, "streaming variance is invalid")
    }
    return(variance)
}

real colvector fesim_akm_truth_targets(
    real scalar worker_sd,
    real scalar firm_sd,
    real scalar error_sd)
{
    if (missing(worker_sd) | missing(firm_sd) | missing(error_sd) | ///
        worker_sd < 0 | firm_sd < 0 | error_sd < 0) {
        _error(3300, "simple AKM truth targets are invalid")
    }
    return((0 \ worker_sd \ worker_sd ^ 2 \ ///
        0 \ firm_sd \ firm_sd ^ 2 \ ///
        0 \ error_sd \ error_sd ^ 2 \ 0))
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
    string scalar network_mode,
    real scalar block_count,
    real scalar block_log_bonus,
    real scalar bridge_count,
    real scalar mean_log_wage,
    real scalar worker_sd,
    real scalar firm_sd,
    real scalar error_sd,
    real scalar firm_size_sd,
    real scalar annual_eu,
    real scalar annual_ee,
    real scalar annual_ue,
    real scalar wage_trend,
    string scalar truth_moment_matrix,
    string scalar truth_target_matrix,
    string scalar bridge_matrix)
{
    struct fesim_network_design scalar design
    struct fesim_population scalar population
    struct fesim_rng_state scalar rng_state
    struct fesim_rng_state scalar rng_plan
    struct fesim_state scalar state
    struct fesim_state scalar state_plan
    real scalar block_workers
    real scalar design_block_log_bonus
    real scalar design_bridge_count
    real scalar covariance
    real scalar employed_count
    real scalar epsilon_square_sum
    real scalar epsilon_sum
    real scalar epsilon_mean
    real scalar output_period
    real scalar psi_square_sum
    real scalar psi_sum
    real scalar psi_mean
    real scalar alpha_employed_sum
    real scalar alpha_psi_sum
    real scalar bridge
    real scalar direct_index
    real scalar target_firm
    real scalar psi_employed_sum
    real scalar epsilon_variance
    real scalar psi_variance
    real scalar alpha_variance
    real colvector active_firms
    real colvector active_rows
    real colvector direct_rows
    real colvector due_plan
    real colvector employed_before
    real colvector employed_rows
    real colvector firm_before
    real colvector truth_moments
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
        missing(block_count) | missing(block_log_bonus) | ///
        missing(bridge_count) | bridge_count < 0 | ///
        bridge_count != floor(bridge_count) | ///
        annual_eu < 0 | annual_eu > 1 | annual_ee < 0 | ///
        annual_ee > 1 | annual_ue < 0 | annual_ue > 1 | ///
        annual_eu + annual_ee >= 1 | ///
        (firms == 1 & annual_ee > 0) | ///
        (seed_was_requested != 0 & seed_was_requested != 1) | ///
        strtrim(truth_moment_matrix) == "" | ///
        strtrim(truth_target_matrix) == "" | ///
        strtrim(bridge_matrix) == "") {
        _error(3300, "simple AKM handler inputs are invalid")
    }
    network_mode = strlower(strtrim(network_mode))
    if (network_mode != "random" & network_mode != "blocks" & ///
        network_mode != "bridges") {
        _error(3300, "simple AKM network design is invalid")
    }

    rng_state = fesim_rng_init(requested_seed, seed_was_requested)
    population = fesim_akm_generate_population(
        workers, firms, worker_sd, firm_sd, firm_size_sd, rng_state)
    design_block_log_bonus = block_log_bonus
    design_bridge_count = 0
    if (network_mode == "bridges") {
        design_block_log_bonus = 0
        design_bridge_count = bridge_count
    }
    design = fesim_netdesign_build(network_mode, workers, firms, ///
        block_count, design_block_log_bonus, design_bridge_count, rng_state)
    fesim_netdesign_prepare(design, population.firm_weight)
    if (network_mode == "random") {
        state = fesim_akm_initialize_state(
            population, initial, delta_years, annual_eu, annual_ee, ///
            annual_ue, rng_state)
        state = fesim_akm_burn_in(
            state, population, burnin, delta_years, annual_eu, annual_ee, ///
            annual_ue, rng_state)
    }
    else {
        state = fesim_akm_initialize_block(
            population, design, initial, delta_years, annual_eu, ///
            annual_ee, annual_ue, rng_state)
        state = fesim_akm_burn_in_block(
            state, population, design, burnin, delta_years, annual_eu, ///
            annual_ee, annual_ue, rng_state)
    }
    if (network_mode == "bridges") {
        state_plan = state
        rng_plan = rng_state
        design = fesim_netdesign_set_bridge_phase(design, 1)
        for (output_period = 2; output_period <= periods; output_period++) {
            design = fesim_netdesign_begin_output(design, output_period)
            employed_before = state_plan.employed
            firm_before = state_plan.firm_id
            state_plan = fesim_akm_advance_block(
                state_plan, population, design, delta_years, annual_eu, ///
                annual_ee, annual_ue, rng_plan)
            direct_rows = selectindex(employed_before :== 1 :& ///
                state_plan.employed :== 1 :& ///
                firm_before :!= state_plan.firm_id)
            if (length(direct_rows)) {
                design = fesim_netdesign_note_candidates(
                    design, direct_rows, firm_before[direct_rows], ///
                    state_plan.period)
            }
        }
        design = fesim_netdesign_finish_plan(design)
    }

    block_workers = fesim_output_default_block(workers, periods)
    active_firms = J(firms, 1, 0)
    employed_count = 0
    epsilon_sum = 0
    epsilon_square_sum = 0
    alpha_employed_sum = 0
    psi_employed_sum = 0
    alpha_psi_sum = 0
    fesim_output_initialize_panel(
        workers, periods, start_value, time_format, truth)
    fesim_output_init_net_truth(design, truth)
    for (output_period = 1; output_period <= periods; output_period++) {
        if (network_mode == "bridges") {
            design = fesim_netdesign_begin_output(design, output_period)
        }
        if (output_period > 1) {
            if (network_mode == "bridges") {
                employed_before = state.employed
                firm_before = state.firm_id
            }
            if (network_mode == "random") {
                state = fesim_akm_advance(
                    state, population, delta_years, annual_eu, annual_ee, ///
                    annual_ue, rng_state)
            }
            else {
                state = fesim_akm_advance_block(
                    state, population, design, delta_years, annual_eu, ///
                    annual_ee, annual_ue, rng_state)
            }
            if (network_mode == "bridges") {
                direct_rows = selectindex(employed_before :== 1 :& ///
                    state.employed :== 1 :& firm_before :!= state.firm_id)
                if (length(direct_rows)) {
                    due_plan = fesim_netdesign_due_plan(
                        design, direct_rows, state.period)
                    for (direct_index = 1; ///
                        direct_index <= length(direct_rows); direct_index++) {
                        bridge = due_plan[direct_index]
                        if (!missing(bridge)) {
                            target_firm = fesim_netdesign_sample_common(
                                design, population.firm_weight, ///
                                design.bridge_target_block[bridge], ///
                                state.last_destination_uniform[
                                    direct_rows[direct_index]])[1]
                            state.firm_id[direct_rows[direct_index]] = ///
                                target_firm
                            state.current_value[direct_rows[direct_index]] = ///
                                population.worker_value[
                                    direct_rows[direct_index]] + ///
                                population.firm_value[target_firm]
                            design = fesim_netdesign_record_bridge(
                                design, bridge, direct_rows[direct_index], ///
                                firm_before[direct_rows[direct_index]], ///
                                target_firm)
                        }
                    }
                    fesim_state_validate(state, population)
                }
            }
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
        fesim_output_store_akm_period(
            state, population, wage_components, output_period, periods, ///
            start_value, truth)
        fesim_output_store_net_truth(
            design, state, output_period, periods, truth)
    }
    fesim_output_finalize_panel(workers, periods, block_workers, truth)
    fesim_output_finalize_net_truth(design, truth)
    if (network_mode == "bridges") {
        design = fesim_netdesign_assert_complete(design)
        st_matrix(bridge_matrix, design.bridge_ledger)
    }

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
        psi_mean \ ///
        sqrt(psi_variance) \ psi_variance \ ///
        epsilon_mean \ ///
        sqrt(epsilon_variance) \ epsilon_variance \ covariance)
    st_matrix(truth_moment_matrix, truth_moments)
    st_matrix(truth_target_matrix, ///
        fesim_akm_truth_targets(worker_sd, firm_sd, error_sd))
    return(rng_state.master_seed)
}

end
