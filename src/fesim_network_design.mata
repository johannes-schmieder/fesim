version 16.0

mata:

real scalar fesim_netdesign_schema_version()
{
    return(1)
}

real colvector fesim_netdesign_balanced(
    real scalar units,
    real scalar blocks,
    real colvector uniform_draw)
{
    real colvector assignment
    real colvector order_index

    if (missing(units) | missing(blocks) | units < 1 | blocks < 1 | ///
        units != floor(units) | blocks != floor(blocks) | blocks > units | ///
        cols(uniform_draw) != 1 | rows(uniform_draw) != units | ///
        any(missing(uniform_draw)) | any(uniform_draw :< 0) | ///
        any(uniform_draw :>= 1)) {
        _error(3300, "balanced network assignments are invalid")
    }
    order_index = order((uniform_draw, (1::units)), (1, 2))
    assignment = J(units, 1, .)
    assignment[order_index] = 1 :+ mod((0::(units - 1)), blocks)
    return(assignment)
}

void fesim_netdesign_validate(struct fesim_network_design scalar design)
{
    real scalar firms
    real scalar workers

    workers = rows(design.worker_block)
    firms = rows(design.firm_block)
    if (design.schema_version != fesim_netdesign_schema_version() | ///
        design.validated != 1 | workers < 1 | firms < 1 | ///
        rows(design.worker_priority) != workers | ///
        (design.mode != "random" & design.mode != "blocks" & ///
        design.mode != "bridges") | ///
        missing(design.block_count) | design.block_count < 1 | ///
        design.block_count != floor(design.block_count) | ///
        missing(design.block_log_bonus) | design.block_log_bonus < 0 | ///
        design.block_log_bonus > 30 | missing(design.bridge_count) | ///
        design.bridge_count < 0 | design.bridge_count != floor(design.bridge_count) | ///
        any(missing(design.worker_block)) | ///
        any(missing(design.firm_block)) | ///
        any(missing(design.worker_priority)) | ///
        any(design.worker_block :< 1) | ///
        any(design.worker_block :> design.block_count) | ///
        any(design.firm_block :< 1) | ///
        any(design.firm_block :> design.block_count) | ///
        any(design.worker_priority :< 1) | ///
        any(design.worker_priority :> workers) | ///
        any(design.worker_priority :!= floor(design.worker_priority))) {
        _error(3300, "network design is invalid")
    }
    if (design.mode == "random") {
        if (design.block_count != 1 | design.block_log_bonus != 0 | ///
            design.bridge_count != 0 | any(design.worker_block :!= 1) | ///
            any(design.firm_block :!= 1)) {
            _error(3300, "random network design is invalid")
        }
    }
    else if (design.block_count > min((workers, firms))) {
        _error(3300, "network blocks exceed workers or firms")
    }
    if (design.prepared != 0 & design.prepared != 1) {
        _error(3300, "network design preparation flag is invalid")
    }
    if (design.prepared == 1 & ///
        (rows(design.firm_cumulative) != design.block_count | ///
        cols(design.firm_cumulative) != firms | ///
        any(missing(design.firm_cumulative)) | ///
        any(design.firm_cumulative :<= 0))) {
        _error(3300, "network destination tables are invalid")
    }
}

struct fesim_network_design scalar fesim_netdesign_build(
    string scalar mode,
    real scalar workers,
    real scalar firms,
    real scalar block_count,
    real scalar block_log_bonus,
    real scalar bridge_count,
    struct fesim_rng_state scalar rng_state)
{
    struct fesim_network_design scalar design
    real colvector firm_draw
    real colvector order_index
    real colvector worker_draw

    mode = strlower(strtrim(mode))
    if (missing(workers) | missing(firms) | workers < 1 | firms < 1 | ///
        workers != floor(workers) | firms != floor(firms) | ///
        (mode != "random" & mode != "blocks" & mode != "bridges")) {
        _error(3300, "network design inputs are invalid")
    }
    design.schema_version = fesim_netdesign_schema_version()
    design.mode = mode
    design.firm_cumulative = J(0, 0, .)
    design.prepared = 0
    design.validated = 0
    if (mode == "random") {
        design.block_count = 1
        design.block_log_bonus = 0
        design.bridge_count = 0
        design.worker_block = J(workers, 1, 1)
        design.firm_block = J(firms, 1, 1)
        design.worker_priority = (1::workers)
    }
    else {
        if (missing(block_count) | block_count < 2 | ///
            block_count != floor(block_count) | ///
            block_count > min((workers, firms)) | ///
            missing(block_log_bonus) | block_log_bonus < 0 | ///
            block_log_bonus > 30 | missing(bridge_count) | ///
            bridge_count < 0 | bridge_count != floor(bridge_count)) {
            _error(3300, "block network design inputs are invalid")
        }
        design.block_count = block_count
        design.block_log_bonus = block_log_bonus
        design.bridge_count = bridge_count
        worker_draw = fesim_rng_runiform(
            rng_state, "network_design", workers, 1)
        firm_draw = fesim_rng_runiform(
            rng_state, "network_design", firms, 1)
        design.worker_block = fesim_netdesign_balanced(
            workers, block_count, worker_draw)
        design.firm_block = fesim_netdesign_balanced(
            firms, block_count, firm_draw)
        order_index = order((worker_draw, (1::workers)), (1, 2))
        design.worker_priority = J(workers, 1, .)
        design.worker_priority[order_index] = (1::workers)
    }
    design.validated = 1
    fesim_netdesign_validate(design)
    return(design)
}

void fesim_netdesign_prepare(
    struct fesim_network_design scalar design,
    real colvector firm_weight)
{
    real scalar block
    real scalar factor
    real colvector adjusted

    fesim_netdesign_validate(design)
    if (cols(firm_weight) != 1 | ///
        rows(firm_weight) != rows(design.firm_block) | ///
        any(missing(firm_weight)) | any(firm_weight :<= 0)) {
        _error(3300, "network destination weights are invalid")
    }
    factor = exp(design.block_log_bonus)
    design.firm_cumulative = J(
        design.block_count, rows(firm_weight), .)
    for (block = 1; block <= design.block_count; block++) {
        adjusted = firm_weight :* ///
            (1 :+ (factor - 1) :* (design.firm_block :== block))
        design.firm_cumulative[block, .] = runningsum(adjusted')
    }
    design.prepared = 1
    fesim_netdesign_validate(design)
}

real colvector fesim_netdesign_sample_common(
    struct fesim_network_design scalar design,
    real colvector firm_weight,
    real colvector reference_block,
    real colvector uniform_draw)
{
    real scalar block
    real scalar draw
    real scalar total
    real colvector destination

    fesim_netdesign_validate(design)
    if (design.prepared != 1 | cols(reference_block) != 1 | ///
        cols(uniform_draw) != 1 | ///
        rows(reference_block) != rows(uniform_draw) | ///
        any(missing(reference_block)) | ///
        any(reference_block :!= floor(reference_block)) | ///
        any(reference_block :< 1) | ///
        any(reference_block :> design.block_count) | ///
        any(missing(uniform_draw)) | any(uniform_draw :< 0) | ///
        any(uniform_draw :>= 1)) {
        _error(3300, "block common-destination inputs are invalid")
    }
    if (design.mode == "random" | design.block_log_bonus == 0) {
        return(fesim_destination_sample_common(firm_weight, uniform_draw))
    }
    destination = J(rows(uniform_draw), 1, .)
    for (draw = 1; draw <= rows(uniform_draw); draw++) {
        block = reference_block[draw]
        total = design.firm_cumulative[block, cols(design.firm_cumulative)]
        destination[draw] = fesim_destination_prefix_index(
            design.firm_cumulative[block, .], ///
            cols(design.firm_cumulative), uniform_draw[draw] * total)
    }
    return(destination)
}

real colvector fesim_netdesign_sample_excl(
    struct fesim_network_design scalar design,
    real colvector firm_weight,
    real colvector reference_block,
    real colvector current_firm,
    real colvector uniform_draw)
{
    real scalar before
    real scalar block
    real scalar current_mass
    real scalar draw
    real scalar firms
    real scalar target
    real scalar total
    real colvector destination

    fesim_netdesign_validate(design)
    firms = rows(design.firm_block)
    if (design.prepared != 1 | firms < 2 | ///
        cols(reference_block) != 1 | cols(current_firm) != 1 | ///
        cols(uniform_draw) != 1 | ///
        rows(reference_block) != rows(current_firm) | ///
        rows(reference_block) != rows(uniform_draw) | ///
        any(missing(reference_block)) | ///
        any(reference_block :!= floor(reference_block)) | ///
        any(reference_block :< 1) | ///
        any(reference_block :> design.block_count) | ///
        any(missing(current_firm)) | ///
        any(current_firm :!= floor(current_firm)) | ///
        any(current_firm :< 1) | any(current_firm :> firms) | ///
        any(missing(uniform_draw)) | any(uniform_draw :< 0) | ///
        any(uniform_draw :>= 1)) {
        _error(3300, "block excluded-destination inputs are invalid")
    }
    if (design.mode == "random" | design.block_log_bonus == 0) {
        return(fesim_destination_sample_excl(
            firm_weight, current_firm, uniform_draw))
    }
    destination = J(rows(uniform_draw), 1, .)
    for (draw = 1; draw <= rows(uniform_draw); draw++) {
        block = reference_block[draw]
        before = 0
        if (current_firm[draw] > 1) {
            before = design.firm_cumulative[
                block, current_firm[draw] - 1]
        }
        current_mass = design.firm_cumulative[
            block, current_firm[draw]] - before
        total = design.firm_cumulative[block, firms] - current_mass
        if (total <= 0) {
            _error(3300, "excluded firm leaves no block destination mass")
        }
        target = uniform_draw[draw] * total
        if (target >= before) target = target + current_mass
        destination[draw] = fesim_destination_prefix_index(
            design.firm_cumulative[block, .], firms, target)
    }
    return(destination)
}

real colvector fesim_netdesign_common_probs(
    struct fesim_network_design scalar design,
    real scalar reference_block)
{
    real rowvector cumulative
    real rowvector mass

    fesim_netdesign_validate(design)
    if (design.prepared != 1 | missing(reference_block) | ///
        reference_block < 1 | reference_block > design.block_count | ///
        reference_block != floor(reference_block)) {
        _error(3300, "block probability reference is invalid")
    }
    cumulative = design.firm_cumulative[reference_block, .]
    mass = cumulative - (0, cumulative[|1 \ cols(cumulative) - 1|])
    return((mass / cumulative[cols(cumulative)])')
}

real colvector fesim_netdesign_excl_probs(
    struct fesim_network_design scalar design,
    real scalar reference_block,
    real scalar current_firm)
{
    real scalar denominator
    real colvector probability

    probability = fesim_netdesign_common_probs(design, reference_block)
    if (missing(current_firm) | current_firm < 1 | ///
        current_firm > rows(probability) | current_firm != floor(current_firm)) {
        _error(3300, "excluded block probability firm is invalid")
    }
    denominator = 1 - probability[current_firm]
    if (denominator <= 0) {
        _error(3300, "excluded firm leaves no block probability mass")
    }
    probability = probability / denominator
    probability[current_firm] = 0
    return(probability)
}

end
