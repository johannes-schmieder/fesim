version 16.0

mata:

real scalar fesim_paygap_schema_version()
{
    return(1)
}

real rowvector fesim_paygap_type_support()
{
    return((-2, -1, 0, 1, 2) / sqrt(2))
}

void fesim_paygap_population_validate(
    struct fesim_population scalar population)
{
    fesim_population_validate(population)
    if (any(missing(population.group)) | ///
        any(population.group :!= 0 :& population.group :!= 1) | ///
        any(missing(population.firm_alt_value)) | ///
        any(missing(population.firm_surplus)) | ///
        any(population.firm_weight :<= 0) | ///
        any(missing(population.worker_type_index)) | ///
        any(population.worker_type_index :< 1) | ///
        any(population.worker_type_index :> 5)) {
        _error(3300, "pay-gap population is invalid")
    }
}

struct fesim_population scalar fesim_paygap_gen_population(
    real scalar workers,
    real scalar firms,
    real scalar female_share,
    real scalar worker_sd_male,
    real scalar worker_sd_female,
    real scalar premium_intercept_male,
    real scalar premium_intercept_female,
    real scalar premium_loading_male,
    real scalar premium_loading_female,
    real scalar premium_deviation_sd_male,
    real scalar premium_deviation_sd_female,
    real scalar firm_size_sd,
    struct fesim_rng_state scalar rng_state)
{
    struct fesim_population scalar population
    real scalar bin
    real colvector attraction_standard
    real colvector female_draw
    real colvector female_deviation
    real colvector male_deviation
    real colvector surplus
    real colvector worker_sd
    real colvector worker_standard
    real rowvector thresholds
    real rowvector type_support

    if (missing(workers) | missing(firms) | workers < 2 | firms < 2 | ///
        workers != floor(workers) | firms != floor(firms) | ///
        missing(female_share) | female_share <= 0 | female_share >= 1 | ///
        any(missing((worker_sd_male, worker_sd_female, ///
        premium_intercept_male, premium_intercept_female, ///
        premium_loading_male, premium_loading_female, ///
        premium_deviation_sd_male, premium_deviation_sd_female, ///
        firm_size_sd))) | worker_sd_male < 0 | worker_sd_female < 0 | ///
        premium_deviation_sd_male < 0 | ///
        premium_deviation_sd_female < 0 | firm_size_sd < 0) {
        _error(3300, "pay-gap population inputs are invalid")
    }

    female_draw = fesim_rng_runiform(
        rng_state, "worker_primitives", workers, 1)
    worker_standard = fesim_rng_rnormal(
        rng_state, "worker_primitives", workers, 1, 0, 1)
    surplus = fesim_rng_rnormal(
        rng_state, "firm_primitives", firms, 1, 0, 1)
    male_deviation = fesim_rng_rnormal(
        rng_state, "firm_primitives", firms, 1, 0, 1)
    female_deviation = fesim_rng_rnormal(
        rng_state, "firm_primitives", firms, 1, 0, 1)
    attraction_standard = fesim_rng_rnormal(
        rng_state, "firm_primitives", firms, 1, 0, 1)

    population.schema_version = fesim_population_schema_version()
    population.workers = workers
    population.firms = firms
    population.worker_id = (1::workers)
    population.firm_id = (1::firms)
    population.group = female_draw :< female_share
    worker_sd = J(workers, 1, worker_sd_male)
    worker_sd[selectindex(population.group :== 1)] = ///
        J(sum(population.group :== 1), 1, worker_sd_female)
    population.worker_value = worker_sd :* worker_standard
    population.firm_surplus = surplus
    population.firm_value = premium_intercept_male :+ ///
        premium_loading_male :* surplus :+ ///
        premium_deviation_sd_male :* male_deviation
    population.firm_alt_value = premium_intercept_female :+ ///
        premium_loading_female :* surplus :+ ///
        premium_deviation_sd_female :* female_deviation
    population.firm_weight = fesim_akm_stable_weights(
        attraction_standard, firm_size_sd)
    population.firm_quality = surplus

    thresholds = invnormal((.2, .4, .6, .8))
    population.worker_type_index = J(workers, 1, 1)
    for (bin = 1; bin <= 4; bin++) {
        population.worker_type_index = population.worker_type_index :+ ///
            (worker_standard :> thresholds[bin])
    }
    type_support = fesim_paygap_type_support()
    population.worker_mobility = ///
        (type_support[population.worker_type_index])'
    population.validated = 0
    fesim_paygap_population_validate(population)
    population.validated = 1
    return(population)
}

real matrix fesim_paygap_destination_weights(
    struct fesim_population scalar population,
    real scalar group_sort_male,
    real scalar group_sort_female,
    real scalar worker_sort_male,
    real scalar worker_sort_female)
{
    real scalar column
    real scalar group
    real scalar largest
    real scalar type
    real scalar tilt
    real colvector log_weight
    real matrix weights
    real rowvector support

    fesim_paygap_population_validate(population)
    if (any(missing((group_sort_male, group_sort_female, ///
        worker_sort_male, worker_sort_female)))) {
        _error(3300, "pay-gap sorting inputs are invalid")
    }
    support = fesim_paygap_type_support()
    weights = J(population.firms, 10, .)
    for (group = 0; group <= 1; group++) {
        for (type = 1; type <= 5; type++) {
            if (group == 0) {
                tilt = group_sort_male + worker_sort_male * support[type]
            }
            else {
                tilt = group_sort_female + worker_sort_female * support[type]
            }
            log_weight = ln(population.firm_weight) :+ ///
                tilt :* population.firm_surplus
            largest = max(log_weight)
            log_weight = log_weight :- largest
            column = group * 5 + type
            weights[, column] = exp(log_weight)
            weights[, column] = weights[, column] / sum(weights[, column])
        }
    }
    if (any(missing(weights)) | any(weights :<= 0) | ///
        max(abs(colsum(weights) :- 1)) > 1e-12) {
        _error(3300, "pay-gap destination weights are invalid")
    }
    return(weights)
}

real colvector fesim_paygap_sample_common(
    real matrix weights,
    real colvector group,
    real colvector type,
    real colvector draws)
{
    real scalar cell
    real colvector destination
    real colvector rows_in_cell

    if (cols(weights) != 10 | rows(group) != rows(type) | ///
        rows(group) != rows(draws) | any(group :!= 0 :& group :!= 1) | ///
        any(type :< 1) | any(type :> 5) | any(type :!= floor(type)) | ///
        any(missing(draws)) | any(draws :< 0) | any(draws :>= 1)) {
        _error(3300, "pay-gap common destination inputs are invalid")
    }
    destination = J(rows(draws), 1, .)
    for (cell = 1; cell <= 10; cell++) {
        rows_in_cell = selectindex((group * 5 :+ type) :== cell)
        if (length(rows_in_cell)) {
            destination[rows_in_cell] = fesim_destination_sample_common(
                weights[, cell], draws[rows_in_cell])
        }
    }
    return(destination)
}

real colvector fesim_paygap_sample_excluding(
    real matrix weights,
    real colvector group,
    real colvector type,
    real colvector current_firm,
    real colvector draws)
{
    real scalar cell
    real colvector destination
    real colvector rows_in_cell

    if (cols(weights) != 10 | rows(group) != rows(type) | ///
        rows(group) != rows(current_firm) | rows(group) != rows(draws) | ///
        any(group :!= 0 :& group :!= 1) | any(type :< 1) | ///
        any(type :> 5) | any(type :!= floor(type))) {
        _error(3300, "pay-gap excluding destination inputs are invalid")
    }
    destination = J(rows(draws), 1, .)
    for (cell = 1; cell <= 10; cell++) {
        rows_in_cell = selectindex((group * 5 :+ type) :== cell)
        if (length(rows_in_cell)) {
            destination[rows_in_cell] = fesim_destination_sample_excl(
                weights[, cell], current_firm[rows_in_cell], ///
                draws[rows_in_cell])
        }
    }
    return(destination)
}

real colvector fesim_paygap_observed_premium(
    struct fesim_population scalar population,
    real colvector group,
    real colvector firm)
{
    real colvector premium
    real colvector female_rows
    real colvector male_rows

    premium = J(rows(group), 1, .)
    male_rows = selectindex(group :== 0)
    female_rows = selectindex(group :== 1)
    if (length(male_rows)) {
        premium[male_rows] = population.firm_value[firm[male_rows]]
    }
    if (length(female_rows)) {
        premium[female_rows] = ///
            population.firm_alt_value[firm[female_rows]]
    }
    return(premium)
}

struct fesim_state scalar fesim_paygap_initialize_state(
    struct fesim_population scalar population,
    real matrix weights,
    string scalar initial,
    struct fesim_rng_state scalar rng_state)
{
    struct fesim_state scalar state
    real colvector destination_draws
    real colvector employed_rows
    real colvector employment_draws

    fesim_paygap_population_validate(population)
    initial = strlower(strtrim(initial))
    if (initial != "random" & initial != "allunemployed") {
        _error(3300, "pay-gap initial state must be random or allunemployed")
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
            state.firm_id[employed_rows] = fesim_paygap_sample_common(
                weights, population.group[employed_rows], ///
                population.worker_type_index[employed_rows], ///
                destination_draws[employed_rows])
            state.spell_id[employed_rows] = J(length(employed_rows), 1, 1)
            state.tenure[employed_rows] = J(length(employed_rows), 1, 0)
            state.unemployment_duration[employed_rows] = ///
                J(length(employed_rows), 1, .)
            state.current_value[employed_rows] = ///
                population.worker_value[employed_rows] :+ ///
                fesim_paygap_observed_premium(population, ///
                    population.group[employed_rows], ///
                    state.firm_id[employed_rows])
        }
    }
    state.validated = 0
    fesim_state_validate(state, population)
    state.validated = 1
    return(state)
}

real matrix fesim_paygap_interval_rates(
    real scalar delta_years,
    real scalar p_eu_male,
    real scalar p_ee_male,
    real scalar p_ue_male,
    real scalar p_eu_female,
    real scalar p_ee_female,
    real scalar p_ue_female)
{
    real matrix rates

    rates = (fesim_akm_interval_rates(delta_years, p_eu_male, ///
        p_ee_male, p_ue_male) \ ///
        fesim_akm_interval_rates(delta_years, p_eu_female, ///
        p_ee_female, p_ue_female))
    return(rates)
}

struct fesim_state scalar fesim_paygap_advance(
    struct fesim_state scalar state,
    struct fesim_population scalar population,
    real matrix weights,
    real scalar delta_years,
    real scalar p_eu_male,
    real scalar p_ee_male,
    real scalar p_ue_male,
    real scalar p_eu_female,
    real scalar p_ee_female,
    real scalar p_ue_female,
    struct fesim_rng_state scalar rng_state)
{
    real matrix rates
    real colvector destination_draws
    real colvector direct_rows
    real colvector employed_before
    real colvector entry_rows
    real colvector event_draws
    real colvector exit_rows
    real colvector p_ee
    real colvector p_eu
    real colvector p_ue
    real colvector stay_employed
    real colvector stay_unemployed

    fesim_paygap_population_validate(population)
    fesim_state_validate(state, population)
    rates = fesim_paygap_interval_rates(delta_years, p_eu_male, ///
        p_ee_male, p_ue_male, p_eu_female, p_ee_female, p_ue_female)
    event_draws = fesim_rng_runiform(
        rng_state, "mobility_events", population.workers, 1)
    destination_draws = fesim_rng_runiform(
        rng_state, "destination_draws", population.workers, 1)
    state.last_destination_uniform = destination_draws
    p_eu = rates[1, 1] :+ population.group :* ///
        (rates[2, 1] - rates[1, 1])
    p_ee = rates[1, 2] :+ population.group :* ///
        (rates[2, 2] - rates[1, 2])
    p_ue = rates[1, 3] :+ population.group :* ///
        (rates[2, 3] - rates[1, 3])

    employed_before = state.employed
    entry_rows = selectindex(employed_before :== 0 :& event_draws :< p_ue)
    exit_rows = selectindex(employed_before :== 1 :& event_draws :< p_eu)
    direct_rows = selectindex(employed_before :== 1 :& ///
        event_draws :>= p_eu :& event_draws :< p_eu :+ p_ee)
    stay_employed = selectindex(employed_before :== 1 :& ///
        event_draws :>= p_eu :+ p_ee)
    stay_unemployed = selectindex(employed_before :== 0 :& ///
        event_draws :>= p_ue)

    state.period = state.period + 1
    state.ntransitions = J(population.workers, 1, 0)
    if (length(stay_employed)) {
        state.tenure[stay_employed] = state.tenure[stay_employed] :+ 1
    }
    if (length(stay_unemployed)) {
        state.unemployment_duration[stay_unemployed] = ///
            state.unemployment_duration[stay_unemployed] :+ 1
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
        state.firm_id[direct_rows] = fesim_paygap_sample_excluding(
            weights, population.group[direct_rows], ///
            population.worker_type_index[direct_rows], ///
            state.firm_id[direct_rows], destination_draws[direct_rows])
        state.spell_id[direct_rows] = state.spell_id[direct_rows] :+ 1
        state.tenure[direct_rows] = J(length(direct_rows), 1, 0)
        state.ntransitions[direct_rows] = J(length(direct_rows), 1, 1)
    }
    if (length(entry_rows)) {
        state.employed[entry_rows] = J(length(entry_rows), 1, 1)
        state.firm_id[entry_rows] = fesim_paygap_sample_common(
            weights, population.group[entry_rows], ///
            population.worker_type_index[entry_rows], ///
            destination_draws[entry_rows])
        state.spell_id[entry_rows] = state.spell_id[entry_rows] :+ 1
        state.tenure[entry_rows] = J(length(entry_rows), 1, 0)
        state.unemployment_duration[entry_rows] = J(length(entry_rows), 1, .)
        state.ntransitions[entry_rows] = J(length(entry_rows), 1, 1)
    }
    if (length(direct_rows) | length(entry_rows)) {
        direct_rows = direct_rows \ entry_rows
        state.current_value[direct_rows] = ///
            population.worker_value[direct_rows] :+ ///
            fesim_paygap_observed_premium(population, ///
                population.group[direct_rows], state.firm_id[direct_rows])
    }
    fesim_state_validate(state, population)
    return(state)
}

struct fesim_state scalar fesim_paygap_burn_in(
    struct fesim_state scalar state,
    struct fesim_population scalar population,
    real matrix weights,
    real scalar burnin,
    real scalar delta_years,
    real scalar p_eu_male,
    real scalar p_ee_male,
    real scalar p_ue_male,
    real scalar p_eu_female,
    real scalar p_ee_female,
    real scalar p_ue_female,
    struct fesim_rng_state scalar rng_state)
{
    real scalar period

    if (missing(burnin) | burnin < 0 | burnin != floor(burnin)) {
        _error(3300, "pay-gap burn-in must be a nonnegative integer")
    }
    for (period = 1; period <= burnin; period++) {
        state = fesim_paygap_advance(state, population, weights, ///
            delta_years, p_eu_male, p_ee_male, p_ue_male, ///
            p_eu_female, p_ee_female, p_ue_female, rng_state)
    }
    state.ntransitions = J(population.workers, 1, 0)
    return(state)
}

real matrix fesim_paygap_wage_components(
    struct fesim_state scalar state,
    struct fesim_population scalar population,
    real scalar mu_male,
    real scalar mu_female,
    real scalar error_sd_male,
    real scalar error_sd_female,
    real scalar wage_trend_male,
    real scalar wage_trend_female,
    real scalar elapsed_years,
    struct fesim_rng_state scalar rng_state)
{
    real colvector employed_rows
    real colvector error_sd
    real colvector group_mu
    real colvector standard_error
    real colvector time_component
    real matrix components

    standard_error = fesim_rng_rnormal(
        rng_state, "wage_shocks", population.workers, 1, 0, 1)
    group_mu = mu_male :+ population.group :* (mu_female - mu_male)
    error_sd = error_sd_male :+ population.group :* ///
        (error_sd_female - error_sd_male)
    time_component = elapsed_years :* (wage_trend_male :+ ///
        population.group :* (wage_trend_female - wage_trend_male))
    components = J(population.workers, 8, .)
    components[, 2] = population.worker_value
    components[, 4] = time_component
    employed_rows = selectindex(state.employed :== 1)
    if (length(employed_rows)) {
        components[employed_rows, 3] = fesim_paygap_observed_premium(
            population, population.group[employed_rows], ///
            state.firm_id[employed_rows])
        components[employed_rows, 5] = J(length(employed_rows), 1, 0)
        components[employed_rows, 6] = J(length(employed_rows), 1, 0)
        components[employed_rows, 7] = ///
            error_sd[employed_rows] :* standard_error[employed_rows]
        components[employed_rows, 1] = group_mu[employed_rows] :+ ///
            components[employed_rows, 2] :+ ///
            components[employed_rows, 3] :+ ///
            components[employed_rows, 4] :+ ///
            components[employed_rows, 7]
        components[employed_rows, 8] = components[employed_rows, 1]
    }
    return(components)
}

real scalar fesim_output_init_paygap_panel(
    real scalar workers,
    real scalar periods,
    real scalar start_value,
    string scalar time_format)
{
    real scalar requested
    real rowvector added_variables

    requested = fesim_output_initialize_panel(
        workers, periods, start_value, time_format, "full")
    added_variables = st_addvar("byte", "group")
    added_variables = st_addvar(J(1, 3, "double"), ///
        ("firm_surplus_true", "psi_male_true", "psi_female_true"))
    return(requested)
}

void fesim_output_store_paygap_period(
    struct fesim_state scalar state,
    struct fesim_population scalar population,
    real matrix wage_components,
    real scalar output_period,
    real scalar periods,
    real scalar start_value)
{
    real colvector employed_rows
    real colvector female_premium
    real colvector male_premium
    real colvector rows_to_write
    real colvector surplus
    real scalar stored

    fesim_output_store_akm_period(state, population, wage_components, ///
        output_period, periods, start_value, "full")
    rows_to_write = (0::(population.workers - 1)) :* periods :+ output_period
    stored = st_store(rows_to_write, "group", population.group)
    surplus = J(population.workers, 1, .)
    male_premium = J(population.workers, 1, .)
    female_premium = J(population.workers, 1, .)
    employed_rows = selectindex(state.employed :== 1)
    if (length(employed_rows)) {
        surplus[employed_rows] = ///
            population.firm_surplus[state.firm_id[employed_rows]]
        male_premium[employed_rows] = ///
            population.firm_value[state.firm_id[employed_rows]]
        female_premium[employed_rows] = ///
            population.firm_alt_value[state.firm_id[employed_rows]]
    }
    stored = st_store(rows_to_write, "firm_surplus_true", surplus)
    stored = st_store(rows_to_write, "psi_male_true", male_premium)
    stored = st_store(rows_to_write, "psi_female_true", female_premium)
}

void fesim_output_finalize_pg_panel()
{
    real scalar status

    st_varlabel("group", "Worker group: 0 men, 1 women")
    st_varlabel("firm_surplus_true", "True common firm-surplus index")
    st_varlabel("psi_male_true", "True male premium at observed firm")
    st_varlabel("psi_female_true", "True female premium at observed firm")
    status = stata("capture label drop fesim_group", 1)
    status = stata("label define fesim_group 0 Men 1 Women", 1)
    status = stata("label values group fesim_group", 1)
}

real scalar fesim_paygap_safe_sd(real colvector values)
{
    if (rows(values) < 2) return(.)
    return(sqrt(fesim_sample_variance(values)))
}

real scalar fesim_paygap_safe_corr(
    real colvector left,
    real colvector right)
{
    real scalar left_sd
    real scalar right_sd

    if (rows(left) < 2 | rows(left) != rows(right)) return(.)
    left_sd = fesim_paygap_safe_sd(left)
    right_sd = fesim_paygap_safe_sd(right)
    if (missing(left_sd) | missing(right_sd) | left_sd == 0 | right_sd == 0) {
        return(.)
    }
    return(fesim_sample_covariance(left, right) / (left_sd * right_sd))
}

void fesim_paygap_results_to_stata(
    real scalar periods,
    real scalar mu_male,
    real scalar mu_female,
    string scalar preset,
    string scalar truth_matrix_name,
    string scalar group_matrix_name,
    string scalar group_target_name,
    string scalar decomposition_name,
    string scalar decomposition_target_name)
{
    real scalar female
    real scalar group_rows_count
    real scalar group_worker_count
    real colvector alpha
    real colvector current_rows
    real colvector employed
    real colvector employed_rows
    real colvector epsilon
    real colvector first_rows
    real colvector from_unemp
    real colvector group
    real colvector jobtojob
    real colvector lnwage
    real colvector male_jobs
    real colvector origin_employed
    real colvector psi
    real colvector psi_female
    real colvector psi_male
    real colvector surplus
    real colvector time_component
    real colvector to_unemp
    real colvector worker_tag
    real matrix decomposition
    real matrix decomposition_targets
    real matrix group_moments
    real matrix group_targets
    real colvector truth_moments
    real scalar firm_total
    real scalar female_premium
    real scalar female_sorting
    real scalar male_premium
    real scalar male_sorting
    real scalar row
    real scalar total_gap
    real scalar worker_component
    real scalar time_gap
    real scalar residual_gap
    real scalar intercept_gap

    if (periods < 2 | periods != floor(periods)) {
        _error(3300, "pay-gap result periods are invalid")
    }
    group = st_data(., "group")
    employed = st_data(., "employed")
    lnwage = st_data(., "lnwage")
    alpha = st_data(., "alpha_true")
    psi = st_data(., "psi_true")
    epsilon = st_data(., "epsilon_true")
    time_component = st_data(., "time_true")
    surplus = st_data(., "firm_surplus_true")
    psi_male = st_data(., "psi_male_true")
    psi_female = st_data(., "psi_female_true")
    from_unemp = st_data(., "from_unemp")
    to_unemp = st_data(., "to_unemp")
    jobtojob = st_data(., "jobtojob")
    if (rows(group) < 2 | mod(rows(group), periods) | ///
        any(group :!= 0 :& group :!= 1)) {
        _error(3300, "pay-gap result panel is invalid")
    }
    worker_tag = J(rows(group), 1, 0)
    worker_tag[(0::(rows(group) / periods - 1)) :* periods :+ 1] = ///
        J(rows(group) / periods, 1, 1)
    origin_employed = J(rows(group), 1, .)
    if (periods > 1) {
        origin_employed[selectindex(worker_tag :== 0)] = ///
            employed[selectindex(worker_tag :== 0) :- 1]
    }
    group_moments = J(17, 2, .)
    for (female = 0; female <= 1; female++) {
        current_rows = selectindex(group :== female)
        employed_rows = selectindex(group :== female :& employed :== 1)
        group_rows_count = length(current_rows)
        group_worker_count = sum(group :== female :& worker_tag :== 1)
        group_moments[1, female + 1] = group_worker_count
        group_moments[2, female + 1] = length(employed_rows)
        group_moments[3, female + 1] = length(employed_rows) / group_rows_count
        if (length(employed_rows)) {
            group_moments[4, female + 1] = mean(lnwage[employed_rows])
            group_moments[5, female + 1] = ///
                fesim_paygap_safe_sd(lnwage[employed_rows])
            group_moments[6, female + 1] = mean(alpha[employed_rows])
            group_moments[7, female + 1] = ///
                fesim_paygap_safe_sd(alpha[employed_rows])
            group_moments[8, female + 1] = mean(psi[employed_rows])
            group_moments[9, female + 1] = ///
                fesim_paygap_safe_sd(psi[employed_rows])
            group_moments[10, female + 1] = mean(epsilon[employed_rows])
            group_moments[11, female + 1] = ///
                fesim_paygap_safe_sd(epsilon[employed_rows])
            group_moments[12, female + 1] = fesim_paygap_safe_corr(
                alpha[employed_rows], psi[employed_rows])
            group_moments[13, female + 1] = mean(surplus[employed_rows])
            group_moments[14, female + 1] = ///
                fesim_paygap_safe_sd(surplus[employed_rows])
        }
        current_rows = selectindex(group :== female :& employed :== 1 :& ///
            to_unemp :< .)
        if (length(current_rows)) {
            group_moments[15, female + 1] = mean(to_unemp[current_rows])
        }
        current_rows = selectindex(group :== female :& ///
            from_unemp :< . :& ///
            origin_employed :== 0)
        if (length(current_rows)) {
            group_moments[16, female + 1] = mean(from_unemp[current_rows])
        }
        current_rows = selectindex(group :== female :& ///
            jobtojob :< . :& ///
            origin_employed :== 1)
        if (length(current_rows)) {
            group_moments[17, female + 1] = mean(jobtojob[current_rows])
        }
    }
    male_jobs = selectindex(group :== 0 :& employed :== 1)
    employed_rows = selectindex(group :== 1 :& employed :== 1)
    if (!length(male_jobs) | !length(employed_rows)) {
        _error(3300, "pay-gap decomposition requires employed observations in both groups")
    }
    total_gap = mean(lnwage[male_jobs]) - mean(lnwage[employed_rows])
    intercept_gap = mu_male - mu_female
    worker_component = mean(alpha[male_jobs]) - mean(alpha[employed_rows])
    firm_total = mean(psi_male[male_jobs]) - ///
        mean(psi_female[employed_rows])
    male_sorting = mean(psi_male[male_jobs]) - ///
        mean(psi_male[employed_rows])
    male_premium = mean(psi_male[employed_rows]) - ///
        mean(psi_female[employed_rows])
    female_sorting = mean(psi_female[male_jobs]) - ///
        mean(psi_female[employed_rows])
    female_premium = mean(psi_male[male_jobs]) - ///
        mean(psi_female[male_jobs])
    time_gap = mean(time_component[male_jobs]) - ///
        mean(time_component[employed_rows])
    residual_gap = mean(epsilon[male_jobs]) - mean(epsilon[employed_rows])
    decomposition = J(9, 3, .)
    for (row = 1; row <= 3; row++) {
        decomposition[1, row] = total_gap
        decomposition[2, row] = intercept_gap
        decomposition[3, row] = worker_component
        decomposition[4, row] = firm_total
        decomposition[7, row] = time_gap
        decomposition[8, row] = residual_gap
    }
    decomposition[5, ] = (male_sorting, female_sorting, ///
        (male_sorting + female_sorting) / 2)
    decomposition[6, ] = (male_premium, female_premium, ///
        (male_premium + female_premium) / 2)
    decomposition[9, ] = decomposition[1, ] :- ///
        decomposition[2, ] :- decomposition[3, ] :- ///
        decomposition[5, ] :- decomposition[6, ] :- ///
        decomposition[7, ] :- decomposition[8, ]

    employed_rows = selectindex(employed :== 1)
    first_rows = selectindex(worker_tag :== 1)
    truth_moments = (mean(alpha[first_rows]) \ ///
        fesim_paygap_safe_sd(alpha[first_rows]) \ ///
        fesim_paygap_safe_sd(alpha[first_rows]) ^ 2 \ ///
        mean(psi[employed_rows]) \ fesim_paygap_safe_sd(psi[employed_rows]) \ ///
        fesim_paygap_safe_sd(psi[employed_rows]) ^ 2 \ ///
        mean(epsilon[employed_rows]) \ ///
        fesim_paygap_safe_sd(epsilon[employed_rows]) \ ///
        fesim_paygap_safe_sd(epsilon[employed_rows]) ^ 2 \ ///
        fesim_sample_covariance(alpha[employed_rows], psi[employed_rows]))

    group_targets = J(17, 2, .)
    decomposition_targets = J(9, 3, .)
    if (strlower(strtrim(preset)) == "cck2016") {
        group_targets[5, ] = (.554, .513)
        group_targets[7, ] = (.420, .400)
        group_targets[8, ] = (.148, .099)
        group_targets[9, ] = (.247, .213)
        group_targets[11, ] = (.143, .125)
        group_targets[12, ] = (.167, .152)
        decomposition_targets[1, ] = J(1, 3, .234)
        decomposition_targets[4, ] = J(1, 3, .049)
        decomposition_targets[5, 1] = .035
        decomposition_targets[6, 1] = .015
    }
    st_matrix(truth_matrix_name, truth_moments)
    st_matrix(group_matrix_name, group_moments)
    st_matrix(group_target_name, group_targets)
    st_matrix(decomposition_name, decomposition)
    st_matrix(decomposition_target_name, decomposition_targets)
}

end
