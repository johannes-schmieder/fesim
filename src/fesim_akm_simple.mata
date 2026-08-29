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
