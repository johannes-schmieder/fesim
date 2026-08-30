version 16.0

mata:

real scalar fesim_emp_schema_version()
{
    return(2)
}

real scalar fesim_emp_month_years()
{
    return(1 / 12)
}

struct fesim_empirical_params scalar fesim_emp_params_build(
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
    real scalar ue_duration)
{
    struct fesim_empirical_params scalar params

    params.schema_version = fesim_emp_schema_version()
    params.kappa_eu = kappa_eu
    params.eu_worker = eu_worker
    params.eu_firm = eu_firm
    params.eu_duration = eu_duration
    params.kappa_ee = kappa_ee
    params.ee_worker = ee_worker
    params.ee_firm = ee_firm
    params.ee_duration = ee_duration
    params.kappa_ue = kappa_ue
    params.ue_worker = ue_worker
    params.ue_duration = ue_duration
    params.validated = 1
    fesim_emp_params_validate(params)
    return(params)
}

void fesim_emp_params_validate(
    struct fesim_empirical_params scalar params)
{
    if (params.schema_version != fesim_emp_schema_version() | ///
        params.validated != 1 | ///
        any(missing((params.kappa_eu, params.eu_worker, ///
        params.eu_firm, params.eu_duration, params.kappa_ee, ///
        params.ee_worker, params.ee_firm, params.ee_duration, ///
        params.kappa_ue, params.ue_worker, params.ue_duration)))) {
        _error(3300, "empirical hazard parameters are invalid")
    }
}

real colvector fesim_emp_standardize(real colvector values)
{
    real scalar standard_deviation
    real colvector centered

    if (cols(values) != 1 | rows(values) < 2 | any(missing(values))) {
        _error(3300, "empirical standardization requires finite variation")
    }
    centered = values :- mean(values)
    standard_deviation = sqrt(variance(centered))
    if (missing(standard_deviation) | standard_deviation <= 0) {
        _error(3300, "empirical standardization requires positive variation")
    }
    return(centered / standard_deviation)
}

void fesim_emp_population_validate(
    struct fesim_population scalar population)
{
    real scalar worker
    real rowvector support

    fesim_population_validate(population)
    if (population.firms < 2 | ///
        any(missing(population.worker_type_index)) | ///
        any(missing(population.worker_mobility)) | ///
        any(missing(population.firm_quality)) | ///
        any(population.firm_weight :<= 0) | ///
        abs(mean(population.firm_quality)) > 1e-12 | ///
        abs(variance(population.firm_quality) - 1) > 1e-10) {
        _error(3300, "empirical population is invalid")
    }
    support = fesim_destination_type_support()
    for (worker = 1; worker <= population.workers; worker++) {
        if (population.worker_mobility[worker] != ///
            support[population.worker_type_index[worker]]) {
            _error(3300, "empirical worker mobility support is invalid")
        }
    }
}

struct fesim_population scalar fesim_emp_generate_population(
    real scalar workers,
    real scalar firms,
    real scalar worker_sd,
    real scalar firm_sd,
    real scalar firm_size_sd,
    real scalar rho_z_alpha,
    real scalar rho_q_psi,
    struct fesim_rng_state scalar rng_state)
{
    struct fesim_population scalar population
    real scalar bin
    real colvector attraction_standard
    real colvector firm_innovation
    real colvector firm_standard
    real colvector mobility_latent
    real colvector quality_latent
    real colvector worker_innovation
    real colvector worker_standard
    real rowvector thresholds
    real rowvector type_support

    if (missing(workers) | missing(firms) | workers < 1 | firms < 2 | ///
        workers != floor(workers) | firms != floor(firms) | ///
        missing(worker_sd) | missing(firm_sd) | missing(firm_size_sd) | ///
        worker_sd < 0 | firm_sd < 0 | firm_size_sd < 0 | ///
        missing(rho_z_alpha) | abs(rho_z_alpha) > 1 | ///
        missing(rho_q_psi) | abs(rho_q_psi) > 1) {
        _error(3300, "empirical population inputs are invalid")
    }

    worker_standard = fesim_rng_rnormal(
        rng_state, "worker_primitives", workers, 1, 0, 1)
    worker_innovation = fesim_rng_rnormal(
        rng_state, "worker_primitives", workers, 1, 0, 1)
    firm_standard = fesim_rng_rnormal(
        rng_state, "firm_primitives", firms, 1, 0, 1)
    firm_innovation = fesim_rng_rnormal(
        rng_state, "firm_primitives", firms, 1, 0, 1)
    attraction_standard = fesim_rng_rnormal(
        rng_state, "firm_primitives", firms, 1, 0, 1)

    mobility_latent = rho_z_alpha :* worker_standard :+ ///
        sqrt(max((0, 1 - rho_z_alpha ^ 2))) :* worker_innovation
    quality_latent = rho_q_psi :* firm_standard :+ ///
        sqrt(max((0, 1 - rho_q_psi ^ 2))) :* firm_innovation
    thresholds = invnormal((.2, .4, .6, .8))
    population.worker_type_index = J(workers, 1, 1)
    for (bin = 1; bin <= 4; bin++) {
        population.worker_type_index = population.worker_type_index :+ ///
            (mobility_latent :> thresholds[bin])
    }
    type_support = fesim_destination_type_support()
    population.worker_mobility = ///
        (type_support[population.worker_type_index])'

    population.schema_version = fesim_population_schema_version()
    population.workers = workers
    population.firms = firms
    population.worker_id = (1::workers)
    population.firm_id = (1::firms)
    population.worker_value = worker_sd :* worker_standard
    population.firm_value = firm_sd :* firm_standard
    population.firm_weight = fesim_akm_stable_weights(
        attraction_standard, firm_size_sd)
    population.firm_quality = fesim_emp_standardize(quality_latent)
    population.validated = 0
    fesim_emp_population_validate(population)
    population.validated = 1
    return(population)
}

void fesim_emp_tables_validate(
    struct fesim_population scalar population,
    struct fesim_destination_tables scalar tables)
{
    fesim_emp_population_validate(population)
    fesim_destination_assert_valid(tables)
    if (rows(tables.firm_id) != population.firms | ///
        any(tables.firm_id :!= population.firm_id) | ///
        max(abs(tables.firm_weight :- population.firm_weight)) > 1e-12 | ///
        max(abs(tables.firm_quality :- population.firm_quality)) > 1e-12) {
        _error(3300, "empirical destination tables do not match population")
    }
}

struct fesim_state scalar fesim_emp_initialize_state(
    struct fesim_population scalar population,
    string scalar initial,
    struct fesim_rng_state scalar rng_state)
{
    struct fesim_state scalar state
    real colvector destination_draws
    real colvector employed_rows
    real colvector employment_draws

    fesim_emp_population_validate(population)
    initial = strlower(strtrim(initial))
    if (initial != "random" & initial != "allunemployed") {
        _error(3300, "empirical initial state must be random or allunemployed")
    }

    state.schema_version = fesim_state_schema_version()
    state.period = 1
    state.employed = J(population.workers, 1, 0)
    state.firm_id = J(population.workers, 1, .)
    state.spell_id = J(population.workers, 1, 0)
    state.tenure = J(population.workers, 1, .)
    state.unemployment_duration = J(population.workers, 1, 0)
    state.ntransitions = J(population.workers, 1, 0)
    state.current_value = J(population.workers, 1, .)
    state.last_destination_uniform = J(population.workers, 1, .)

    if (initial == "random") {
        employment_draws = fesim_rng_runiform(
            rng_state, "initial_states", population.workers, 1)
        destination_draws = fesim_rng_runiform(
            rng_state, "destination_draws", population.workers, 1)
        state.employed = employment_draws :< .5
        employed_rows = selectindex(state.employed :== 1)
        if (length(employed_rows)) {
            state.firm_id[employed_rows] = fesim_destination_sample_common(
                population.firm_weight, destination_draws[employed_rows])
            state.spell_id[employed_rows] = J(length(employed_rows), 1, 1)
            state.tenure[employed_rows] = J(length(employed_rows), 1, 0)
            state.unemployment_duration[employed_rows] = ///
                J(length(employed_rows), 1, .)
            state.current_value[employed_rows] = ///
                population.worker_value[employed_rows] :+ ///
                population.firm_value[state.firm_id[employed_rows]]
        }
    }
    state.validated = 0
    fesim_state_validate(state, population)
    state.validated = 1
    return(state)
}

real colvector fesim_emp_select_rows(
    real colvector rows_to_select,
    real colvector condition)
{
    real colvector selected

    if (cols(rows_to_select) != 1 | cols(condition) != 1 | ///
        rows(rows_to_select) != rows(condition) | ///
        any(condition :!= 0 :& condition :!= 1)) {
        _error(3300, "empirical row selection is invalid")
    }
    selected = selectindex(condition)
    if (!length(selected)) return(J(0, 1, .))
    return(rows_to_select[selected])
}

struct fesim_state scalar fesim_emp_advance(
    struct fesim_state scalar state,
    struct fesim_population scalar population,
    struct fesim_empirical_params scalar params,
    struct fesim_destination_tables scalar tables,
    struct fesim_rng_state scalar rng_state)
{
    real matrix employed_probabilities
    real colvector destination_draws
    real colvector direct_current
    real colvector direct_rows
    real colvector employed_rows
    real colvector entry_rows
    real colvector event_draws
    real colvector exit_rows
    real colvector retained_employed
    real colvector stay_employed
    real colvector stay_unemployed
    real colvector unemployed_probability
    real colvector unemployed_rows

    fesim_emp_population_validate(population)
    fesim_state_validate(state, population)
    fesim_emp_params_validate(params)
    fesim_emp_tables_validate(population, tables)

    event_draws = fesim_rng_runiform(
        rng_state, "mobility_events", population.workers, 1)
    destination_draws = fesim_rng_runiform(
        rng_state, "destination_draws", population.workers, 1)
    state.last_destination_uniform = destination_draws
    employed_rows = selectindex(state.employed :== 1)
    unemployed_rows = selectindex(state.employed :== 0)
    exit_rows = J(0, 1, .)
    direct_rows = J(0, 1, .)
    stay_employed = J(0, 1, .)
    entry_rows = J(0, 1, .)
    stay_unemployed = J(0, 1, .)

    if (length(employed_rows)) {
        employed_probabilities = fesim_hazard_competing_from_log(
            fesim_hazard_employed_log(params.kappa_eu, ///
                params.eu_worker, population.worker_mobility[employed_rows], ///
                params.eu_firm, ///
                population.firm_quality[state.firm_id[employed_rows]], ///
                params.eu_duration, state.tenure[employed_rows]), ///
            fesim_hazard_employed_log(params.kappa_ee, ///
                params.ee_worker, population.worker_mobility[employed_rows], ///
                params.ee_firm, ///
                population.firm_quality[state.firm_id[employed_rows]], ///
                params.ee_duration, state.tenure[employed_rows]), ///
            fesim_emp_month_years())
        exit_rows = fesim_emp_select_rows(employed_rows, ///
            event_draws[employed_rows] :< employed_probabilities[, 1])
        direct_rows = fesim_emp_select_rows(employed_rows, ///
            event_draws[employed_rows] :>= employed_probabilities[, 1] :& ///
            event_draws[employed_rows] :< ///
                employed_probabilities[, 1] :+ employed_probabilities[, 2])
        stay_employed = fesim_emp_select_rows(employed_rows, ///
            event_draws[employed_rows] :>= ///
                employed_probabilities[, 1] :+ employed_probabilities[, 2])
    }
    if (length(unemployed_rows)) {
        unemployed_probability = fesim_hazard_one_from_log(
            fesim_hazard_unemployed_log(params.kappa_ue, ///
                params.ue_worker, ///
                population.worker_mobility[unemployed_rows], ///
                params.ue_duration, ///
                state.unemployment_duration[unemployed_rows]), ///
            fesim_emp_month_years())
        entry_rows = fesim_emp_select_rows(unemployed_rows, ///
            event_draws[unemployed_rows] :< unemployed_probability)
        stay_unemployed = fesim_emp_select_rows(unemployed_rows, ///
            event_draws[unemployed_rows] :>= unemployed_probability)
    }

    direct_current = state.firm_id[direct_rows]
    state.period = state.period + 1
    state.ntransitions = J(population.workers, 1, 0)
    if (length(stay_employed)) {
        state.tenure[stay_employed] = state.tenure[stay_employed] :+ ///
            fesim_emp_month_years()
    }
    if (length(stay_unemployed)) {
        state.unemployment_duration[stay_unemployed] = ///
            state.unemployment_duration[stay_unemployed] :+ ///
            fesim_emp_month_years()
    }
    if (length(exit_rows)) {
        state.employed[exit_rows] = J(length(exit_rows), 1, 0)
        state.firm_id[exit_rows] = J(length(exit_rows), 1, .)
        state.tenure[exit_rows] = J(length(exit_rows), 1, .)
        state.unemployment_duration[exit_rows] = J(length(exit_rows), 1, 0)
        state.current_value[exit_rows] = J(length(exit_rows), 1, .)
        state.ntransitions[exit_rows] = J(length(exit_rows), 1, 1)
    }
    if (length(direct_rows)) {
        state.firm_id[direct_rows] = fesim_destination_sample_ee(
            tables, population.worker_type_index[direct_rows], ///
            direct_current, destination_draws[direct_rows])
        state.spell_id[direct_rows] = state.spell_id[direct_rows] :+ 1
        state.tenure[direct_rows] = J(length(direct_rows), 1, 0)
        state.ntransitions[direct_rows] = J(length(direct_rows), 1, 1)
    }
    if (length(entry_rows)) {
        state.employed[entry_rows] = J(length(entry_rows), 1, 1)
        state.firm_id[entry_rows] = fesim_destination_sample_ue(
            tables, population.worker_type_index[entry_rows], ///
            destination_draws[entry_rows])
        state.spell_id[entry_rows] = state.spell_id[entry_rows] :+ 1
        state.tenure[entry_rows] = J(length(entry_rows), 1, 0)
        state.unemployment_duration[entry_rows] = J(length(entry_rows), 1, .)
        state.ntransitions[entry_rows] = J(length(entry_rows), 1, 1)
    }
    retained_employed = selectindex(state.employed :== 1)
    if (length(retained_employed)) {
        state.current_value[retained_employed] = ///
            population.worker_value[retained_employed] :+ ///
            population.firm_value[state.firm_id[retained_employed]]
    }
    fesim_state_validate(state, population)
    state.validated = 1
    return(state)
}

struct fesim_state scalar fesim_emp_burn_in(
    struct fesim_state scalar state,
    struct fesim_population scalar population,
    real scalar burnin_years,
    struct fesim_empirical_params scalar params,
    struct fesim_destination_tables scalar tables,
    struct fesim_rng_state scalar rng_state)
{
    real scalar month
    real scalar months

    if (missing(burnin_years) | burnin_years < 0) {
        _error(3300, "empirical burn-in years are invalid")
    }
    months = burnin_years / fesim_emp_month_years()
    if (abs(months - floor(months + .5)) > 1e-10) {
        _error(3300, "empirical burn-in must be a whole number of months")
    }
    months = floor(months + .5)
    fesim_emp_population_validate(population)
    fesim_state_validate(state, population)
    fesim_emp_params_validate(params)
    fesim_emp_tables_validate(population, tables)
    for (month = 1; month <= months; month++) {
        state = fesim_emp_advance(
            state, population, params, tables, rng_state)
    }
    return(state)
}

struct fesim_state scalar fesim_emp_initialize_block(
    struct fesim_population scalar population,
    struct fesim_network_design scalar design,
    string scalar initial,
    struct fesim_rng_state scalar rng_state)
{
    struct fesim_state scalar state
    real colvector destination_draws
    real colvector employed_rows
    real colvector employment_draws

    fesim_emp_population_validate(population)
    fesim_netdesign_validate(design)
    initial = strlower(strtrim(initial))
    if ((design.mode != "blocks" & design.mode != "bridges") | ///
        design.prepared != 1 | ///
        (initial != "random" & initial != "allunemployed")) {
        _error(3300, "empirical block initial state is invalid")
    }
    if (design.mode == "blocks" & design.block_log_bonus == 0) {
        return(fesim_emp_initialize_state(population, initial, rng_state))
    }
    state.schema_version = fesim_state_schema_version()
    state.period = 1
    state.employed = J(population.workers, 1, 0)
    state.firm_id = J(population.workers, 1, .)
    state.spell_id = J(population.workers, 1, 0)
    state.tenure = J(population.workers, 1, .)
    state.unemployment_duration = J(population.workers, 1, 0)
    state.ntransitions = J(population.workers, 1, 0)
    state.current_value = J(population.workers, 1, .)
    state.last_destination_uniform = J(population.workers, 1, .)
    if (initial == "random") {
        employment_draws = fesim_rng_runiform(
            rng_state, "initial_states", population.workers, 1)
        destination_draws = fesim_rng_runiform(
            rng_state, "destination_draws", population.workers, 1)
        state.employed = employment_draws :< .5
        employed_rows = selectindex(state.employed :== 1)
        if (length(employed_rows)) {
            state.firm_id[employed_rows] = fesim_netdesign_sample_common(
                design, population.firm_weight, ///
                design.worker_block[employed_rows], ///
                destination_draws[employed_rows])
            state.spell_id[employed_rows] = J(length(employed_rows), 1, 1)
            state.tenure[employed_rows] = J(length(employed_rows), 1, 0)
            state.unemployment_duration[employed_rows] = ///
                J(length(employed_rows), 1, .)
            state.current_value[employed_rows] = ///
                population.worker_value[employed_rows] :+ ///
                population.firm_value[state.firm_id[employed_rows]]
        }
    }
    state.validated = 0
    fesim_state_validate(state, population)
    state.validated = 1
    return(state)
}

struct fesim_state scalar fesim_emp_advance_block(
    struct fesim_state scalar state,
    struct fesim_population scalar population,
    struct fesim_network_design scalar design,
    struct fesim_empirical_params scalar params,
    struct fesim_destination_tables scalar tables,
    struct fesim_rng_state scalar rng_state)
{
    real matrix employed_probabilities
    real colvector destination_draws
    real colvector destination_firm
    real colvector direct_current
    real colvector direct_rows
    real colvector employed_rows
    real colvector entry_rows
    real colvector event_draws
    real colvector exit_rows
    real colvector retained_employed
    real colvector stay_employed
    real colvector stay_unemployed
    real colvector unemployed_probability
    real colvector unemployed_rows

    fesim_emp_population_validate(population)
    fesim_state_validate(state, population)
    fesim_emp_params_validate(params)
    fesim_emp_tables_validate(population, tables)
    fesim_netdesign_validate(design)
    if ((design.mode != "blocks" & design.mode != "bridges") | ///
        design.prepared != 1 | ///
        tables.network_mode != design.mode | ///
        tables.block_count != design.block_count | ///
        tables.block_log_bonus != design.block_log_bonus | ///
        any(tables.firm_block :!= design.firm_block)) {
        _error(3300, "empirical block mobility design is invalid")
    }
    if (design.mode == "blocks" & design.block_log_bonus == 0) {
        return(fesim_emp_advance(
            state, population, params, tables, rng_state))
    }
    event_draws = fesim_rng_runiform(
        rng_state, "mobility_events", population.workers, 1)
    destination_draws = fesim_rng_runiform(
        rng_state, "destination_draws", population.workers, 1)
    state.last_destination_uniform = destination_draws
    employed_rows = selectindex(state.employed :== 1)
    unemployed_rows = selectindex(state.employed :== 0)
    exit_rows = J(0, 1, .)
    direct_rows = J(0, 1, .)
    stay_employed = J(0, 1, .)
    entry_rows = J(0, 1, .)
    stay_unemployed = J(0, 1, .)
    if (length(employed_rows)) {
        employed_probabilities = fesim_hazard_competing_from_log(
            fesim_hazard_employed_log(params.kappa_eu, ///
                params.eu_worker, population.worker_mobility[employed_rows], ///
                params.eu_firm, ///
                population.firm_quality[state.firm_id[employed_rows]], ///
                params.eu_duration, state.tenure[employed_rows]), ///
            fesim_hazard_employed_log(params.kappa_ee, ///
                params.ee_worker, population.worker_mobility[employed_rows], ///
                params.ee_firm, ///
                population.firm_quality[state.firm_id[employed_rows]], ///
                params.ee_duration, state.tenure[employed_rows]), ///
            fesim_emp_month_years())
        exit_rows = fesim_emp_select_rows(employed_rows, ///
            event_draws[employed_rows] :< employed_probabilities[, 1])
        direct_rows = fesim_emp_select_rows(employed_rows, ///
            event_draws[employed_rows] :>= employed_probabilities[, 1] :& ///
            event_draws[employed_rows] :< ///
                employed_probabilities[, 1] :+ employed_probabilities[, 2])
        stay_employed = fesim_emp_select_rows(employed_rows, ///
            event_draws[employed_rows] :>= ///
                employed_probabilities[, 1] :+ employed_probabilities[, 2])
    }
    if (length(unemployed_rows)) {
        unemployed_probability = fesim_hazard_one_from_log(
            fesim_hazard_unemployed_log(params.kappa_ue, ///
                params.ue_worker, population.worker_mobility[unemployed_rows], ///
                params.ue_duration, ///
                state.unemployment_duration[unemployed_rows]), ///
            fesim_emp_month_years())
        entry_rows = fesim_emp_select_rows(unemployed_rows, ///
            event_draws[unemployed_rows] :< unemployed_probability)
        stay_unemployed = fesim_emp_select_rows(unemployed_rows, ///
            event_draws[unemployed_rows] :>= unemployed_probability)
    }
    direct_current = state.firm_id[direct_rows]
    state.period = state.period + 1
    state.ntransitions = J(population.workers, 1, 0)
    if (length(stay_employed)) {
        state.tenure[stay_employed] = state.tenure[stay_employed] :+ ///
            fesim_emp_month_years()
    }
    if (length(stay_unemployed)) {
        state.unemployment_duration[stay_unemployed] = ///
            state.unemployment_duration[stay_unemployed] :+ ///
            fesim_emp_month_years()
    }
    if (length(exit_rows)) {
        state.employed[exit_rows] = J(length(exit_rows), 1, 0)
        state.firm_id[exit_rows] = J(length(exit_rows), 1, .)
        state.tenure[exit_rows] = J(length(exit_rows), 1, .)
        state.unemployment_duration[exit_rows] = J(length(exit_rows), 1, 0)
        state.current_value[exit_rows] = J(length(exit_rows), 1, .)
        state.ntransitions[exit_rows] = J(length(exit_rows), 1, 1)
    }
    if (length(direct_rows)) {
        destination_firm = fesim_dest_sample_ee_blocks(
            tables, population.worker_type_index[direct_rows], ///
            direct_current, destination_draws[direct_rows])
        state.firm_id[direct_rows] = destination_firm
        state.spell_id[direct_rows] = state.spell_id[direct_rows] :+ 1
        state.tenure[direct_rows] = J(length(direct_rows), 1, 0)
        state.ntransitions[direct_rows] = J(length(direct_rows), 1, 1)
    }
    if (length(entry_rows)) {
        state.employed[entry_rows] = J(length(entry_rows), 1, 1)
        state.firm_id[entry_rows] = fesim_dest_sample_ue_blocks(
            tables, population.worker_type_index[entry_rows], ///
            design.worker_block[entry_rows], destination_draws[entry_rows])
        state.spell_id[entry_rows] = state.spell_id[entry_rows] :+ 1
        state.tenure[entry_rows] = J(length(entry_rows), 1, 0)
        state.unemployment_duration[entry_rows] = J(length(entry_rows), 1, .)
        state.ntransitions[entry_rows] = J(length(entry_rows), 1, 1)
    }
    retained_employed = selectindex(state.employed :== 1)
    if (length(retained_employed)) {
        state.current_value[retained_employed] = ///
            population.worker_value[retained_employed] :+ ///
            population.firm_value[state.firm_id[retained_employed]]
    }
    fesim_state_validate(state, population)
    state.validated = 1
    return(state)
}

struct fesim_state scalar fesim_emp_burn_in_block(
    struct fesim_state scalar state,
    struct fesim_population scalar population,
    struct fesim_network_design scalar design,
    real scalar burnin_years,
    struct fesim_empirical_params scalar params,
    struct fesim_destination_tables scalar tables,
    struct fesim_rng_state scalar rng_state)
{
    real scalar month
    real scalar months

    if (missing(burnin_years) | burnin_years < 0) {
        _error(3300, "empirical block burn-in years are invalid")
    }
    months = burnin_years / fesim_emp_month_years()
    if (abs(months - floor(months + .5)) > 1e-10) {
        _error(3300, "empirical block burn-in must use whole months")
    }
    months = floor(months + .5)
    for (month = 1; month <= months; month++) {
        state = fesim_emp_advance_block(
            state, population, design, params, tables, rng_state)
    }
    return(state)
}

struct fesim_state scalar fesim_emp_advance_ladder(
    struct fesim_state scalar state,
    struct fesim_population scalar population,
    struct fesim_network_design scalar design,
    struct fesim_empirical_params scalar params,
    struct fesim_destination_tables scalar tables,
    struct fesim_rng_state scalar rng_state)
{
    real colvector direct_rows
    real colvector employed_before
    real colvector firm_before

    fesim_emp_population_validate(population)
    fesim_state_validate(state, population)
    fesim_emp_params_validate(params)
    fesim_emp_tables_validate(population, tables)
    fesim_netdesign_validate(design)
    if (design.mode != "ladder" | tables.network_mode != "random" | ///
        rows(design.firm_rank) != population.firms | ///
        max(abs(design.firm_rank :- ///
            fesim_netdesign_midranks(population.firm_value))) > 1e-12) {
        _error(3300, "stylized AKM ladder mobility design is invalid")
    }
    employed_before = state.employed
    firm_before = state.firm_id
    state = fesim_emp_advance(state, population, params, tables, rng_state)
    direct_rows = selectindex(employed_before :== 1 :& ///
        state.employed :== 1 :& firm_before :!= state.firm_id)
    if (length(direct_rows)) {
        state.firm_id[direct_rows] = fesim_net_ladder_emp(
            design, tables, population.worker_type_index[direct_rows], ///
            firm_before[direct_rows], ///
            state.last_destination_uniform[direct_rows])
        state.current_value[direct_rows] = ///
            population.worker_value[direct_rows] :+ ///
            population.firm_value[state.firm_id[direct_rows]]
    }
    fesim_state_validate(state, population)
    state.validated = 1
    return(state)
}

struct fesim_state scalar fesim_emp_burn_in_ladder(
    struct fesim_state scalar state,
    struct fesim_population scalar population,
    struct fesim_network_design scalar design,
    real scalar burnin_years,
    struct fesim_empirical_params scalar params,
    struct fesim_destination_tables scalar tables,
    struct fesim_rng_state scalar rng_state)
{
    real scalar month
    real scalar months

    if (missing(burnin_years) | burnin_years < 0) {
        _error(3300, "empirical ladder burn-in years are invalid")
    }
    months = burnin_years / fesim_emp_month_years()
    if (abs(months - floor(months + .5)) > 1e-10) {
        _error(3300, "empirical ladder burn-in must use whole months")
    }
    months = floor(months + .5)
    for (month = 1; month <= months; month++) {
        state = fesim_emp_advance_ladder(
            state, population, design, params, tables, rng_state)
    }
    return(state)
}

end
