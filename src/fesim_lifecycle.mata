version 16.0

mata:

struct fesim_config scalar fesim_toy_config(
    real scalar workers,
    real scalar firms,
    real scalar periods)
{
    struct fesim_config scalar config

    config.schema_version = fesim_config_schema_version()
    config.dgp = "_toy"
    config.preset = "deterministic"
    config.calibration_class = "internal_test"
    config.workers = workers
    config.firms = firms
    config.periods = periods
    config.frequency = "year"
    config.start = "2000"
    config.start_value = 40
    config.end_value = config.start_value + periods - 1
    config.delta_years = 1
    config.time_format = "%ty"
    config.internal_clock = "output_period"
    config.seed = "none"
    config.initial = "deterministic"
    config.burnin = 0
    config.jobrule = "end"
    config.truth = "none"
    config.connectivity = "keep"
    config.report = "noreport"
    config.parameter_names = J(1, 0, "")
    config.parameter_values = J(1, 0, .)
    config.serialized = "dgp=_toy preset=deterministic"
    config.validated = 0
    fesim_config_validate(config)
    config.validated = 1
    return(config)
}

void fesim_config_validate(struct fesim_config scalar config)
{
    if (config.schema_version != fesim_config_schema_version()) {
        _error(3300, "unsupported fesim configuration schema")
    }
    if (strtrim(config.dgp) == "" | strtrim(config.preset) == "") {
        _error(3300, "configuration requires dgp and preset")
    }
    if (missing(config.workers) | missing(config.firms) | ///
        missing(config.periods) | config.workers < 1 | config.firms < 1 | ///
        config.periods < 1 | config.workers != floor(config.workers) | ///
        config.firms != floor(config.firms) | ///
        config.periods != floor(config.periods)) {
        _error(3300, "configuration counts must be positive integers")
    }
    if (config.workers * config.periods > 2147483647) {
        _error(3300, "configuration exceeds the supported observation count")
    }
    if (missing(config.delta_years) | config.delta_years <= 0 | ///
        missing(config.start_value) | missing(config.end_value) | ///
        config.end_value != config.start_value + config.periods - 1 | ///
        missing(config.burnin) | config.burnin < 0 | ///
        config.burnin != floor(config.burnin)) {
        _error(3300, "configuration time metadata are invalid")
    }
    if (cols(config.parameter_names) != cols(config.parameter_values)) {
        _error(3300, "configuration parameter names and values do not align")
    }
}

struct fesim_population scalar fesim_toy_generate_population(
    struct fesim_config scalar config)
{
    struct fesim_population scalar population

    fesim_config_validate(config)
    population.schema_version = fesim_population_schema_version()
    population.workers = config.workers
    population.firms = config.firms
    population.worker_id = (1::config.workers)
    population.firm_id = (1::config.firms)
    population.worker_value = population.worker_id / 100
    population.firm_value = population.firm_id / 10
    population.firm_weight = J(config.firms, 1, 1 / config.firms)
    population.worker_type_index = J(config.workers, 1, .)
    population.worker_mobility = J(config.workers, 1, .)
    population.firm_quality = J(config.firms, 1, .)
    population.validated = 0
    fesim_population_validate(population)
    population.validated = 1
    return(population)
}

void fesim_population_validate(struct fesim_population scalar population)
{
    real scalar firm_quality_missing
    real scalar worker_mobility_missing

    if (population.schema_version != fesim_population_schema_version()) {
        _error(3300, "unsupported fesim population schema")
    }
    if (missing(population.workers) | missing(population.firms) | ///
        population.workers < 1 | population.firms < 1 | ///
        population.workers != floor(population.workers) | ///
        population.firms != floor(population.firms) | ///
        rows(population.worker_id) != population.workers | ///
        rows(population.worker_value) != population.workers | ///
        rows(population.worker_type_index) != population.workers | ///
        rows(population.worker_mobility) != population.workers | ///
        rows(population.firm_id) != population.firms | ///
        rows(population.firm_value) != population.firms | ///
        rows(population.firm_weight) != population.firms | ///
        rows(population.firm_quality) != population.firms) {
        _error(3300, "population dimensions do not match their declared sizes")
    }
    if (any(population.worker_id :!= (1::population.workers)) | ///
        any(population.firm_id :!= (1::population.firms)) | ///
        any(missing(population.worker_value)) | ///
        any(missing(population.firm_value)) | ///
        any(missing(population.firm_weight)) | ///
        any(population.firm_weight :< 0) | ///
        abs(sum(population.firm_weight) - 1) > 1e-12) {
        _error(3300, "population identifiers, values, or weights are invalid")
    }
    worker_mobility_missing = ///
        all(missing(population.worker_type_index)) & ///
        all(missing(population.worker_mobility))
    if (!worker_mobility_missing & ///
        (any(missing(population.worker_type_index)) | ///
        any(population.worker_type_index :< 1) | ///
        any(population.worker_type_index :> 5) | ///
        any(population.worker_type_index :!= ///
            floor(population.worker_type_index)) | ///
        any(missing(population.worker_mobility)))) {
        _error(3300, "population worker mobility types are invalid")
    }
    firm_quality_missing = all(missing(population.firm_quality))
    if (!firm_quality_missing & any(missing(population.firm_quality))) {
        _error(3300, "population firm quality is invalid")
    }
}

struct fesim_state scalar fesim_toy_initialize_state(
    struct fesim_population scalar population)
{
    struct fesim_state scalar state

    fesim_population_validate(population)
    state.schema_version = fesim_state_schema_version()
    state.period = 1
    state.employed = J(population.workers, 1, 1)
    state.firm_id = 1 :+ mod(population.worker_id :- 1, population.firms)
    state.spell_id = J(population.workers, 1, 1)
    state.tenure = J(population.workers, 1, 0)
    state.unemployment_duration = J(population.workers, 1, .)
    state.ntransitions = J(population.workers, 1, 0)
    state.current_value = population.worker_value + ///
        population.firm_value[state.firm_id, 1]
    state.validated = 0
    fesim_state_validate(state, population)
    state.validated = 1
    return(state)
}

void fesim_state_validate(
    struct fesim_state scalar state,
    struct fesim_population scalar population)
{
    real colvector unemployed
    real colvector employed

    if (state.schema_version != fesim_state_schema_version()) {
        _error(3300, "unsupported fesim dynamic-state schema")
    }
    if (missing(state.period) | state.period < 1 | ///
        state.period != floor(state.period) | ///
        rows(state.employed) != population.workers | ///
        rows(state.firm_id) != population.workers | ///
        rows(state.spell_id) != population.workers | ///
        rows(state.tenure) != population.workers | ///
        rows(state.unemployment_duration) != population.workers | ///
        rows(state.ntransitions) != population.workers | ///
        rows(state.current_value) != population.workers | ///
        any(state.employed :!= 0 :& state.employed :!= 1) | ///
        any(missing(state.spell_id)) | any(state.spell_id :< 0) | ///
        any(state.spell_id :!= floor(state.spell_id)) | ///
        any(missing(state.ntransitions)) | any(state.ntransitions :< 0) | ///
        any(state.ntransitions :!= floor(state.ntransitions))) {
        _error(3300, "dynamic-state dimensions or employment indicators are invalid")
    }
    unemployed = selectindex(state.employed :== 0)
    employed = selectindex(state.employed :== 1)
    if (length(unemployed) & ///
        (any(!missing(state.firm_id[unemployed])) | ///
        any(!missing(state.current_value[unemployed])) | ///
        any(!missing(state.tenure[unemployed])) | ///
        any(missing(state.unemployment_duration[unemployed])) | ///
        any(state.unemployment_duration[unemployed] :< 0))) {
        _error(3300, "nonemployed toy states must have missing firm and value")
    }
    if (length(employed) & ///
        (any(state.firm_id[employed] :< 1) | ///
        any(state.firm_id[employed] :> population.firms) | ///
        any(state.spell_id[employed] :< 1) | ///
        any(missing(state.current_value[employed])) | ///
        any(missing(state.tenure[employed])) | ///
        any(state.tenure[employed] :< 0) | ///
        any(!missing(state.unemployment_duration[employed])))) {
        _error(3300, "employed toy states have invalid firm or value")
    }
}

struct fesim_config scalar fesim_toy_solve(
    struct fesim_config scalar config)
{
    fesim_config_validate(config)
    return(config)
}

struct fesim_state scalar fesim_toy_advance(
    struct fesim_state scalar state,
    struct fesim_population scalar population)
{
    real scalar i
    real scalar code

    fesim_state_validate(state, population)
    state.period = state.period + 1
    state.ntransitions = J(population.workers, 1, 0)
    for (i = 1; i <= population.workers; i++) {
        code = mod(population.worker_id[i] + state.period, 6)
        if (state.employed[i] & code == 0) {
            state.employed[i] = 0
            state.firm_id[i] = .
            state.tenure[i] = .
            state.unemployment_duration[i] = 0
            state.current_value[i] = .
            state.ntransitions[i] = 1
        }
        else if (!state.employed[i] & code == 1) {
            state.employed[i] = 1
            state.firm_id[i] = 1 + mod(population.worker_id[i] + ///
                state.period, population.firms)
            state.spell_id[i] = state.spell_id[i] + 1
            state.tenure[i] = 0
            state.unemployment_duration[i] = .
            state.current_value[i] = population.worker_value[i] + ///
                population.firm_value[state.firm_id[i], 1]
            state.ntransitions[i] = 1
        }
        else if (state.employed[i]) {
            state.tenure[i] = state.tenure[i] + 1
            if (code == 2 & population.firms > 1) {
                state.firm_id[i] = 1 + mod(state.firm_id[i], population.firms)
                state.spell_id[i] = state.spell_id[i] + 1
                state.tenure[i] = 0
                state.ntransitions[i] = 1
            }
            state.current_value[i] = population.worker_value[i] + ///
                population.firm_value[state.firm_id[i], 1]
        }
        else {
            state.unemployment_duration[i] = ///
                state.unemployment_duration[i] + 1
        }
    }
    fesim_state_validate(state, population)
    state.validated = 1
    return(state)
}

struct fesim_state scalar fesim_toy_burn_in(
    struct fesim_state scalar state,
    struct fesim_population scalar population,
    real scalar burnin)
{
    real scalar i

    if (burnin < 0 | burnin != floor(burnin)) {
        _error(3300, "toy burn-in must be a nonnegative integer")
    }
    for (i = 1; i <= burnin; i++) {
        state = fesim_toy_advance(state, population)
    }
    return(state)
}

real matrix fesim_toy_observe(
    struct fesim_state scalar state,
    struct fesim_population scalar population,
    real scalar output_period)
{
    real matrix observed
    real colvector unemployed

    fesim_state_validate(state, population)
    observed = J(population.workers, 8, .)
    observed[, 1] = population.worker_id
    observed[, 2] = J(population.workers, 1, output_period)
    observed[, 3] = state.firm_id
    observed[, 4] = state.employed
    observed[, 5] = state.current_value
    observed[, 6] = state.spell_id
    observed[, 7] = state.tenure
    observed[, 8] = state.ntransitions
    unemployed = selectindex(state.employed :== 0)
    if (length(unemployed)) {
        observed[unemployed, 6] = J(length(unemployed), 1, .)
    }
    return(observed)
}

struct fesim_results scalar fesim_results_new(
    struct fesim_config scalar config)
{
    struct fesim_results scalar results

    results.schema_version = fesim_results_schema_version()
    results.status = "initialized"
    results.lifecycle = ""
    results.N = config.workers * config.periods
    results.workers = config.workers
    results.firms = config.firms
    results.periods = config.periods
    results.parameters = config.parameter_values
    results.targets = J(1, 0, .)
    results.moments = J(1, 0, .)
    results.metadata_names = J(1, 0, "")
    results.metadata_values = J(1, 0, "")
    results.observed = J(results.N, 8, .)
    results.validated = 0
    return(results)
}

struct fesim_results scalar fesim_toy_finalize_flows(
    struct fesim_results scalar results)
{
    real matrix flows

    flows = fesim_finalize_flows(results.observed, results.periods)
    if (rows(flows) != results.N | cols(flows) != 5) {
        _error(3300, "toy flow finalization returned invalid dimensions")
    }
    results.status = "flows_finalized"
    return(results)
}

struct fesim_results scalar fesim_toy_compute_moments(
    struct fesim_results scalar results)
{
    real colvector employed_rows
    real scalar mean_value

    employed_rows = selectindex(results.observed[, 4] :== 1)
    mean_value = .
    if (length(employed_rows)) {
        mean_value = mean(results.observed[employed_rows, 5])
    }
    results.moments = (mean(results.observed[, 4]), mean_value)
    results.status = "moments_computed"
    return(results)
}

struct fesim_results scalar fesim_toy_metadata(
    struct fesim_results scalar results,
    struct fesim_config scalar config)
{
    results.metadata_names = ("dgp", "preset", "internal_clock")
    results.metadata_values = (config.dgp, config.preset, config.internal_clock)
    results.status = "metadata_complete"
    return(results)
}

void fesim_results_validate(struct fesim_results scalar results)
{
    real colvector expected_worker
    real colvector expected_period

    if (results.schema_version != fesim_results_schema_version() | ///
        results.N != results.workers * results.periods | ///
        rows(results.observed) != results.N | cols(results.observed) != 8) {
        _error(3300, "fesim results dimensions are invalid")
    }
    expected_worker = 1 :+ floor((0::(results.N - 1)) / results.periods)
    expected_period = 1 :+ mod((0::(results.N - 1)), results.periods)
    if (any(results.observed[, 1] :!= expected_worker) | ///
        any(results.observed[, 2] :!= expected_period) | ///
        cols(results.metadata_names) != cols(results.metadata_values)) {
        _error(3300, "fesim results keys or metadata are invalid")
    }
}

end
