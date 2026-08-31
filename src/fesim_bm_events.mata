version 16.0

mata:

real scalar fesim_bm_history_schema_version()
{
    return(1)
}

string rowvector fesim_bm_event_column_names()
{
    return(("worker_id", "event_time", "event_kind", "accepted", ///
        "origin_firm", "offered_firm", "destination_firm", ///
        "spell_id_after", "tenure_after", ///
        "unemployment_duration_after", "waiting_time"))
}

real scalar fesim_bm_open_uniform(real scalar value)
{
    real scalar boundary

    if (missing(value) | value < 0 | value > 1) {
        _error(3300, "BM event uniform must lie in [0,1]")
    }
    boundary = 2^-53
    if (value <= 0) return(boundary)
    if (value >= 1) return(1 - boundary)
    return(value)
}

real scalar fesim_bm_exponential_wait(
    real scalar uniform,
    real scalar rate)
{
    if (missing(rate) | rate <= 0) {
        _error(3300, "BM event rate must be positive")
    }
    uniform = fesim_bm_open_uniform(uniform)
    return(-fesim_bm_log1p(-uniform) / rate)
}

real scalar fesim_bm_event_kind(
    real scalar employed,
    real scalar type_uniform,
    real scalar lambda_e,
    real scalar delta)
{
    if ((employed != 0 & employed != 1) | missing(type_uniform) | ///
        type_uniform < 0 | type_uniform > 1 | missing(lambda_e) | ///
        missing(delta) | lambda_e <= 0 | delta <= 0) {
        _error(3300, "BM event-type inputs are invalid")
    }
    if (!employed) return(1)
    type_uniform = fesim_bm_open_uniform(type_uniform)
    if (type_uniform < delta / (delta + lambda_e)) return(3)
    return(2)
}

real scalar fesim_bm_offer_accept(
    real scalar employed,
    real scalar current_firm,
    real scalar offered_firm,
    real colvector posted_wage)
{
    real scalar firms

    firms = rows(posted_wage)
    if ((employed != 0 & employed != 1) | firms < 1 | ///
        cols(posted_wage) != 1 | any(missing(posted_wage)) | ///
        missing(offered_firm) | offered_firm < 1 | ///
        offered_firm > firms | offered_firm != floor(offered_firm)) {
        _error(3300, "BM offer-acceptance inputs are invalid")
    }
    if (!employed) {
        if (!missing(current_firm) & current_firm != 0) {
            _error(3300, "BM unemployed current firm must be zero")
        }
        return(1)
    }
    if (missing(current_firm) | current_firm < 1 | ///
        current_firm > firms | current_firm != floor(current_firm)) {
        _error(3300, "BM employed current firm is invalid")
    }
    return(posted_wage[offered_firm] > posted_wage[current_firm])
}

void fesim_bm_initial_state_validate(
    struct fesim_bm_firms scalar universe,
    real colvector employed,
    real colvector firm_id,
    real colvector spell_id,
    real colvector tenure,
    real colvector unemployment_duration)
{
    real scalar workers
    real colvector employed_rows, unemployed_rows

    workers = rows(employed)
    if (universe.validated != 1 | workers < 1 | cols(employed) != 1 | ///
        rows(firm_id) != workers | cols(firm_id) != 1 | ///
        rows(spell_id) != workers | cols(spell_id) != 1 | ///
        rows(tenure) != workers | cols(tenure) != 1 | ///
        rows(unemployment_duration) != workers | ///
        cols(unemployment_duration) != 1 | ///
        any(employed :!= 0 :& employed :!= 1) | ///
        any(missing(firm_id)) | any(missing(spell_id)) | ///
        any(spell_id :< 0) | any(spell_id :!= floor(spell_id))) {
        _error(3300, "BM initial state dimensions are invalid")
    }
    employed_rows = selectindex(employed :== 1)
    unemployed_rows = selectindex(employed :== 0)
    if (length(employed_rows)) {
        if (any(firm_id[employed_rows] :< 1) | ///
            any(firm_id[employed_rows] :> universe.firms) | ///
            any(firm_id[employed_rows] :!= floor(firm_id[employed_rows])) | ///
            any(spell_id[employed_rows] :< 1) | ///
            any(missing(tenure[employed_rows])) | ///
            any(tenure[employed_rows] :< 0) | ///
            any(!missing(unemployment_duration[employed_rows]))) {
            _error(3300, "BM employed initial states are invalid")
        }
    }
    if (length(unemployed_rows)) {
        if (any(firm_id[unemployed_rows] :!= 0) | ///
            any(!missing(tenure[unemployed_rows])) | ///
            any(missing(unemployment_duration[unemployed_rows])) | ///
            any(unemployment_duration[unemployed_rows] :< 0)) {
            _error(3300, "BM unemployed initial states are invalid")
        }
    }
}

void fesim_bm_history_validate(
    struct fesim_bm_solution scalar solution,
    struct fesim_bm_firms scalar universe,
    struct fesim_bm_history scalar history,
    real scalar tolerance)
{
    real scalar workers, events, row, worker, previous_worker
    real scalar current_employed, current_firm, current_spell
    real scalar current_tenure, current_unemployment, previous_time
    real scalar event_time, event_kind, accepted, offered, destination
    real scalar waiting, expected_acceptance
    real scalar count_u, count_e, count_d, count_entry, count_move
    real scalar count_rejected, count_transitions
    real rowvector counts
    real colvector replay_employed, replay_firm, replay_spell
    real colvector replay_tenure, replay_unemployment, replay_transitions
    real colvector last_event_time

    workers = history.workers
    events = history.total_events
    if (solution.validated != 1 | universe.validated != 1 | ///
        history.schema_version != fesim_bm_history_schema_version() | ///
        history.status != "simulated" | missing(workers) | workers < 1 | ///
        workers != floor(workers) | history.firms != universe.firms | ///
        missing(history.horizon) | history.horizon < 0 | ///
        (history.record_events != 0 & history.record_events != 1) | ///
        missing(tolerance) | tolerance <= 0 | tolerance > 1e-4 | ///
        missing(events) | events < 0 | events != floor(events) | ///
        any(missing((history.unemployment_offers, ///
            history.employed_offers, history.destructions, ///
            history.accepted_entries, history.accepted_moves, ///
            history.rejected_offers, history.total_transitions)))) {
        _error(3300, "BM event history structure is invalid")
    }
    fesim_bm_initial_state_validate(universe, history.initial_employed, ///
        history.initial_firm_id, history.initial_spell_id, ///
        history.initial_tenure, history.initial_unemployment_duration)
    fesim_bm_initial_state_validate(universe, history.final_employed, ///
        history.final_firm_id, history.final_spell_id, ///
        history.final_tenure, history.final_unemployment_duration)
    counts = (history.unemployment_offers, history.employed_offers, ///
        history.destructions, history.accepted_entries, ///
        history.accepted_moves, history.rejected_offers, ///
        history.total_transitions)
    if (rows(history.final_transitions) != workers | ///
        cols(history.final_transitions) != 1 | ///
        any(counts :< 0) | any(counts :!= floor(counts)) | ///
        any(missing(history.final_transitions)) | ///
        any(history.final_transitions :< 0) | ///
        any(history.final_transitions :!= floor(history.final_transitions)) | ///
        history.total_transitions != sum(history.final_transitions) | ///
        history.total_transitions != history.accepted_entries + ///
            history.accepted_moves + history.destructions | ///
        history.total_events != history.unemployment_offers + ///
            history.employed_offers + history.destructions | ///
        history.unemployment_offers != history.accepted_entries | ///
        history.employed_offers != history.accepted_moves + ///
            history.rejected_offers) {
        _error(430, "BM event history totals are inconsistent")
    }
    if (!history.record_events) {
        if (rows(history.events) != 0 | cols(history.events) != 11) {
            _error(430, "BM unrecorded event history is invalid")
        }
        return
    }
    if (rows(history.events) != events | cols(history.events) != 11) {
        _error(3300, "BM event ledger dimensions are invalid")
    }

    replay_employed = history.initial_employed
    replay_firm = history.initial_firm_id
    replay_spell = history.initial_spell_id
    replay_tenure = history.initial_tenure
    replay_unemployment = history.initial_unemployment_duration
    replay_transitions = J(workers, 1, 0)
    last_event_time = J(workers, 1, 0)
    count_u = 0
    count_e = 0
    count_d = 0
    count_entry = 0
    count_move = 0
    count_rejected = 0
    count_transitions = 0
    previous_worker = 0
    previous_time = 0
    for (row = 1; row <= events; row++) {
        worker = history.events[row, 1]
        event_time = history.events[row, 2]
        event_kind = history.events[row, 3]
        accepted = history.events[row, 4]
        offered = history.events[row, 6]
        destination = history.events[row, 7]
        waiting = history.events[row, 11]
        if (missing(worker) | worker < 1 | worker > workers | ///
            worker != floor(worker) | worker < previous_worker | ///
            missing(event_time) | event_time <= 0 | ///
            event_time > history.horizon | missing(waiting) | waiting <= 0) {
            _error(430, "BM event ordering is invalid")
        }
        if (worker != previous_worker) previous_time = 0
        if (event_time <= previous_time | ///
            abs(event_time - previous_time - waiting) > tolerance) {
            _error(430, "BM within-worker event times are invalid")
        }
        current_employed = replay_employed[worker]
        current_firm = replay_firm[worker]
        current_spell = replay_spell[worker]
        current_tenure = replay_tenure[worker]
        current_unemployment = replay_unemployment[worker]
        if (current_employed) current_tenure = current_tenure + waiting
        else current_unemployment = current_unemployment + waiting
        if (history.events[row, 5] != current_firm) {
            _error(430, "BM event origin is inconsistent")
        }

        if (!current_employed) {
            if (event_kind != 1 | accepted != 1 | offered < 1 | ///
                offered > universe.firms | offered != floor(offered) | ///
                destination != offered) {
                _error(430, "BM unemployment offer event is invalid")
            }
            current_employed = 1
            current_firm = offered
            current_spell = current_spell + 1
            current_tenure = 0
            current_unemployment = .
            count_u = count_u + 1
            count_entry = count_entry + 1
            count_transitions = count_transitions + 1
            replay_transitions[worker] = replay_transitions[worker] + 1
        }
        else if (event_kind == 3) {
            if (accepted != 0 | offered != 0 | destination != 0) {
                _error(430, "BM destruction event is invalid")
            }
            current_employed = 0
            current_firm = 0
            current_tenure = .
            current_unemployment = 0
            count_d = count_d + 1
            count_transitions = count_transitions + 1
            replay_transitions[worker] = replay_transitions[worker] + 1
        }
        else if (event_kind == 2) {
            expected_acceptance = fesim_bm_offer_accept(
                1, current_firm, offered, universe.posted_wage)
            if (accepted != expected_acceptance | ///
                destination != (accepted ? offered : current_firm)) {
                _error(430, "BM employed offer event is invalid")
            }
            count_e = count_e + 1
            if (accepted) {
                current_firm = offered
                current_spell = current_spell + 1
                current_tenure = 0
                count_move = count_move + 1
                count_transitions = count_transitions + 1
                replay_transitions[worker] = replay_transitions[worker] + 1
            }
            else count_rejected = count_rejected + 1
        }
        else _error(430, "BM event kind is invalid")

        if (history.events[row, 7] != current_firm | ///
            history.events[row, 8] != current_spell | ///
            (current_employed & ///
                (abs(history.events[row, 9] - current_tenure) > tolerance | ///
                !missing(history.events[row, 10]))) | ///
            (!current_employed & ///
                (!missing(history.events[row, 9]) | ///
                abs(history.events[row, 10] - current_unemployment) > ///
                tolerance))) {
            _error(430, "BM event post-state is inconsistent")
        }
        replay_employed[worker] = current_employed
        replay_firm[worker] = current_firm
        replay_spell[worker] = current_spell
        replay_tenure[worker] = current_tenure
        replay_unemployment[worker] = current_unemployment
        last_event_time[worker] = event_time
        previous_worker = worker
        previous_time = event_time
    }
    for (worker = 1; worker <= workers; worker++) {
        if (replay_employed[worker]) {
            replay_tenure[worker] = replay_tenure[worker] + ///
                history.horizon - last_event_time[worker]
        }
        else {
            replay_unemployment[worker] = replay_unemployment[worker] + ///
                history.horizon - last_event_time[worker]
        }
    }
    if (any(replay_employed :!= history.final_employed) | ///
        any(replay_firm :!= history.final_firm_id) | ///
        any(replay_spell :!= history.final_spell_id) | ///
        mreldif(replay_tenure, history.final_tenure) > tolerance | ///
        mreldif(replay_unemployment, ///
            history.final_unemployment_duration) > tolerance | ///
        any(replay_transitions :!= history.final_transitions) | ///
        count_u != history.unemployment_offers | ///
        count_e != history.employed_offers | ///
        count_d != history.destructions | ///
        count_entry != history.accepted_entries | ///
        count_move != history.accepted_moves | ///
        count_rejected != history.rejected_offers | ///
        count_transitions != history.total_transitions) {
        _error(430, "BM event replay validation failed")
    }
}

struct fesim_bm_history scalar fesim_bm_simulate_events(
    struct fesim_bm_solution scalar solution,
    struct fesim_bm_firms scalar universe,
    real colvector employed,
    real colvector firm_id,
    real colvector spell_id,
    real colvector tenure,
    real colvector unemployment_duration,
    real scalar horizon,
    real scalar record_events,
    real scalar max_events,
    struct fesim_rng_state scalar rng_state,
    real scalar tolerance)
{
    struct fesim_bm_history scalar history
    real scalar workers, worker, current_time, rate, waiting, event_kind
    real scalar type_uniform, destination_uniform, offered_firm, accepted
    real scalar origin_firm, remaining, event_index, destination_index
    real scalar buffer_size, capacity, new_capacity, event_count
    real scalar current_employed, current_firm, current_spell
    real scalar current_tenure, current_unemployment
    real colvector event_buffer, destination_buffer

    workers = rows(employed)
    if (solution.validated != 1 | universe.validated != 1 | ///
        missing(horizon) | horizon < 0 | horizon > 100000 | ///
        (record_events != 0 & record_events != 1) | ///
        missing(max_events) | max_events < 1 | ///
        max_events != floor(max_events) | max_events > 10000000 | ///
        rng_state.schema_version != fesim_rng_schema_version() | ///
        missing(tolerance) | tolerance <= 0 | tolerance > 1e-4) {
        _error(3300, "BM event simulation controls are invalid")
    }
    fesim_bm_initial_state_validate(universe, employed, firm_id, spell_id, ///
        tenure, unemployment_duration)
    history.schema_version = fesim_bm_history_schema_version()
    history.status = "simulated"
    history.workers = workers
    history.firms = universe.firms
    history.horizon = horizon
    history.record_events = record_events
    history.initial_employed = employed
    history.initial_firm_id = firm_id
    history.initial_spell_id = spell_id
    history.initial_tenure = tenure
    history.initial_unemployment_duration = unemployment_duration
    history.final_employed = employed
    history.final_firm_id = firm_id
    history.final_spell_id = spell_id
    history.final_tenure = tenure
    history.final_unemployment_duration = unemployment_duration
    history.final_transitions = J(workers, 1, 0)
    history.total_events = 0
    history.unemployment_offers = 0
    history.employed_offers = 0
    history.destructions = 0
    history.accepted_entries = 0
    history.accepted_moves = 0
    history.rejected_offers = 0
    history.total_transitions = 0
    buffer_size = 4096
    event_buffer = J(0, 1, .)
    destination_buffer = J(0, 1, .)
    event_index = 1
    destination_index = 1
    if (record_events) {
        capacity = min((max_events, buffer_size))
        history.events = J(capacity, 11, .)
    }
    else {
        capacity = 0
        history.events = J(0, 11, .)
    }
    event_count = 0

    for (worker = 1; worker <= workers; worker++) {
        current_time = 0
        current_employed = history.final_employed[worker]
        current_firm = history.final_firm_id[worker]
        current_spell = history.final_spell_id[worker]
        current_tenure = history.final_tenure[worker]
        current_unemployment = history.final_unemployment_duration[worker]
        while (current_time < horizon) {
            rate = current_employed ? ///
                solution.lambda_e + solution.delta : solution.lambda_u
            if (event_index > rows(event_buffer)) {
                event_buffer = fesim_rng_runiform(
                    rng_state, "mobility_events", buffer_size, 1)
                event_index = 1
            }
            waiting = fesim_bm_exponential_wait(
                event_buffer[event_index], rate)
            event_index = event_index + 1
            if (current_time + waiting > horizon) {
                remaining = horizon - current_time
                if (current_employed) current_tenure = current_tenure + remaining
                else current_unemployment = current_unemployment + remaining
                current_time = horizon
                break
            }
            current_time = current_time + waiting
            if (current_employed) current_tenure = current_tenure + waiting
            else current_unemployment = current_unemployment + waiting
            if (event_count >= max_events) {
                _error(430, "BM event simulation exceeded max_events")
            }
            if (current_employed) {
                if (event_index > rows(event_buffer)) {
                    event_buffer = fesim_rng_runiform(
                        rng_state, "mobility_events", buffer_size, 1)
                    event_index = 1
                }
                type_uniform = event_buffer[event_index]
                event_index = event_index + 1
            }
            else type_uniform = .5
            event_kind = fesim_bm_event_kind(
                current_employed, type_uniform, solution.lambda_e, ///
                solution.delta)
            origin_firm = current_firm
            offered_firm = 0
            accepted = 0
            if (event_kind == 1 | event_kind == 2) {
                if (destination_index > rows(destination_buffer)) {
                    destination_buffer = fesim_rng_runiform(
                        rng_state, "destination_draws", buffer_size, 1)
                    destination_index = 1
                }
                destination_uniform = fesim_bm_open_uniform(
                    destination_buffer[destination_index])
                destination_index = destination_index + 1
                offered_firm = min((universe.firms, ///
                    1 + floor(destination_uniform * universe.firms)))
                accepted = fesim_bm_offer_accept(current_employed, ///
                    current_firm, offered_firm, universe.posted_wage)
            }
            if (event_kind == 1) {
                history.unemployment_offers = history.unemployment_offers + 1
                history.accepted_entries = history.accepted_entries + 1
                current_employed = 1
                current_firm = offered_firm
                current_spell = current_spell + 1
                current_tenure = 0
                current_unemployment = .
                history.final_transitions[worker] = ///
                    history.final_transitions[worker] + 1
            }
            else if (event_kind == 3) {
                history.destructions = history.destructions + 1
                current_employed = 0
                current_firm = 0
                current_tenure = .
                current_unemployment = 0
                history.final_transitions[worker] = ///
                    history.final_transitions[worker] + 1
            }
            else {
                history.employed_offers = history.employed_offers + 1
                if (accepted) {
                    history.accepted_moves = history.accepted_moves + 1
                    current_firm = offered_firm
                    current_spell = current_spell + 1
                    current_tenure = 0
                    history.final_transitions[worker] = ///
                        history.final_transitions[worker] + 1
                }
                else history.rejected_offers = history.rejected_offers + 1
            }
            event_count = event_count + 1
            if (record_events) {
                if (event_count > capacity) {
                    new_capacity = min((max_events, max((
                        capacity + 1, 2 * capacity))))
                    history.events = history.events \ ///
                        J(new_capacity - capacity, 11, .)
                    capacity = new_capacity
                }
                history.events[event_count, ] = (
                    worker, current_time, event_kind, accepted, ///
                    origin_firm, offered_firm, current_firm, ///
                    current_spell, current_tenure, current_unemployment, ///
                    waiting)
            }
        }
        history.final_employed[worker] = current_employed
        history.final_firm_id[worker] = current_firm
        history.final_spell_id[worker] = current_spell
        history.final_tenure[worker] = current_tenure
        history.final_unemployment_duration[worker] = current_unemployment
    }
    history.total_events = event_count
    history.total_transitions = sum(history.final_transitions)
    if (record_events) {
        if (event_count == 0) history.events = J(0, 11, .)
        else history.events = history.events[1..event_count, ]
    }
    history.validated = 0
    fesim_bm_history_validate(solution, universe, history, tolerance)
    history.validated = 1
    return(history)
}

end
