version 16.0

mata:

struct fesim_rng_state {
    real scalar schema_version
    real scalar master_seed
    string scalar seed_source
    string scalar rng_name
    string scalar method
    string scalar caller_rng
    string scalar continuation_rng
    string scalar caller_state
    string scalar continuation_state
    string rowvector component_names
    real rowvector stream_ids
    string rowvector component_states
}

real scalar fesim_rng_schema_version()
{
    return(2)
}

string rowvector fesim_rng_component_names()
{
    return(("worker_primitives", "firm_primitives", "initial_states", ///
        "mobility_events", "destination_draws", "wage_shocks", ///
        "observation_error", "solver", "network_design"))
}

real rowvector fesim_rng_stream_ids()
{
    return((101, 102, 103, 104, 105, 106, 107, 108, 109))
}

void fesim_rng_restore_state(string scalar rng_name, string scalar state)
{
    stata("set rng " + rng_name, 1)
    rngstate(state)
}

real scalar fesim_rng_component_index(
    struct fesim_rng_state scalar state,
    string scalar component)
{
    real rowvector found

    found = selectindex(state.component_names :== strlower(strtrim(component)))
    if (cols(found) != 1) {
        _error(3300, "unknown fesim RNG component: " + component)
    }
    return(found[1])
}

struct fesim_rng_state scalar fesim_rng_init(
    real scalar requested_seed,
    real scalar seed_was_requested)
{
    struct fesim_rng_state scalar state
    real scalar i
    real matrix seed_draw
    string scalar seed_text

    state.schema_version = fesim_rng_schema_version()
    state.rng_name = "mt64s"
    state.method = "fixed_nonoverlapping_mt64s_component_streams"
    state.component_names = fesim_rng_component_names()
    state.stream_ids = fesim_rng_stream_ids()
    state.component_states = J(1, cols(state.component_names), "")
    state.caller_rng = st_global("c(rng)")
    state.continuation_rng = state.caller_rng
    state.caller_state = rngstate()

    if (seed_was_requested) {
        if (missing(requested_seed) | requested_seed < 0 | ///
            requested_seed > 2147483647 | requested_seed != floor(requested_seed)) {
            _error(3300, "fesim seed must be an integer from 0 through 2147483647")
        }
        state.master_seed = requested_seed
        state.seed_source = "requested"
        state.continuation_state = state.caller_state
    }
    else {
        seed_draw = runiformint(1, 1, 0, 2147483647)
        state.master_seed = seed_draw[1, 1]
        state.seed_source = "current_rng"
        state.continuation_state = rngstate()
    }

    seed_text = strtrim(sprintf("%21.0f", state.master_seed))
    stata("set rng mt64s", 1)
    stata("set seed " + seed_text, 1)
    stata("clear rngstream", 1)
    for (i = 1; i <= cols(state.component_names); i++) {
        stata("set rngstream " + strtrim(sprintf("%8.0f", state.stream_ids[i])), 1)
        state.component_states[i] = rngstate()
    }
    fesim_rng_restore_state(state.continuation_rng, state.continuation_state)
    return(state)
}

real matrix fesim_rng_runiform(
    struct fesim_rng_state scalar state,
    string scalar component,
    real scalar rows,
    real scalar cols)
{
    real scalar i
    real matrix draws
    string scalar restore_rng
    string scalar restore_state

    if (rows < 0 | cols < 0 | rows != floor(rows) | cols != floor(cols)) {
        _error(3200)
    }
    i = fesim_rng_component_index(state, component)
    restore_rng = st_global("c(rng)")
    restore_state = rngstate()
    stata("set rng mt64s", 1)
    rngstate(state.component_states[i])
    draws = runiform(rows, cols)
    state.component_states[i] = rngstate()
    fesim_rng_restore_state(restore_rng, restore_state)
    return(draws)
}

real matrix fesim_rng_runiformint(
    struct fesim_rng_state scalar state,
    string scalar component,
    real scalar rows,
    real scalar cols,
    real scalar minimum,
    real scalar maximum)
{
    real scalar i
    real matrix draws
    string scalar restore_rng
    string scalar restore_state

    if (rows < 0 | cols < 0 | rows != floor(rows) | cols != floor(cols)) {
        _error(3200)
    }
    i = fesim_rng_component_index(state, component)
    restore_rng = st_global("c(rng)")
    restore_state = rngstate()
    stata("set rng mt64s", 1)
    rngstate(state.component_states[i])
    draws = runiformint(rows, cols, minimum, maximum)
    state.component_states[i] = rngstate()
    fesim_rng_restore_state(restore_rng, restore_state)
    return(draws)
}

real matrix fesim_rng_rnormal(
    struct fesim_rng_state scalar state,
    string scalar component,
    real scalar rows,
    real scalar cols,
    real scalar mean,
    real scalar standard_deviation)
{
    real scalar i
    real matrix draws
    string scalar restore_rng
    string scalar restore_state

    if (rows < 0 | cols < 0 | rows != floor(rows) | cols != floor(cols) | ///
        standard_deviation < 0) {
        _error(3200)
    }
    i = fesim_rng_component_index(state, component)
    restore_rng = st_global("c(rng)")
    restore_state = rngstate()
    stata("set rng mt64s", 1)
    rngstate(state.component_states[i])
    draws = rnormal(rows, cols, mean, standard_deviation)
    state.component_states[i] = rngstate()
    fesim_rng_restore_state(restore_rng, restore_state)
    return(draws)
}

end
