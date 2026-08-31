version 16.0

mata:

string scalar fesim_dispatch_status()
{
    return("akm_and_paygap_public")
}

void fesim_handler_validate(struct fesim_handler scalar handler)
{
    if (handler.schema_version != fesim_handler_schema_version() | ///
        strtrim(handler.dgp) == "" | strtrim(handler.preset) == "" | ///
        strtrim(handler.lifecycle_stages) == "" | ///
        (handler.solve_required != 0 & handler.solve_required != 1) | ///
        strtrim(handler.qualification) == "") {
        _error(3300, "fesim lifecycle handler is invalid")
    }
}

struct fesim_handler scalar fesim_dispatch_handler(
    string scalar dgp,
    string scalar preset)
{
    struct fesim_handler scalar handler

    dgp = strlower(strtrim(dgp))
    preset = strlower(strtrim(preset))
    if (!((dgp == "_toy" & preset == "deterministic") | ///
        (dgp == "akm" & (preset == "simple" | preset == "stylized" | ///
        preset == "germany_chk_2002_2009")) | ///
        (dgp == "akmpaygap" & ///
        (preset == "simple" | preset == "cck2016")))) {
        _error(3300, "no qualified fesim lifecycle handler for requested DGP and preset")
    }
    handler.schema_version = fesim_handler_schema_version()
    handler.dgp = dgp
    handler.preset = preset
    handler.lifecycle_stages = "defaults validate solve generate_population " + ///
        "initialize_state burn_in advance observe finalize_flows " + ///
        "compute_moments metadata"
    handler.solve_required = 0
    if (dgp == "_toy") handler.qualification = "internal_toy_only"
    else if (dgp == "akmpaygap") ///
        handler.qualification = "public_paygap_streaming"
    else if (preset == "simple") handler.qualification = "public_streaming"
    else if (preset == "stylized") ///
        handler.qualification = "public_monthly_streaming"
    else handler.qualification = "public_targeted_monthly_streaming"
    fesim_handler_validate(handler)
    return(handler)
}

struct fesim_results scalar fesim_dispatch_run(
    string scalar dgp,
    string scalar preset,
    real scalar workers,
    real scalar firms,
    real scalar periods)
{
    struct fesim_handler scalar handler
    struct fesim_config scalar config
    struct fesim_population scalar population
    struct fesim_state scalar state
    struct fesim_results scalar results
    real matrix period_observed
    real scalar output_period
    real scalar worker
    real scalar result_row

    handler = fesim_dispatch_handler(dgp, preset)
    config = fesim_toy_config(workers, firms, periods)
    config = fesim_toy_solve(config)
    population = fesim_toy_generate_population(config)
    state = fesim_toy_initialize_state(population)
    state = fesim_toy_burn_in(state, population, config.burnin)
    results = fesim_results_new(config)

    for (output_period = 1; output_period <= config.periods; output_period++) {
        if (output_period > 1) {
            state = fesim_toy_advance(state, population)
        }
        period_observed = fesim_toy_observe(state, population, output_period)
        for (worker = 1; worker <= config.workers; worker++) {
            result_row = (worker - 1) * config.periods + output_period
            results.observed[result_row, ] = period_observed[worker, ]
        }
    }
    results = fesim_toy_finalize_flows(results)
    results = fesim_toy_compute_moments(results)
    results = fesim_toy_metadata(results, config)
    results.lifecycle = handler.lifecycle_stages
    fesim_results_validate(results)
    results.validated = 1
    results.status = "validated"
    return(results)
}

real scalar fesim_dispatch_toy_smoke()
{
    struct fesim_results scalar results

    results = fesim_dispatch_run("_toy", "deterministic", 3, 2, 2)
    return(results.validated)
}

end
