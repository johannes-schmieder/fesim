version 16.0

mata:

real scalar fesim_destination_schema_version()
{
    return(1)
}

real rowvector fesim_destination_type_support()
{
    return((-2, -1, 0, 1, 2) / sqrt(2))
}

void fesim_destination_assert_valid(
    struct fesim_destination_tables scalar tables)
{
    real scalar firms, types

    firms = rows(tables.firm_id)
    types = cols(tables.worker_type_support)
    if (tables.schema_version != fesim_destination_schema_version() | ///
        tables.validated != 1 | firms < 1 | types != 5 | ///
        rows(tables.firm_quality) != firms | ///
        rows(tables.firm_weight) != firms | ///
        rows(tables.firm_order) != firms | ///
        rows(tables.firm_position) != firms | ///
        rows(tables.ue_cumulative) != types | ///
        cols(tables.ue_cumulative) != firms | ///
        rows(tables.ee_lower_cumulative) != types | ///
        cols(tables.ee_lower_cumulative) != firms | ///
        rows(tables.ee_upper_reverse_cumulative) != types | ///
        cols(tables.ee_upper_reverse_cumulative) != firms) {
        _error(3300, "invalid fesim destination tables")
    }
}

struct fesim_destination_tables scalar fesim_destination_build(
    real colvector firm_id,
    real colvector firm_weight,
    real colvector firm_quality,
    real scalar theta_sort,
    real scalar theta_quality,
    real scalar theta_up,
    real scalar theta_down)
{
    struct fesim_destination_tables scalar tables
    real scalar firms, types, type_index, beta, log_scale
    real colvector order_index, position, sorted_weight, sorted_quality
    real colvector log_weight, scaled_weight

    firms = rows(firm_id)
    if (cols(firm_id) != 1 | cols(firm_weight) != 1 | ///
        cols(firm_quality) != 1 | firms < 1 | ///
        rows(firm_weight) != firms | rows(firm_quality) != firms | ///
        any(missing(firm_id)) | any(firm_id :!= floor(firm_id)) | ///
        any(firm_id :!= (1::firms)) | any(missing(firm_weight)) | ///
        any(firm_weight :<= 0) | any(missing(firm_quality)) | ///
        any(missing((theta_sort, theta_quality, theta_up, theta_down)))) {
        _error(3300, "destination firms must be 1..J with positive weights and finite quality")
    }

    tables.schema_version = fesim_destination_schema_version()
    tables.worker_type_support = fesim_destination_type_support()
    tables.firm_id = firm_id
    tables.firm_weight = firm_weight
    tables.firm_quality = firm_quality
    tables.theta_sort = theta_sort
    tables.theta_quality = theta_quality
    tables.theta_up = theta_up
    tables.theta_down = theta_down

    order_index = order((firm_quality, firm_id), (1, 2))
    tables.firm_order = firm_id[order_index]
    position = J(firms, 1, .)
    position[tables.firm_order] = 1::firms
    tables.firm_position = position
    sorted_weight = firm_weight[order_index]
    sorted_quality = firm_quality[order_index]

    types = cols(tables.worker_type_support)
    tables.ue_cumulative = J(types, firms, .)
    tables.ue_log_scale = J(types, 1, .)
    tables.ee_lower_cumulative = J(types, firms, .)
    tables.ee_lower_log_scale = J(types, 1, .)
    tables.ee_upper_reverse_cumulative = J(types, firms, .)
    tables.ee_upper_log_scale = J(types, 1, .)

    for (type_index = 1; type_index <= types; type_index++) {
        beta = theta_sort * tables.worker_type_support[type_index] + ///
            theta_quality

        log_weight = ln(firm_weight) :+ beta :* firm_quality
        if (any(missing(log_weight))) {
            _error(3300, "destination utility overflow")
        }
        log_scale = max(log_weight)
        scaled_weight = exp(log_weight :- log_scale)
        tables.ue_cumulative[type_index, .] = runningsum(scaled_weight')
        tables.ue_log_scale[type_index] = log_scale

        log_weight = ln(sorted_weight) :+ ///
            (beta - theta_down) :* sorted_quality
        if (any(missing(log_weight))) {
            _error(3300, "lower destination utility overflow")
        }
        log_scale = max(log_weight)
        scaled_weight = exp(log_weight :- log_scale)
        tables.ee_lower_cumulative[type_index, .] = ///
            runningsum(scaled_weight')
        tables.ee_lower_log_scale[type_index] = log_scale

        log_weight = ln(sorted_weight) :+ ///
            (beta + theta_up) :* sorted_quality
        if (any(missing(log_weight))) {
            _error(3300, "upper destination utility overflow")
        }
        log_scale = max(log_weight)
        scaled_weight = exp(log_weight :- log_scale)
        tables.ee_upper_reverse_cumulative[type_index, .] = ///
            runningsum(scaled_weight[firms::1]')
        tables.ee_upper_log_scale[type_index] = log_scale
    }
    tables.validated = 1
    fesim_destination_assert_valid(tables)
    return(tables)
}

real scalar fesim_destination_prefix_index(
    real rowvector cumulative,
    real scalar limit,
    real scalar target)
{
    real scalar lower, upper, middle

    if (limit < 1 | limit > cols(cumulative) | limit != floor(limit) | ///
        missing(target) | target < 0 | target >= cumulative[limit]) {
        _error(3300, "destination inverse-CDF target is outside its table")
    }
    lower = 1
    upper = limit
    while (lower < upper) {
        middle = floor((lower + upper) / 2)
        if (cumulative[middle] > target) upper = middle
        else lower = middle + 1
    }
    return(lower)
}

real colvector fesim_dest_sample_common(
    real colvector firm_weight,
    real colvector uniform_draw)
{
    real scalar draw
    real scalar total
    real colvector destination
    real rowvector cumulative

    if (cols(firm_weight) != 1 | rows(firm_weight) < 1 | ///
        any(missing(firm_weight)) | any(firm_weight :<= 0) | ///
        cols(uniform_draw) != 1 | any(missing(uniform_draw)) | ///
        any(uniform_draw :< 0) | any(uniform_draw :>= 1)) {
        _error(3300, "common destination weights or uniforms are invalid")
    }
    cumulative = runningsum(firm_weight')
    total = cumulative[cols(cumulative)]
    destination = J(rows(uniform_draw), 1, .)
    for (draw = 1; draw <= rows(uniform_draw); draw++) {
        destination[draw] = fesim_destination_prefix_index(
            cumulative, cols(cumulative), uniform_draw[draw] * total)
    }
    return(destination)
}

real colvector fesim_destination_sample_ue(
    struct fesim_destination_tables scalar tables,
    real colvector worker_type_index,
    real colvector uniform_draw)
{
    real scalar i, type_index, total, target
    real colvector destination

    fesim_destination_assert_valid(tables)
    if (cols(worker_type_index) != 1 | cols(uniform_draw) != 1 | ///
        rows(worker_type_index) != rows(uniform_draw) | ///
        any(missing(worker_type_index)) | ///
        any(worker_type_index :!= floor(worker_type_index)) | ///
        any(worker_type_index :< 1) | any(worker_type_index :> 5) | ///
        any(missing(uniform_draw)) | any(uniform_draw :< 0) | ///
        any(uniform_draw :>= 1)) {
        _error(3300, "UE destination types and uniforms are invalid")
    }
    destination = J(rows(uniform_draw), 1, .)
    for (i = 1; i <= rows(uniform_draw); i++) {
        type_index = worker_type_index[i]
        total = tables.ue_cumulative[type_index, cols(tables.ue_cumulative)]
        target = uniform_draw[i] * total
        destination[i] = fesim_destination_prefix_index(
            tables.ue_cumulative[type_index, .], ///
            cols(tables.ue_cumulative), target)
    }
    return(destination)
}

real scalar fesim_dest_lower_probability(
    real scalar log_lower,
    real scalar log_upper)
{
    real scalar difference

    difference = log_upper - log_lower
    if (difference >= 700) return(0)
    if (difference <= -700) return(1)
    return(1 / (1 + exp(difference)))
}

real colvector fesim_destination_sample_ee(
    struct fesim_destination_tables scalar tables,
    real colvector worker_type_index,
    real colvector current_firm,
    real colvector uniform_draw)
{
    real scalar i, type_index, firm, position, firms
    real scalar lower_total, upper_total, log_lower, log_upper, p_lower
    real scalar conditional, target, reverse_index, sorted_position
    real colvector destination

    fesim_destination_assert_valid(tables)
    firms = rows(tables.firm_id)
    if (firms < 2) _error(3300, "EE destination requires at least two firms")
    if (cols(worker_type_index) != 1 | cols(current_firm) != 1 | ///
        cols(uniform_draw) != 1 | ///
        rows(worker_type_index) != rows(current_firm) | ///
        rows(worker_type_index) != rows(uniform_draw) | ///
        any(missing(worker_type_index)) | ///
        any(worker_type_index :!= floor(worker_type_index)) | ///
        any(worker_type_index :< 1) | any(worker_type_index :> 5) | ///
        any(missing(current_firm)) | any(current_firm :!= floor(current_firm)) | ///
        any(current_firm :< 1) | any(current_firm :> firms) | ///
        any(missing(uniform_draw)) | any(uniform_draw :< 0) | ///
        any(uniform_draw :>= 1)) {
        _error(3300, "EE destination types, current firms, or uniforms are invalid")
    }

    destination = J(rows(uniform_draw), 1, .)
    for (i = 1; i <= rows(uniform_draw); i++) {
        type_index = worker_type_index[i]
        firm = current_firm[i]
        position = tables.firm_position[firm]
        lower_total = 0
        upper_total = 0
        if (position > 1) {
            lower_total = tables.ee_lower_cumulative[type_index, position - 1]
        }
        if (position < firms) {
            upper_total = tables.ee_upper_reverse_cumulative[
                type_index, firms - position]
        }

        if (lower_total == 0) p_lower = 0
        else if (upper_total == 0) p_lower = 1
        else {
            log_lower = tables.ee_lower_log_scale[type_index] + ///
                ln(lower_total) + tables.theta_down * tables.firm_quality[firm]
            log_upper = tables.ee_upper_log_scale[type_index] + ///
                ln(upper_total) - tables.theta_up * tables.firm_quality[firm]
            p_lower = fesim_dest_lower_probability(log_lower, log_upper)
        }

        if (uniform_draw[i] < p_lower) {
            conditional = uniform_draw[i] / p_lower
            target = conditional * lower_total
            sorted_position = fesim_destination_prefix_index(
                tables.ee_lower_cumulative[type_index, .], ///
                position - 1, target)
        }
        else {
            conditional = (uniform_draw[i] - p_lower) / (1 - p_lower)
            target = conditional * upper_total
            reverse_index = fesim_destination_prefix_index(
                tables.ee_upper_reverse_cumulative[type_index, .], ///
                firms - position, target)
            sorted_position = firms - reverse_index + 1
        }
        destination[i] = tables.firm_order[sorted_position]
    }
    return(destination)
}

real colvector fesim_destination_ue_probs(
    struct fesim_destination_tables scalar tables,
    real scalar worker_type_index)
{
    real rowvector cumulative, mass

    fesim_destination_assert_valid(tables)
    if (missing(worker_type_index) | worker_type_index < 1 | ///
        worker_type_index > 5 | worker_type_index != floor(worker_type_index)) {
        _error(3300, "worker type index must be 1 through 5")
    }
    cumulative = tables.ue_cumulative[worker_type_index, .]
    if (cols(cumulative) == 1) return(1)
    mass = cumulative - (0, cumulative[|1 \ cols(cumulative) - 1|])
    return((mass / cumulative[cols(cumulative)])')
}

real colvector fesim_destination_ee_probs(
    struct fesim_destination_tables scalar tables,
    real scalar worker_type_index,
    real scalar current_firm)
{
    real scalar beta, largest, firm
    real colvector log_weight, probability, quality_difference

    fesim_destination_assert_valid(tables)
    if (rows(tables.firm_id) < 2 | missing(worker_type_index) | ///
        worker_type_index < 1 | worker_type_index > 5 | ///
        worker_type_index != floor(worker_type_index) | ///
        missing(current_firm) | current_firm < 1 | ///
        current_firm > rows(tables.firm_id) | current_firm != floor(current_firm)) {
        _error(3300, "EE diagnostic probability request is invalid")
    }
    beta = tables.theta_sort * ///
        tables.worker_type_support[worker_type_index] + tables.theta_quality
    quality_difference = tables.firm_quality :- tables.firm_quality[current_firm]
    log_weight = ln(tables.firm_weight) :+ beta :* tables.firm_quality :+ ///
        tables.theta_up :* (quality_difference :> 0) :* quality_difference :+ ///
        tables.theta_down :* (quality_difference :< 0) :* (-quality_difference)
    largest = .
    for (firm = 1; firm <= rows(log_weight); firm++) {
        if (firm != current_firm & ///
            (missing(largest) | log_weight[firm] > largest)) {
            largest = log_weight[firm]
        }
    }
    probability = J(rows(log_weight), 1, 0)
    for (firm = 1; firm <= rows(log_weight); firm++) {
        if (firm != current_firm) {
            probability[firm] = exp(log_weight[firm] - largest)
        }
    }
    probability = probability / sum(probability)
    return(probability)
}

end
