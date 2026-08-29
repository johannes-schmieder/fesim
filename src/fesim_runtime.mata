version 16.0

mata:

real scalar fesim_runtime_schema_version()
{
    return(1)
}

real rowvector fesim_runtime_claim_timers(real scalar requested)
{
    real scalar timer_id
    real scalar found
    real rowvector claimed
    real rowvector value

    if (missing(requested) | requested < 1 | ///
        requested != floor(requested) | requested > 100) {
        _error(3300, "requested runtime timer count is invalid")
    }
    claimed = J(1, requested, .)
    found = 0
    for (timer_id = 100; timer_id >= 1 & found < requested; timer_id--) {
        value = timer_value(timer_id)
        if (value[1] == 0 & value[2] == 0) {
            found = found + 1
            claimed[found] = timer_id
        }
    }
    return(claimed)
}

void fesim_runtime_start(real scalar timer_id)
{
    if (missing(timer_id)) return
    timer_clear(timer_id)
    timer_on(timer_id)
}

real scalar fesim_runtime_stop(real scalar timer_id)
{
    real rowvector value

    if (missing(timer_id)) return(0)
    timer_off(timer_id)
    value = timer_value(timer_id)
    return(value[1])
}

void fesim_runtime_release(real rowvector timer_ids)
{
    real scalar position

    for (position = 1; position <= cols(timer_ids); position++) {
        if (!missing(timer_ids[position])) timer_clear(timer_ids[position])
    }
}

end
