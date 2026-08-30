version 16.0

mata:

real scalar fesim_akm_simple_schema_version()
{
    return(4)
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
    real colvector unemployment_draws
    real colvector unemployment_ages
    real colvector unemployed_rows

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
    state.unemployment_duration = J(population.workers, 1, 0)
    state.ntransitions = J(population.workers, 1, 0)
    state.current_value = J(population.workers, 1, .)
    state.last_destination_uniform = J(population.workers, 1, .)

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
            unemployment_draws = fesim_rng_runiform(
                rng_state, "initial_states", population.workers, 1)
            unemployment_ages = fesim_akm_geometric_ages(
                unemployment_draws, rates[3])
        }
        else {
            tenure_ages = J(population.workers, 1, 0)
        }
        state.employed = employment_draws :< employment_probability
        employed_rows = selectindex(state.employed :== 1)
        if (length(employed_rows)) {
            state.firm_id[employed_rows] = fesim_destination_sample_common(
                firm_probabilities, firm_draws[employed_rows])
            state.spell_id[employed_rows] = J(length(employed_rows), 1, 1)
            state.tenure[employed_rows] = tenure_ages[employed_rows]
            state.unemployment_duration[employed_rows] = ///
                J(length(employed_rows), 1, .)
            state.current_value[employed_rows] = ///
                population.worker_value[employed_rows] + ///
                population.firm_value[state.firm_id[employed_rows], 1]
        }
        if (initial == "stationary") {
            unemployed_rows = selectindex(state.employed :== 0)
            if (length(unemployed_rows)) {
                state.unemployment_duration[unemployed_rows] = ///
                    unemployment_ages[unemployed_rows]
            }
        }
    }
    state.validated = 0
    fesim_state_validate(state, population)
    state.validated = 1
    return(state)
}

struct fesim_state scalar fesim_akm_advance(
    struct fesim_state scalar state,
    struct fesim_population scalar population,
    real scalar delta_years,
    real scalar annual_eu,
    real scalar annual_ee,
    real scalar annual_ue,
    struct fesim_rng_state scalar rng_state)
{
    real rowvector rates
    real colvector destination_draws
    real colvector direct_rows
    real colvector employed_before
    real colvector entry_rows
    real colvector event_draws
    real colvector exit_rows
    real colvector retained_employed
    real colvector stay_rows
    real colvector stay_unemployed

    fesim_population_validate(population)
    fesim_state_validate(state, population)
    rates = fesim_akm_interval_rates(
        delta_years, annual_eu, annual_ee, annual_ue)
    if (rates[2] > 0 & ///
        (population.firms < 2 | max(population.firm_weight) >= 1)) {
        _error(3300, "direct job moves require another positive-weight firm")
    }

    event_draws = fesim_rng_runiform(
        rng_state, "mobility_events", population.workers, 1)
    destination_draws = fesim_rng_runiform(
        rng_state, "destination_draws", population.workers, 1)
    state.last_destination_uniform = destination_draws
    employed_before = state.employed
    entry_rows = selectindex(employed_before :== 0 :& ///
        event_draws :< rates[3])
    exit_rows = selectindex(employed_before :== 1 :& ///
        event_draws :< rates[1])
    direct_rows = selectindex(employed_before :== 1 :& ///
        event_draws :>= rates[1] :& ///
        event_draws :< rates[1] + rates[2])
    stay_rows = selectindex(employed_before :== 1 :& ///
        event_draws :>= rates[1] + rates[2])
    stay_unemployed = selectindex(employed_before :== 0 :& ///
        event_draws :>= rates[3])

    state.period = state.period + 1
    state.ntransitions = J(population.workers, 1, 0)
    if (length(stay_rows)) {
        state.tenure[stay_rows] = state.tenure[stay_rows] :+ 1
    }
    if (length(stay_unemployed)) {
        state.unemployment_duration[stay_unemployed] = ///
            state.unemployment_duration[stay_unemployed] :+ 1
    }
    if (length(exit_rows)) {
        state.employed[exit_rows] = J(length(exit_rows), 1, 0)
        state.firm_id[exit_rows] = J(length(exit_rows), 1, .)
        state.tenure[exit_rows] = J(length(exit_rows), 1, .)
        state.unemployment_duration[exit_rows] = ///
            J(length(exit_rows), 1, 0)
        state.current_value[exit_rows] = J(length(exit_rows), 1, .)
        state.ntransitions[exit_rows] = J(length(exit_rows), 1, 1)
    }
    if (length(direct_rows)) {
        state.firm_id[direct_rows] = fesim_destination_sample_excl(
            population.firm_weight, state.firm_id[direct_rows], ///
            destination_draws[direct_rows])
        state.spell_id[direct_rows] = state.spell_id[direct_rows] :+ 1
        state.tenure[direct_rows] = J(length(direct_rows), 1, 0)
        state.ntransitions[direct_rows] = J(length(direct_rows), 1, 1)
    }
    if (length(entry_rows)) {
        state.employed[entry_rows] = J(length(entry_rows), 1, 1)
        state.firm_id[entry_rows] = fesim_destination_sample_common(
            population.firm_weight, destination_draws[entry_rows])
        state.spell_id[entry_rows] = state.spell_id[entry_rows] :+ 1
        state.tenure[entry_rows] = J(length(entry_rows), 1, 0)
        state.unemployment_duration[entry_rows] = ///
            J(length(entry_rows), 1, .)
        state.ntransitions[entry_rows] = J(length(entry_rows), 1, 1)
    }
    retained_employed = selectindex(state.employed :== 1)
    if (length(retained_employed)) {
        state.current_value[retained_employed] = ///
            population.worker_value[retained_employed] + ///
            population.firm_value[state.firm_id[retained_employed], 1]
    }
    fesim_state_validate(state, population)
    state.validated = 1
    return(state)
}

struct fesim_state scalar fesim_akm_burn_in(
    struct fesim_state scalar state,
    struct fesim_population scalar population,
    real scalar burnin,
    real scalar delta_years,
    real scalar annual_eu,
    real scalar annual_ee,
    real scalar annual_ue,
    struct fesim_rng_state scalar rng_state)
{
    real scalar period
    real rowvector rates

    if (missing(burnin) | burnin < 0 | burnin != floor(burnin)) {
        _error(3300, "simple AKM burn-in must be a nonnegative integer")
    }
    fesim_population_validate(population)
    fesim_state_validate(state, population)
    rates = fesim_akm_interval_rates(
        delta_years, annual_eu, annual_ee, annual_ue)
    if (rates[2] > 0 & ///
        (population.firms < 2 | max(population.firm_weight) >= 1)) {
        _error(3300, "direct job moves require another positive-weight firm")
    }
    for (period = 1; period <= burnin; period++) {
        state = fesim_akm_advance(
            state, population, delta_years, annual_eu, annual_ee, ///
            annual_ue, rng_state)
    }
    return(state)
}

string rowvector fesim_akm_wage_component_names()
{
    return(("lnwage", "alpha_true", "psi_true", "time_true", ///
        "xb_true", "match_true", "epsilon_true", "lnwage_true"))
}

string rowvector fesim_akm_wage_moment_names()
{
    return(("epsilon_mean", "epsilon_sd", "epsilon_var"))
}

real matrix fesim_akm_wage_components(
    struct fesim_state scalar state,
    struct fesim_population scalar population,
    real scalar mean_log_wage,
    real scalar error_sd,
    real scalar wage_trend,
    real scalar elapsed_years,
    struct fesim_rng_state scalar rng_state)
{
    real scalar time_component
    real colvector employed_rows
    real colvector standard_errors
    real matrix components

    fesim_population_validate(population)
    fesim_state_validate(state, population)
    if (missing(mean_log_wage) | missing(error_sd) | ///
        missing(wage_trend) | missing(elapsed_years) | ///
        error_sd < 0 | elapsed_years < 0) {
        _error(3300, "simple AKM wage inputs are invalid")
    }
    time_component = wage_trend * elapsed_years
    if (missing(time_component)) {
        _error(3300, "simple AKM time component overflowed")
    }
    standard_errors = fesim_rng_rnormal(
        rng_state, "wage_shocks", population.workers, 1, 0, 1)
    components = J(population.workers, 8, .)
    components[, 2] = population.worker_value
    components[, 4] = J(population.workers, 1, time_component)
    employed_rows = selectindex(state.employed :== 1)
    if (length(employed_rows)) {
        components[employed_rows, 3] = ///
            population.firm_value[state.firm_id[employed_rows], 1]
        components[employed_rows, 5] = J(length(employed_rows), 1, 0)
        components[employed_rows, 6] = J(length(employed_rows), 1, 0)
        components[employed_rows, 7] = ///
            error_sd :* standard_errors[employed_rows]
        components[employed_rows, 1] = mean_log_wage :+ ///
            components[employed_rows, 2] :+ ///
            components[employed_rows, 3] :+ time_component :+ ///
            components[employed_rows, 7]
        components[employed_rows, 8] = components[employed_rows, 1]
        if (any(missing(components[employed_rows, 1])) | ///
            any(missing(components[employed_rows, 7]))) {
            _error(3300, "simple AKM wage values overflowed")
        }
    }
    return(components)
}

real colvector fesim_akm_wage_moments(real matrix components)
{
    real scalar epsilon_variance
    real colvector employed_rows

    if (cols(components) != 8 | rows(components) < 1) {
        _error(3300, "simple AKM wage-component matrix is invalid")
    }
    employed_rows = selectindex(components[, 1] :< .)
    if (!length(employed_rows)) return(J(3, 1, .))
    if (any(missing(components[employed_rows, 7]))) {
        _error(3300, "employed wage components lack epsilon")
    }
    epsilon_variance = fesim_sample_variance(components[employed_rows, 7])
    return((mean(components[employed_rows, 7]) \
        sqrt(epsilon_variance) \
        epsilon_variance))
}

real colvector fesim_akm_wage_targets(real scalar error_sd)
{
    if (missing(error_sd) | error_sd < 0) {
        _error(3300, "simple AKM wage target is invalid")
    }
    return((0 \ error_sd \ error_sd ^ 2))
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
    population.worker_type_index = J(workers, 1, .)
    population.worker_mobility = J(workers, 1, .)
    population.firm_quality = J(firms, 1, .)
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

real matrix fesim_akm_block_stationary(
    struct fesim_population scalar population,
    struct fesim_network_design scalar design,
    real scalar delta_years,
    real scalar annual_eu,
    real scalar annual_ee,
    real scalar annual_ue)
{
    real scalar block
    real scalar denominator
    real scalar employment_probability
    real scalar firm
    real scalar firms
    real scalar block_firm_count
    real rowvector rates
    real colvector block_firms
    real colvector block_stationary
    real colvector rhs
    real colvector stationary_firm
    real matrix common_probability
    real matrix direct_transition
    real matrix equations
    real matrix firm_probability
    real matrix stationary

    fesim_population_validate(population)
    fesim_netdesign_validate(design)
    if ((design.mode != "blocks" & design.mode != "bridges") | ///
        design.prepared != 1 | ///
        rows(design.firm_block) != population.firms) {
        _error(3300, "simple AKM block stationary design is invalid")
    }
    rates = fesim_akm_interval_rates(
        delta_years, annual_eu, annual_ee, annual_ue)
    if (rates[1] + rates[3] == 0) {
        _error(3300, "stationary employment is not unique when EU and UE are zero")
    }
    firms = population.firms
    stationary = J(firms + 1, design.block_count, 0)
    if (rates[3] == 0) {
        stationary[1, .] = J(1, design.block_count, 1)
        return(stationary)
    }
    employment_probability = rates[3] / (rates[1] + rates[3])
    common_probability = J(firms, design.block_count, .)
    for (block = 1; block <= design.block_count; block++) {
        common_probability[, block] = ///
            fesim_netdesign_common_probs(design, block)
    }
    if (rates[1] == 0 & rates[2] == 0) {
        firm_probability = common_probability
    }
    else {
        direct_transition = J(firms, firms, .)
        for (firm = 1; firm <= firms; firm++) {
            direct_transition[firm, .] = fesim_netdesign_excl_probs(
                design, design.firm_block[firm], firm)'
        }
        if (rates[1] > 0) {
            denominator = rates[1] + rates[2]
            equations = I(firms) - ///
                (rates[2] / denominator) :* direct_transition'
            firm_probability = qrsolve(equations, ///
                (rates[1] / denominator) :* common_probability)
        }
        else if (design.mode == "blocks") {
            equations = direct_transition' - I(firms)
            equations[firms, .] = J(1, firms, 1)
            rhs = J(firms, 1, 0)
            rhs[firms] = 1
            stationary_firm = qrsolve(equations, rhs)
            firm_probability = stationary_firm * ///
                J(1, design.block_count, 1)
        }
        else {
            firm_probability = J(firms, design.block_count, 0)
            for (block = 1; block <= design.block_count; block++) {
                block_firms = selectindex(design.firm_block :== block)
                block_firm_count = length(block_firms)
                equations = direct_transition[
                    block_firms, block_firms]' - I(block_firm_count)
                equations[block_firm_count, .] = ///
                    J(1, block_firm_count, 1)
                rhs = J(block_firm_count, 1, 0)
                rhs[block_firm_count] = 1
                block_stationary = qrsolve(equations, rhs)
                firm_probability[block_firms, block] = block_stationary
            }
        }
    }
    if (any(missing(firm_probability)) | min(firm_probability) < -1e-10) {
        _error(3300, "simple AKM block stationary distribution failed")
    }
    firm_probability = firm_probability :* (firm_probability :> 0)
    for (block = 1; block <= design.block_count; block++) {
        firm_probability[, block] = firm_probability[, block] / ///
            sum(firm_probability[, block])
    }
    stationary[1, .] = J(1, design.block_count, ///
        1 - employment_probability)
    stationary[2..(firms + 1), .] = ///
        employment_probability :* firm_probability
    if (max(abs(colsum(stationary) :- 1)) > 1e-10) {
        _error(3300, "simple AKM block stationary probabilities are invalid")
    }
    return(stationary)
}

real colvector fesim_akm_sample_sparse(
    real colvector probability,
    real colvector uniform_draw)
{
    real scalar draw
    real colvector destination
    real rowvector cumulative

    if (cols(probability) != 1 | rows(probability) < 1 | ///
        any(missing(probability)) | any(probability :< 0) | ///
        abs(sum(probability) - 1) > 1e-10 | ///
        cols(uniform_draw) != 1 | any(missing(uniform_draw)) | ///
        any(uniform_draw :< 0) | any(uniform_draw :>= 1)) {
        _error(3300, "sparse destination probabilities are invalid")
    }
    cumulative = runningsum(probability')
    destination = J(rows(uniform_draw), 1, .)
    for (draw = 1; draw <= rows(uniform_draw); draw++) {
        destination[draw] = fesim_destination_prefix_index(
            cumulative, cols(cumulative), uniform_draw[draw])
    }
    return(destination)
}

struct fesim_state scalar fesim_akm_initialize_block(
    struct fesim_population scalar population,
    struct fesim_network_design scalar design,
    string scalar initial,
    real scalar delta_years,
    real scalar annual_eu,
    real scalar annual_ee,
    real scalar annual_ue,
    struct fesim_rng_state scalar rng_state)
{
    struct fesim_state scalar state
    real scalar block
    real scalar employment_probability
    real rowvector rates
    real colvector block_rows
    real colvector employed_rows
    real colvector employment_draws
    real colvector firm_draws
    real colvector firm_probability
    real colvector tenure_ages
    real colvector tenure_draws
    real colvector unemployment_ages
    real colvector unemployment_draws
    real colvector unemployed_rows
    real matrix stationary

    fesim_population_validate(population)
    fesim_netdesign_validate(design)
    initial = strlower(strtrim(initial))
    if ((design.mode != "blocks" & design.mode != "bridges") | ///
        design.prepared != 1 | ///
        (initial != "stationary" & initial != "random" & ///
        initial != "allunemployed")) {
        _error(3300, "simple AKM block initialization is invalid")
    }
    if (design.mode == "blocks" & design.block_log_bonus == 0) {
        return(fesim_akm_initialize_state(population, initial, ///
            delta_years, annual_eu, annual_ee, annual_ue, rng_state))
    }
    rates = fesim_akm_interval_rates(
        delta_years, annual_eu, annual_ee, annual_ue)
    if (initial == "stationary") {
        stationary = fesim_akm_block_stationary(population, design, ///
            delta_years, annual_eu, annual_ee, annual_ue)
        employment_probability = 1 - stationary[1, 1]
    }
    else if (initial == "random") employment_probability = .5

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
            unemployment_draws = fesim_rng_runiform(
                rng_state, "initial_states", population.workers, 1)
            unemployment_ages = fesim_akm_geometric_ages(
                unemployment_draws, rates[3])
        }
        else tenure_ages = J(population.workers, 1, 0)
        state.employed = employment_draws :< employment_probability
        for (block = 1; block <= design.block_count; block++) {
            block_rows = selectindex(state.employed :== 1 :& ///
                design.worker_block :== block)
            if (length(block_rows)) {
                if (initial == "stationary") {
                    firm_probability = stationary[
                        2..rows(stationary), block] / employment_probability
                    state.firm_id[block_rows] = ///
                        fesim_akm_sample_sparse(
                            firm_probability, firm_draws[block_rows])
                }
                else {
                    state.firm_id[block_rows] = ///
                        fesim_netdesign_sample_common(design, ///
                            population.firm_weight, ///
                            J(length(block_rows), 1, block), ///
                            firm_draws[block_rows])
                }
            }
        }
        employed_rows = selectindex(state.employed :== 1)
        if (length(employed_rows)) {
            state.spell_id[employed_rows] = J(length(employed_rows), 1, 1)
            state.tenure[employed_rows] = tenure_ages[employed_rows]
            state.unemployment_duration[employed_rows] = ///
                J(length(employed_rows), 1, .)
            state.current_value[employed_rows] = ///
                population.worker_value[employed_rows] + ///
                population.firm_value[state.firm_id[employed_rows], 1]
        }
        if (initial == "stationary") {
            unemployed_rows = selectindex(state.employed :== 0)
            if (length(unemployed_rows)) {
                state.unemployment_duration[unemployed_rows] = ///
                    unemployment_ages[unemployed_rows]
            }
        }
    }
    state.validated = 0
    fesim_state_validate(state, population)
    state.validated = 1
    return(state)
}

struct fesim_state scalar fesim_akm_advance_block(
    struct fesim_state scalar state,
    struct fesim_population scalar population,
    struct fesim_network_design scalar design,
    real scalar delta_years,
    real scalar annual_eu,
    real scalar annual_ee,
    real scalar annual_ue,
    struct fesim_rng_state scalar rng_state)
{
    real rowvector rates
    real colvector current_firm
    real colvector destination_draws
    real colvector destination_firm
    real colvector direct_rows
    real colvector employed_before
    real colvector entry_rows
    real colvector event_draws
    real colvector exit_rows
    real colvector retained_employed
    real colvector stay_rows
    real colvector stay_unemployed

    fesim_population_validate(population)
    fesim_state_validate(state, population)
    fesim_netdesign_validate(design)
    if ((design.mode != "blocks" & design.mode != "bridges") | ///
        design.prepared != 1) {
        _error(3300, "simple AKM block mobility design is invalid")
    }
    if (design.mode == "blocks" & design.block_log_bonus == 0) {
        return(fesim_akm_advance(state, population, delta_years, ///
            annual_eu, annual_ee, annual_ue, rng_state))
    }
    rates = fesim_akm_interval_rates(
        delta_years, annual_eu, annual_ee, annual_ue)
    event_draws = fesim_rng_runiform(
        rng_state, "mobility_events", population.workers, 1)
    destination_draws = fesim_rng_runiform(
        rng_state, "destination_draws", population.workers, 1)
    state.last_destination_uniform = destination_draws
    employed_before = state.employed
    entry_rows = selectindex(employed_before :== 0 :& ///
        event_draws :< rates[3])
    exit_rows = selectindex(employed_before :== 1 :& ///
        event_draws :< rates[1])
    direct_rows = selectindex(employed_before :== 1 :& ///
        event_draws :>= rates[1] :& ///
        event_draws :< rates[1] + rates[2])
    stay_rows = selectindex(employed_before :== 1 :& ///
        event_draws :>= rates[1] + rates[2])
    stay_unemployed = selectindex(employed_before :== 0 :& ///
        event_draws :>= rates[3])
    current_firm = state.firm_id[direct_rows]

    state.period = state.period + 1
    state.ntransitions = J(population.workers, 1, 0)
    if (length(stay_rows)) state.tenure[stay_rows] = state.tenure[stay_rows] :+ 1
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
        destination_firm = fesim_netdesign_sample_excl(
            design, population.firm_weight, ///
            design.firm_block[current_firm], current_firm, ///
            destination_draws[direct_rows])
        state.firm_id[direct_rows] = destination_firm
        state.spell_id[direct_rows] = state.spell_id[direct_rows] :+ 1
        state.tenure[direct_rows] = J(length(direct_rows), 1, 0)
        state.ntransitions[direct_rows] = J(length(direct_rows), 1, 1)
    }
    if (length(entry_rows)) {
        state.employed[entry_rows] = J(length(entry_rows), 1, 1)
        state.firm_id[entry_rows] = fesim_netdesign_sample_common(
            design, population.firm_weight, ///
            design.worker_block[entry_rows], destination_draws[entry_rows])
        state.spell_id[entry_rows] = state.spell_id[entry_rows] :+ 1
        state.tenure[entry_rows] = J(length(entry_rows), 1, 0)
        state.unemployment_duration[entry_rows] = J(length(entry_rows), 1, .)
        state.ntransitions[entry_rows] = J(length(entry_rows), 1, 1)
    }
    retained_employed = selectindex(state.employed :== 1)
    if (length(retained_employed)) {
        state.current_value[retained_employed] = ///
            population.worker_value[retained_employed] + ///
            population.firm_value[state.firm_id[retained_employed], 1]
    }
    fesim_state_validate(state, population)
    state.validated = 1
    return(state)
}

struct fesim_state scalar fesim_akm_burn_in_block(
    struct fesim_state scalar state,
    struct fesim_population scalar population,
    struct fesim_network_design scalar design,
    real scalar burnin,
    real scalar delta_years,
    real scalar annual_eu,
    real scalar annual_ee,
    real scalar annual_ue,
    struct fesim_rng_state scalar rng_state)
{
    real scalar period

    if (missing(burnin) | burnin < 0 | burnin != floor(burnin)) {
        _error(3300, "simple AKM block burn-in must be a nonnegative integer")
    }
    for (period = 1; period <= burnin; period++) {
        state = fesim_akm_advance_block(state, population, design, ///
            delta_years, annual_eu, annual_ee, annual_ue, rng_state)
    }
    return(state)
}

end
