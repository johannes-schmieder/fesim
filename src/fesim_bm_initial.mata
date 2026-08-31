version 16.0

mata:

real scalar fesim_bm_state_schema_version()
{
    return(1)
}

real colvector fesim_bm_stationary_probs(
    struct fesim_bm_solution scalar solution,
    struct fesim_bm_firms scalar universe)
{
    real colvector probability

    if (solution.validated != 1 | universe.validated != 1) {
        _error(3300, "BM stationary probability inputs are invalid")
    }
    probability = solution.unemployment_rate \
        universe.expected_employment_mass
    if (any(missing(probability)) | any(probability :<= 0) | ///
        abs(sum(probability) - 1) > 1e-10) {
        _error(430, "BM finite stationary probabilities are invalid")
    }
    return(probability / sum(probability))
}

real colvector fesim_bm_stationary_exit_rates(
    struct fesim_bm_solution scalar solution,
    struct fesim_bm_firms scalar universe)
{
    real scalar firm, firms
    real colvector rate

    if (solution.validated != 1 | universe.validated != 1) {
        _error(3300, "BM stationary duration inputs are invalid")
    }
    firms = universe.firms
    rate = J(firms + 1, 1, .)
    rate[1] = solution.lambda_u
    for (firm = 1; firm <= firms; firm++) {
        rate[firm + 1] = solution.delta + solution.lambda_e * ///
            sum(universe.posted_wage :> universe.posted_wage[firm]) / firms
    }
    if (any(missing(rate)) | any(rate :<= 0)) {
        _error(430, "BM stationary exit rates are invalid")
    }
    return(rate)
}

void fesim_bm_state_validate(
    struct fesim_bm_firms scalar universe,
    struct fesim_bm_state scalar state)
{
    if (universe.validated != 1 | ///
        state.schema_version != fesim_bm_state_schema_version() | ///
        (state.status != "initialized" & state.status != "burned_in" & ///
            state.status != "advanced") | ///
        (state.initial_mode != "stationary" & ///
            state.initial_mode != "random" & ///
            state.initial_mode != "allunemployed") | ///
        missing(state.workers) | state.workers < 1 | ///
        state.workers != floor(state.workers) | ///
        state.firms != universe.firms | missing(state.elapsed_time) | ///
        state.elapsed_time < 0 | rows(state.ntransitions) != state.workers | ///
        cols(state.ntransitions) != 1 | ///
        any(missing(state.ntransitions)) | any(state.ntransitions :< 0) | ///
        any(state.ntransitions :!= floor(state.ntransitions))) {
        _error(3300, "BM dynamic state structure is invalid")
    }
    fesim_bm_initial_state_validate(universe, state.employed, ///
        state.firm_id, state.spell_id, state.tenure, ///
        state.unemployment_duration)
}

struct fesim_bm_state scalar fesim_bm_initialize_state(
    struct fesim_bm_solution scalar solution,
    struct fesim_bm_firms scalar universe,
    real scalar workers,
    string scalar initial_mode,
    struct fesim_rng_state scalar rng_state,
    real scalar tolerance)
{
    struct fesim_bm_state scalar state
    real scalar worker
    real colvector probability, category, state_draw, age_draw, exit_rate

    initial_mode = strlower(strtrim(initial_mode))
    if (solution.validated != 1 | universe.validated != 1 | ///
        missing(workers) | workers < 1 | workers != floor(workers) | ///
        workers > 10000000 | ///
        (initial_mode != "stationary" & initial_mode != "random" & ///
            initial_mode != "allunemployed") | ///
        rng_state.schema_version != fesim_rng_schema_version() | ///
        missing(tolerance) | tolerance <= 0 | tolerance > 1e-4) {
        _error(3300, "BM initialization controls are invalid")
    }
    fesim_bm_firms_validate(solution, universe, tolerance)
    state.schema_version = fesim_bm_state_schema_version()
    state.status = "initialized"
    state.initial_mode = initial_mode
    state.workers = workers
    state.firms = universe.firms
    state.elapsed_time = 0
    state.employed = J(workers, 1, 0)
    state.firm_id = J(workers, 1, 0)
    state.spell_id = J(workers, 1, 0)
    state.tenure = J(workers, 1, .)
    state.unemployment_duration = J(workers, 1, 0)
    state.ntransitions = J(workers, 1, 0)

    if (initial_mode != "allunemployed") {
        state_draw = fesim_rng_runiform(
            rng_state, "initial_states", workers, 1)
        if (initial_mode == "stationary") {
            probability = fesim_bm_stationary_probs(
                solution, universe)
            age_draw = fesim_rng_runiform(
                rng_state, "initial_states", workers, 1)
            exit_rate = fesim_bm_stationary_exit_rates(solution, universe)
        }
        else {
            probability = .5 \
                J(universe.firms, 1, .5 / universe.firms)
        }
        category = fesim_destination_sample_common(probability, state_draw)
        state.employed = category :> 1
        for (worker = 1; worker <= workers; worker++) {
            if (state.employed[worker]) {
                state.firm_id[worker] = category[worker] - 1
                state.spell_id[worker] = 1
                state.unemployment_duration[worker] = .
                if (initial_mode == "stationary") {
                    state.tenure[worker] = fesim_bm_exponential_wait(
                        age_draw[worker], exit_rate[category[worker]])
                }
                else state.tenure[worker] = 0
            }
            else if (initial_mode == "stationary") {
                state.unemployment_duration[worker] = ///
                    fesim_bm_exponential_wait(
                    age_draw[worker], exit_rate[1])
            }
        }
    }
    state.validated = 0
    fesim_bm_state_validate(universe, state)
    state.validated = 1
    return(state)
}

struct fesim_bm_state scalar fesim_bm_state_from_history(
    struct fesim_bm_firms scalar universe,
    struct fesim_bm_state scalar state,
    struct fesim_bm_history scalar history,
    string scalar status,
    real scalar reset_transitions,
    real scalar tolerance)
{
    if (universe.validated != 1 | state.validated != 1 | ///
        history.validated != 1 | history.workers != state.workers | ///
        history.firms != state.firms | ///
        (status != "burned_in" & status != "advanced") | ///
        (reset_transitions != 0 & reset_transitions != 1) | ///
        missing(tolerance) | tolerance <= 0 | tolerance > 1e-4 | ///
        any(history.initial_employed :!= state.employed) | ///
        any(history.initial_firm_id :!= state.firm_id) | ///
        any(history.initial_spell_id :!= state.spell_id) | ///
        mreldif(history.initial_tenure, state.tenure) > tolerance | ///
        mreldif(history.initial_unemployment_duration, ///
            state.unemployment_duration) > tolerance) {
        _error(3300, "BM state/history boundary is invalid")
    }
    state.status = status
    state.elapsed_time = state.elapsed_time + history.horizon
    state.employed = history.final_employed
    state.firm_id = history.final_firm_id
    state.spell_id = history.final_spell_id
    state.tenure = history.final_tenure
    state.unemployment_duration = history.final_unemployment_duration
    if (reset_transitions) state.ntransitions = J(state.workers, 1, 0)
    else state.ntransitions = history.final_transitions
    state.validated = 0
    fesim_bm_state_validate(universe, state)
    state.validated = 1
    return(state)
}

struct fesim_bm_state scalar fesim_bm_burn_in(
    struct fesim_bm_solution scalar solution,
    struct fesim_bm_firms scalar universe,
    struct fesim_bm_state scalar state,
    real scalar burnin,
    real scalar max_events,
    struct fesim_rng_state scalar rng_state,
    real scalar tolerance)
{
    struct fesim_bm_history scalar history

    if (state.validated != 1 | missing(burnin) | burnin < 0 | ///
        (state.initial_mode == "random" & burnin <= 0)) {
        _error(3300, "BM burn-in controls are invalid")
    }
    fesim_bm_firms_validate(solution, universe, tolerance)
    history = fesim_bm_simulate_events(solution, universe, ///
        state.employed, state.firm_id, state.spell_id, state.tenure, ///
        state.unemployment_duration, burnin, 0, max_events, rng_state, ///
        tolerance)
    return(fesim_bm_state_from_history(
        universe, state, history, "burned_in", 1, tolerance))
}

end
