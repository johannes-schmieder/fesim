version 16.0

mata:

real scalar fesim_akm_simple_schema_version()
{
    return(1)
}

string rowvector fesim_akm_pop_moment_names()
{
    return(("alpha_mean", "alpha_sd", "alpha_var", ///
        "psi_mean", "psi_sd", "psi_var", ///
        "firm_weight_min", "firm_weight_max", "firm_weight_hhi"))
}

real colvector fesim_akm_stable_weights(
    real colvector standard_draws,
    real scalar log_weight_sd)
{
    real scalar firm
    real scalar gap
    real scalar largest_draw
    real colvector log_weights
    real colvector weights

    if (rows(standard_draws) < 1 | any(missing(standard_draws)) | ///
        missing(log_weight_sd) | log_weight_sd < 0) {
        _error(3300, "firm attraction inputs are invalid")
    }
    if (log_weight_sd == 0) {
        return(J(rows(standard_draws), 1, 1 / rows(standard_draws)))
    }

    largest_draw = max(standard_draws)
    log_weights = J(rows(standard_draws), 1, 0)
    for (firm = 1; firm <= rows(standard_draws); firm++) {
        gap = largest_draw - standard_draws[firm]
        if (gap > 0) {
            if (log_weight_sd > 700 / gap) log_weights[firm] = -700
            else log_weights[firm] = -log_weight_sd * gap
        }
    }
    weights = exp(log_weights)
    return(weights / sum(weights))
}

real rowvector fesim_akm_interval_rates(
    real scalar delta_years,
    real scalar annual_eu,
    real scalar annual_ee,
    real scalar annual_ue)
{
    real rowvector employed_rates

    employed_rates = fesim_rate_competing_to_interval(
        annual_eu, annual_ee, delta_years)
    return((employed_rates[1], employed_rates[2], ///
        fesim_rate_annual_to_interval(annual_ue, delta_years), ///
        employed_rates[3]))
}

real matrix fesim_akm_transition_matrix(
    struct fesim_population scalar population,
    real scalar delta_years,
    real scalar annual_eu,
    real scalar annual_ee,
    real scalar annual_ue)
{
    real scalar denominator
    real scalar firm
    real scalar destination
    real scalar states
    real rowvector rates
    real matrix transition

    fesim_population_validate(population)
    rates = fesim_akm_interval_rates(
        delta_years, annual_eu, annual_ee, annual_ue)
    if (population.firms == 1 & rates[2] > 0) {
        _error(3300, "direct job moves require at least two firms")
    }

    states = population.firms + 1
    transition = J(states, states, 0)
    transition[1, 1] = 1 - rates[3]
    transition[1, 2..states] = rates[3] :* population.firm_weight'
    for (firm = 1; firm <= population.firms; firm++) {
        transition[firm + 1, 1] = rates[1]
        transition[firm + 1, firm + 1] = rates[4]
        if (rates[2] > 0) {
            denominator = 1 - population.firm_weight[firm]
            if (denominator <= 0) {
                _error(3300, "firm weights do not admit another destination")
            }
            for (destination = 1; destination <= population.firms; ///
                destination++) {
                if (destination != firm) {
                    transition[firm + 1, destination + 1] = rates[2] * ///
                        population.firm_weight[destination] / denominator
                }
            }
        }
    }
    if (max(abs(rowsum(transition) :- 1)) > 1e-12 | ///
        any(transition :< 0) | any(missing(transition))) {
        _error(3300, "simple AKM transition matrix is invalid")
    }
    return(transition)
}

real colvector fesim_akm_stationary_probs(
    struct fesim_population scalar population,
    real scalar delta_years,
    real scalar annual_eu,
    real scalar annual_ee,
    real scalar annual_ue)
{
    real scalar index
    real scalar states
    real rowvector rates
    real colvector rhs
    real colvector stationary
    real matrix equations
    real matrix transition

    fesim_population_validate(population)
    rates = fesim_akm_interval_rates(
        delta_years, annual_eu, annual_ee, annual_ue)
    if (rates[1] + rates[3] == 0) {
        _error(3300, "stationary employment is not unique when EU and UE are zero")
    }
    if (rates[3] == 0) {
        return((1 \ J(population.firms, 1, 0)))
    }
    if (rates[1] == 0 & rates[2] == 0) {
        return((0 \ population.firm_weight))
    }

    transition = fesim_akm_transition_matrix(
        population, delta_years, annual_eu, annual_ee, annual_ue)
    states = rows(transition)
    equations = transition' - I(states)
    equations[states, ] = J(1, states, 1)
    rhs = J(states, 1, 0)
    rhs[states] = 1
    stationary = qrsolve(equations, rhs)
    if (any(missing(stationary)) | min(stationary) < -1e-10) {
        _error(3300, "simple AKM stationary distribution could not be solved")
    }
    for (index = 1; index <= states; index++) {
        if (stationary[index] < 0) stationary[index] = 0
    }
    stationary = stationary / sum(stationary)
    if (max(abs(transition' * stationary - stationary)) > 1e-10) {
        _error(3300, "simple AKM stationary distribution failed validation")
    }
    return(stationary)
}

real colvector fesim_akm_draw_categories(
    real colvector probabilities,
    real colvector draws)
{
    real scalar category
    real scalar cumulative
    real scalar draw
    real colvector selected

    if (rows(probabilities) < 1 | any(missing(probabilities)) | ///
        any(probabilities :< 0) | ///
        abs(sum(probabilities) - 1) > 1e-12 | ///
        any(missing(draws)) | any(draws :< 0) | any(draws :>= 1)) {
        _error(3300, "categorical-draw inputs are invalid")
    }
    selected = J(rows(draws), 1, .)
    for (draw = 1; draw <= rows(draws); draw++) {
        category = 1
        cumulative = probabilities[1]
        while (draws[draw] >= cumulative & ///
            category < rows(probabilities)) {
            category++
            cumulative = cumulative + probabilities[category]
        }
        selected[draw] = category
    }
    return(selected)
}

real colvector fesim_akm_geometric_ages(
    real colvector draws,
    real scalar exit_probability)
{
    if (missing(exit_probability) | exit_probability < 0 | ///
        exit_probability >= 1 | any(missing(draws)) | ///
        any(draws :< 0) | any(draws :>= 1)) {
        _error(3300, "stationary-tenure inputs are invalid")
    }
    if (exit_probability == 0) return(J(rows(draws), 1, 0))
    return(floor(ln(1 :- draws) / ln(1 - exit_probability)))
}

struct fesim_state scalar fesim_akm_initialize_state(
    struct fesim_population scalar population,
    string scalar initial,
    real scalar delta_years,
    real scalar annual_eu,
    real scalar annual_ee,
    real scalar annual_ue,
    struct fesim_rng_state scalar rng_state)
{
    struct fesim_state scalar state
    real scalar employment_probability
    real rowvector rates
    real colvector employed_rows
    real colvector employment_draws
    real colvector firm_draws
    real colvector firm_probabilities
    real colvector state_probabilities
    real colvector tenure_draws
    real colvector tenure_ages

    fesim_population_validate(population)
    initial = strlower(strtrim(initial))
    if (initial != "stationary" & initial != "random" & ///
        initial != "allunemployed") {
        _error(3300, "simple AKM initial state is unknown")
    }
    rates = fesim_akm_interval_rates(
        delta_years, annual_eu, annual_ee, annual_ue)
    if (rates[2] > 0 & ///
        (population.firms < 2 | max(population.firm_weight) >= 1)) {
        _error(3300, "direct job moves require another positive-weight firm")
    }
    if (initial == "stationary") {
        state_probabilities = fesim_akm_stationary_probs(
            population, delta_years, annual_eu, annual_ee, annual_ue)
        employment_probability = 1 - state_probabilities[1]
        if (employment_probability > 0) {
            firm_probabilities = state_probabilities[2..rows(state_probabilities)] / ///
                employment_probability
        }
    }
    else if (initial == "random") {
        employment_probability = .5
        firm_probabilities = population.firm_weight
    }

    state.schema_version = fesim_state_schema_version()
    state.period = 1
    state.employed = J(population.workers, 1, 0)
    state.firm_id = J(population.workers, 1, .)
    state.spell_id = J(population.workers, 1, 0)
    state.tenure = J(population.workers, 1, .)
    state.ntransitions = J(population.workers, 1, 0)
    state.current_value = J(population.workers, 1, .)

    if (initial != "allunemployed") {
        employment_draws = fesim_rng_runiform(
            rng_state, "initial_states", population.workers, 1)
        firm_draws = fesim_rng_runiform(
            rng_state, "destination_draws", population.workers, 1)
        if (initial == "stationary") {
            tenure_draws = fesim_rng_runiform(
                rng_state, "initial_states", population.workers, 1)
            tenure_ages = fesim_akm_geometric_ages(
                tenure_draws, rates[1] + rates[2])
        }
        else {
            tenure_ages = J(population.workers, 1, 0)
        }
        state.employed = employment_draws :< employment_probability
        employed_rows = selectindex(state.employed :== 1)
        if (length(employed_rows)) {
            state.firm_id[employed_rows] = fesim_akm_draw_categories(
                firm_probabilities, firm_draws[employed_rows])
            state.spell_id[employed_rows] = J(length(employed_rows), 1, 1)
            state.tenure[employed_rows] = tenure_ages[employed_rows]
            state.current_value[employed_rows] = ///
                population.worker_value[employed_rows] + ///
                population.firm_value[state.firm_id[employed_rows]]
        }
    }
    state.validated = 0
    fesim_state_validate(state, population)
    state.validated = 1
    return(state)
}

struct fesim_population scalar fesim_akm_generate_population(
    real scalar workers,
    real scalar firms,
    real scalar worker_sd,
    real scalar firm_sd,
    real scalar firm_size_sd,
    struct fesim_rng_state scalar rng_state)
{
    struct fesim_population scalar population
    real colvector attraction_standard
    real colvector firm_standard
    real colvector worker_standard

    if (missing(workers) | missing(firms) | workers < 1 | firms < 1 | ///
        workers != floor(workers) | firms != floor(firms) | ///
        missing(worker_sd) | missing(firm_sd) | missing(firm_size_sd) | ///
        worker_sd < 0 | firm_sd < 0 | firm_size_sd < 0) {
        _error(3300, "simple AKM population inputs are invalid")
    }

    worker_standard = fesim_rng_rnormal(
        rng_state, "worker_primitives", workers, 1, 0, 1)
    firm_standard = fesim_rng_rnormal(
        rng_state, "firm_primitives", firms, 1, 0, 1)
    attraction_standard = fesim_rng_rnormal(
        rng_state, "firm_primitives", firms, 1, 0, 1)

    population.schema_version = fesim_population_schema_version()
    population.workers = workers
    population.firms = firms
    population.worker_id = (1::workers)
    population.firm_id = (1::firms)
    population.worker_value = worker_sd :* worker_standard
    population.firm_value = firm_sd :* firm_standard
    population.firm_weight = fesim_akm_stable_weights(
        attraction_standard, firm_size_sd)
    population.validated = 0
    fesim_population_validate(population)
    population.validated = 1
    return(population)
}

real colvector fesim_akm_population_moments(
    struct fesim_population scalar population)
{
    real scalar alpha_variance
    real scalar psi_variance

    fesim_population_validate(population)
    alpha_variance = fesim_sample_variance(population.worker_value)
    psi_variance = fesim_sample_variance(population.firm_value)
    return((mean(population.worker_value) \ sqrt(alpha_variance) \ ///
        alpha_variance \ mean(population.firm_value) \ ///
        sqrt(psi_variance) \ psi_variance \ ///
        min(population.firm_weight) \ max(population.firm_weight) \ ///
        sum(population.firm_weight :^ 2)))
}

real colvector fesim_akm_population_targets(
    real scalar worker_sd,
    real scalar firm_sd)
{
    if (missing(worker_sd) | missing(firm_sd) | ///
        worker_sd < 0 | firm_sd < 0) {
        _error(3300, "simple AKM population targets are invalid")
    }
    return((0 \ worker_sd \ worker_sd ^ 2 \ ///
        0 \ firm_sd \ firm_sd ^ 2 \ J(3, 1, .)))
}

end
