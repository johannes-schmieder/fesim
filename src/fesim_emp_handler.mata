version 16.0

mata:

real scalar fesim_emp_handler_schema_version()
{
    return(5)
}

real colvector fesim_emp_truth_targets(
    real scalar worker_sd,
    real scalar firm_sd,
    real scalar error_sd,
    real scalar covariance_target)
{
    if (missing(worker_sd) | missing(firm_sd) | missing(error_sd) | ///
        worker_sd < 0 | firm_sd < 0 | error_sd < 0 | ///
        (!missing(covariance_target) & ///
        abs(covariance_target) > worker_sd * firm_sd + 1e-12)) {
        _error(3300, "empirical AKM truth targets are invalid")
    }
    if (missing(covariance_target)) {
        return((0 \ worker_sd \ worker_sd ^ 2 \ ///
            0 \ firm_sd \ firm_sd ^ 2 \ ///
            0 \ error_sd \ error_sd ^ 2))
    }
    return((0 \ worker_sd \ worker_sd ^ 2 \ ///
        0 \ firm_sd \ firm_sd ^ 2 \ ///
        0 \ error_sd \ error_sd ^ 2 \ covariance_target))
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
    string scalar network_mode,
    real scalar block_count,
    real scalar block_log_bonus,
    real scalar bridge_count,
    real scalar ladder_down_share,
    real scalar ladder_lateral_share,
    real scalar ladder_up_share,
    real scalar ladder_band,
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
    real scalar covariance_target,
    string scalar truth_moment_matrix,
    string scalar truth_target_matrix,
    string scalar bridge_matrix)
{
    struct fesim_destination_tables scalar tables
    struct fesim_empirical_params scalar params
    struct fesim_network_design scalar design
    struct fesim_population scalar population
    struct fesim_rng_state scalar rng_state
    struct fesim_rng_state scalar rng_plan
    struct fesim_state scalar state
    struct fesim_state scalar state_plan
    real scalar alpha_employed_sum
    real scalar alpha_psi_sum
    real scalar alpha_variance
    real scalar block_workers
    real scalar bridge
    real scalar covariance
    real scalar design_block_log_bonus
    real scalar design_bridge_count
    real scalar direct_index
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
    real scalar target_firm
    real colvector active_firms
    real colvector active_rows
    real colvector direct_rows
    real colvector due_plan
    real colvector employed_before
    real colvector employed_rows
    real colvector firm_before
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
        missing(block_count) | missing(block_log_bonus) | ///
        missing(bridge_count) | bridge_count < 0 | ///
        bridge_count != floor(bridge_count) | ///
        any(missing((ladder_down_share, ladder_lateral_share, ///
        ladder_up_share, ladder_band))) | ladder_down_share < 0 | ///
        ladder_down_share > 1 | ladder_lateral_share < 0 | ///
        ladder_lateral_share > 1 | ladder_up_share < 0 | ///
        ladder_up_share > 1 | ladder_band < 0 | ladder_band > 1 | ///
        abs(ladder_down_share + ladder_lateral_share + ///
            ladder_up_share - 1) > 1e-12 | ///
        missing(rho_z_alpha) | abs(rho_z_alpha) > 1 | ///
        missing(rho_q_psi) | abs(rho_q_psi) > 1 | ///
        (worker_sd == 0 & rho_z_alpha != 0) | ///
        (firm_sd == 0 & rho_q_psi != 0) | ///
        any(missing((kappa_eu, eu_worker, eu_firm, eu_duration, ///
        kappa_ee, ee_worker, ee_firm, ee_duration, kappa_ue, ///
        ue_worker, ue_duration, theta_sort, theta_quality, ///
        theta_up, theta_down))) | ///
        (!missing(covariance_target) & ///
        abs(covariance_target) > worker_sd * firm_sd + 1e-12) | ///
        (seed_was_requested != 0 & seed_was_requested != 1) | ///
        strtrim(truth_moment_matrix) == "" | ///
        strtrim(truth_target_matrix) == "" | ///
        strtrim(bridge_matrix) == "") {
        _error(3300, "empirical AKM handler inputs are invalid")
    }
    initial = strlower(strtrim(initial))
    truth = strlower(strtrim(truth))
    network_mode = strlower(strtrim(network_mode))
    if ((initial != "random" & initial != "allunemployed") | ///
        (truth != "none" & truth != "basic" & truth != "full") | ///
        (network_mode != "random" & network_mode != "blocks" & ///
        network_mode != "bridges" & network_mode != "ladder")) {
        _error(3300, "empirical AKM initialization or truth mode is invalid")
    }
    months_per_output = floor(months_per_output + .5)

    rng_state = fesim_rng_init(requested_seed, seed_was_requested)
    population = fesim_emp_generate_population(
        workers, firms, worker_sd, firm_sd, firm_size_sd, ///
        rho_z_alpha, rho_q_psi, rng_state)
    design_block_log_bonus = block_log_bonus
    design_bridge_count = 0
    if (network_mode == "bridges") {
        design_block_log_bonus = 0
        design_bridge_count = bridge_count
    }
    if (network_mode == "ladder") {
        design = fesim_netdesign_build_ladder(
            workers, firms, ladder_down_share, ladder_lateral_share, ///
            ladder_up_share, ladder_band, population.firm_value, rng_state)
    }
    else {
        design = fesim_netdesign_build(network_mode, workers, firms, ///
            block_count, design_block_log_bonus, design_bridge_count, rng_state)
    }
    fesim_netdesign_prepare(design, population.firm_weight)
    params = fesim_emp_params_build(
        kappa_eu, eu_worker, eu_firm, eu_duration, ///
        kappa_ee, ee_worker, ee_firm, ee_duration, ///
        kappa_ue, ue_worker, ue_duration)
    if (network_mode == "random" | network_mode == "ladder") {
        tables = fesim_destination_build(
            population.firm_id, population.firm_weight, ///
            population.firm_quality, theta_sort, theta_quality, ///
            theta_up, theta_down)
        state = fesim_emp_initialize_state(population, initial, rng_state)
        if (network_mode == "random") {
            state = fesim_emp_burn_in(
                state, population, burnin_years, params, tables, rng_state)
        }
        else {
            state = fesim_emp_burn_in_ladder(
                state, population, design, burnin_years, params, tables, ///
                rng_state)
        }
    }
    else {
        if (network_mode == "blocks") {
            tables = fesim_destination_build_blocks(
                population.firm_id, population.firm_weight, ///
                population.firm_quality, design.firm_block, ///
                design.block_count, design.block_log_bonus, ///
                theta_sort, theta_quality, theta_up, theta_down)
        }
        else {
            tables = fesim_destination_build_bridges(
                population.firm_id, population.firm_weight, ///
                population.firm_quality, design.firm_block, ///
                design.block_count, theta_sort, theta_quality, ///
                theta_up, theta_down)
        }
        state = fesim_emp_initialize_block(
            population, design, initial, rng_state)
        state = fesim_emp_burn_in_block(
            state, population, design, burnin_years, params, tables, ///
            rng_state)
    }
    if (network_mode == "bridges") {
        state_plan = state
        rng_plan = rng_state
        design = fesim_netdesign_set_bridge_phase(design, 1)
        for (output_period = 2; output_period <= periods; output_period++) {
            design = fesim_netdesign_begin_output(design, output_period)
            for (month = 1; month <= months_per_output; month++) {
                employed_before = state_plan.employed
                firm_before = state_plan.firm_id
                state_plan = fesim_emp_advance_block(
                    state_plan, population, design, params, tables, rng_plan)
                direct_rows = selectindex(employed_before :== 1 :& ///
                    state_plan.employed :== 1 :& ///
                    firm_before :!= state_plan.firm_id)
                if (length(direct_rows)) {
                    design = fesim_netdesign_note_candidates(
                        design, direct_rows, firm_before[direct_rows], ///
                        state_plan.period)
                }
            }
        }
        design = fesim_netdesign_finish_plan(design)
    }
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
    fesim_output_init_net_truth(design, truth)
    for (output_period = 1; output_period <= periods; output_period++) {
        if (network_mode == "bridges") {
            design = fesim_netdesign_begin_output(design, output_period)
        }
        if (output_period > 1) {
            interval_transitions = J(workers, 1, 0)
            for (month = 1; month <= months_per_output; month++) {
                if (network_mode == "bridges") {
                    employed_before = state.employed
                    firm_before = state.firm_id
                }
                if (network_mode == "random") {
                    state = fesim_emp_advance(
                        state, population, params, tables, rng_state)
                }
                else if (network_mode == "ladder") {
                    state = fesim_emp_advance_ladder(
                        state, population, design, params, tables, rng_state)
                }
                else {
                    state = fesim_emp_advance_block(
                        state, population, design, params, tables, rng_state)
                }
                if (network_mode == "bridges") {
                    direct_rows = selectindex(employed_before :== 1 :& ///
                        state.employed :== 1 :& ///
                        firm_before :!= state.firm_id)
                    if (length(direct_rows)) {
                        due_plan = fesim_netdesign_due_plan(
                            design, direct_rows, state.period)
                        for (direct_index = 1; ///
                            direct_index <= length(direct_rows); ///
                            direct_index++) {
                            bridge = due_plan[direct_index]
                            if (!missing(bridge)) {
                                target_firm = fesim_dest_sample_ee_target(
                                    tables, population.worker_type_index[
                                        direct_rows[direct_index]], ///
                                    firm_before[direct_rows[direct_index]], ///
                                    design.bridge_target_block[bridge], ///
                                    state.last_destination_uniform[
                                        direct_rows[direct_index]])[1]
                                state.firm_id[direct_rows[direct_index]] = ///
                                    target_firm
                                state.current_value[
                                    direct_rows[direct_index]] = ///
                                    population.worker_value[
                                        direct_rows[direct_index]] + ///
                                    population.firm_value[target_firm]
                                design = fesim_netdesign_record_bridge(
                                    design, bridge, ///
                                    direct_rows[direct_index], ///
                                    firm_before[direct_rows[direct_index]], ///
                                    target_firm)
                            }
                        }
                        fesim_state_validate(state, population)
                    }
                }
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
        fesim_output_store_net_truth(
            design, state, output_period, periods, truth)
    }
    fesim_output_finalize_panel(workers, periods, block_workers, truth)
    fesim_output_finalize_emp_panel(truth)
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
        psi_mean \ sqrt(psi_variance) \ psi_variance \ ///
        epsilon_mean \ sqrt(epsilon_variance) \ epsilon_variance \ ///
        covariance)
    st_matrix(truth_moment_matrix, truth_moments)
    st_matrix(truth_target_matrix, ///
        fesim_emp_truth_targets( ///
            worker_sd, firm_sd, error_sd, covariance_target))
    return(rng_state.master_seed)
}

end
