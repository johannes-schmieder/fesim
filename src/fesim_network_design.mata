version 16.0

mata:

real scalar fesim_netdesign_schema_version()
{
    return(3)
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
    real scalar block
    real scalar firms
    real scalar workers
    real rowvector cumulative_row
    real rowvector differences

    workers = rows(design.worker_block)
    firms = rows(design.firm_block)
    if (design.schema_version != fesim_netdesign_schema_version() | ///
        design.validated != 1 | workers < 1 | firms < 1 | ///
        rows(design.worker_priority) != workers | ///
        rows(design.firm_rank) != firms | ///
        rows(design.bridge_candidate_output_period) != workers | ///
        rows(design.bridge_candidate_internal_period) != workers | ///
        rows(design.bridge_interval_count) != workers | ///
        (design.mode != "random" & design.mode != "blocks" & ///
        design.mode != "bridges" & design.mode != "ladder")) {
        _error(3300, "network design is invalid")
    }
    if (missing(design.block_count) | design.block_count < 1 | ///
        design.block_count != floor(design.block_count) | ///
        missing(design.block_log_bonus) | design.block_log_bonus < 0 | ///
        design.block_log_bonus > 30 | missing(design.bridge_count) | ///
        design.bridge_count < 0 | ///
        design.bridge_count != floor(design.bridge_count) | ///
        any(missing((design.ladder_down_share, ///
        design.ladder_lateral_share, design.ladder_up_share, ///
        design.ladder_band))) | design.ladder_down_share < 0 | ///
        design.ladder_down_share > 1 | design.ladder_lateral_share < 0 | ///
        design.ladder_lateral_share > 1 | design.ladder_up_share < 0 | ///
        design.ladder_up_share > 1 | design.ladder_band < 0 | ///
        design.ladder_band > 1) {
        _error(3300, "network design is invalid")
    }
    if (any(missing(design.worker_block)) | ///
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
    if (missing(design.bridge_phase) | design.bridge_phase < 0 | ///
        design.bridge_phase > 3 | ///
        design.bridge_phase != floor(design.bridge_phase) | ///
        missing(design.bridge_output_period) | ///
        design.bridge_output_period < 0 | ///
        design.bridge_output_period != floor(design.bridge_output_period) | ///
        missing(design.bridge_filled) | design.bridge_filled < 0 | ///
        design.bridge_filled > design.bridge_count | ///
        design.bridge_filled != floor(design.bridge_filled) | ///
        rows(design.bridge_source_block) != design.bridge_count | ///
        rows(design.bridge_target_block) != design.bridge_count | ///
        rows(design.bridge_plan_worker) != design.bridge_count | ///
        rows(design.bridge_plan_output_period) != design.bridge_count | ///
        rows(design.bridge_plan_internal_period) != design.bridge_count | ///
        rows(design.bridge_ledger) != design.bridge_count | ///
        cols(design.bridge_ledger) != 8 | ///
        any(missing(design.bridge_interval_count)) | ///
        any(design.bridge_interval_count :< 0) | ///
        any(design.bridge_interval_count :!= ///
            floor(design.bridge_interval_count))) {
        _error(3300, "network design is invalid")
    }
    if (design.mode == "random") {
        if (design.block_count != 1 | design.block_log_bonus != 0 | ///
            design.bridge_count != 0 | any(design.worker_block :!= 1) | ///
            any(design.firm_block :!= 1) | ///
            design.ladder_down_share != 0 | ///
            design.ladder_lateral_share != 0 | ///
            design.ladder_up_share != 0 | design.ladder_band != 0 | ///
            any(design.firm_rank :< .)) {
            _error(3300, "random network design is invalid")
        }
    }
    else if (design.mode == "ladder") {
        if (design.block_count != 1 | design.block_log_bonus != 0 | ///
            design.bridge_count != 0 | any(design.worker_block :!= 1) | ///
            any(design.firm_block :!= 1) | ///
            any(missing(design.firm_rank)) | ///
            any(design.firm_rank :< 0) | any(design.firm_rank :> 1) | ///
            abs(design.ladder_down_share + ///
                design.ladder_lateral_share + ///
                design.ladder_up_share - 1) > 1e-12) {
            _error(3300, "ladder network design is invalid")
        }
    }
    else {
        if (design.ladder_down_share != 0 | ///
            design.ladder_lateral_share != 0 | ///
            design.ladder_up_share != 0 | design.ladder_band != 0 | ///
            any(design.firm_rank :< .)) {
            _error(3300, "block network design has ladder parameters")
        }
        if (design.block_count > min((workers, firms))) {
            _error(3300, "network blocks exceed workers or firms")
        }
        if (design.mode == "blocks" & design.bridge_count != 0) {
            _error(3300, "block network design has a bridge plan")
        }
        if (design.mode == "bridges") {
            if (design.block_log_bonus != 0 | ///
                design.bridge_count < design.block_count - 1 | ///
                any(missing(design.bridge_source_block)) | ///
                any(missing(design.bridge_target_block)) | ///
                any(design.bridge_source_block :< 1) | ///
                any(design.bridge_source_block :>= design.block_count) | ///
                any(design.bridge_target_block :!= ///
                    design.bridge_source_block :+ 1) | ///
                any(design.bridge_ledger[, 1] :!= ///
                    (1::design.bridge_count)) | ///
                any(design.bridge_ledger[, 7] :!= ///
                    design.bridge_source_block) | ///
                any(design.bridge_ledger[, 8] :!= ///
                    design.bridge_target_block)) {
                _error(3300, "bridge network plan is invalid")
            }
            if (design.bridge_phase >= 2 & ///
                (any(missing(design.bridge_plan_worker)) | ///
                any(missing(design.bridge_plan_output_period)) | ///
                any(missing(design.bridge_plan_internal_period)))) {
                _error(3300, "bridge execution plan is incomplete")
            }
            if (design.bridge_phase == 3 & ///
                (design.bridge_filled != design.bridge_count | ///
                any(missing(design.bridge_ledger)))) {
                _error(3300, "completed bridge ledger is incomplete")
            }
        }
    }
    if (design.prepared != 0 & design.prepared != 1) {
        _error(3300, "network design preparation flag is invalid")
    }
    if (design.prepared == 1) {
        if (rows(design.firm_cumulative) != design.block_count | ///
            cols(design.firm_cumulative) != firms | ///
            any(missing(design.firm_cumulative))) {
            _error(3300, "network destination tables are invalid")
        }
        for (block = 1; block <= design.block_count; block++) {
            if (firms == 1) {
                differences = design.firm_cumulative[block, .]
            }
            else {
                cumulative_row = design.firm_cumulative[block, .]
                differences = cumulative_row
                differences[|2 \ firms|] = ///
                    cumulative_row[|2 \ firms|] - ///
                    cumulative_row[|1 \ firms - 1|]
            }
            if (design.firm_cumulative[block, firms] <= 0 | ///
                any(differences :< 0)) {
                _error(3300, "network destination tables are invalid")
            }
        }
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
    real matrix ledger

    mode = strlower(strtrim(mode))
    if (missing(workers) | missing(firms) | workers < 1 | firms < 1 | ///
        workers != floor(workers) | firms != floor(firms) | ///
        (mode != "random" & mode != "blocks" & mode != "bridges")) {
        _error(3300, "network design inputs are invalid")
    }
    design.schema_version = fesim_netdesign_schema_version()
    design.mode = mode
    design.ladder_down_share = 0
    design.ladder_lateral_share = 0
    design.ladder_up_share = 0
    design.ladder_band = 0
    design.firm_rank = J(firms, 1, .)
    design.firm_cumulative = J(0, 0, .)
    design.bridge_phase = 0
    design.bridge_output_period = 0
    design.bridge_filled = 0
    design.bridge_source_block = J(0, 1, .)
    design.bridge_target_block = J(0, 1, .)
    design.bridge_plan_worker = J(0, 1, .)
    design.bridge_plan_output_period = J(0, 1, .)
    design.bridge_plan_internal_period = J(0, 1, .)
    design.bridge_candidate_output_period = J(workers, 1, .)
    design.bridge_candidate_internal_period = J(workers, 1, .)
    design.bridge_interval_count = J(workers, 1, 0)
    design.bridge_ledger = J(0, 8, .)
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
        if (mode == "blocks") design.bridge_count = 0
        else {
            if (block_log_bonus != 0 | ///
                bridge_count < block_count - 1 | bridge_count > workers) {
                _error(3300, "bridge network design inputs are invalid")
            }
            design.bridge_source_block = 1 :+ ///
                mod((0::(bridge_count - 1)), block_count - 1)
            design.bridge_target_block = design.bridge_source_block :+ 1
            design.bridge_plan_worker = J(bridge_count, 1, .)
            design.bridge_plan_output_period = J(bridge_count, 1, .)
            design.bridge_plan_internal_period = J(bridge_count, 1, .)
            ledger = J(bridge_count, 8, .)
            ledger[, 1] = (1::bridge_count)
            ledger[, 7] = design.bridge_source_block
            ledger[, 8] = design.bridge_target_block
            design.bridge_ledger = ledger
        }
    }
    design.validated = 1
    fesim_netdesign_validate(design)
    return(design)
}

real colvector fesim_netdesign_midranks(real colvector firm_effect)
{
    real scalar firms
    real scalar group
    real scalar first
    real scalar last
    real colvector rank
    real matrix info
    real matrix sorted

    firms = rows(firm_effect)
    if (cols(firm_effect) != 1 | firms < 1 | any(missing(firm_effect))) {
        _error(3300, "ladder firm effects are invalid")
    }
    sorted = sort((firm_effect, (1::firms)), (1, 2))
    info = panelsetup(sorted, 1)
    rank = J(firms, 1, .)
    for (group = 1; group <= rows(info); group++) {
        first = info[group, 1]
        last = info[group, 2]
        rank[sorted[first..last, 2]] = ///
            J(last - first + 1, 1, ((first + last) / 2 - .5) / firms)
    }
    return(rank)
}

struct fesim_network_design scalar fesim_netdesign_build_ladder(
    real scalar workers,
    real scalar firms,
    real scalar ladder_down_share,
    real scalar ladder_lateral_share,
    real scalar ladder_up_share,
    real scalar ladder_band,
    real colvector firm_effect,
    struct fesim_rng_state scalar rng_state)
{
    struct fesim_network_design scalar design

    if (missing(ladder_down_share) | missing(ladder_lateral_share) | ///
        missing(ladder_up_share) | missing(ladder_band) | ///
        ladder_down_share < 0 | ladder_down_share > 1 | ///
        ladder_lateral_share < 0 | ladder_lateral_share > 1 | ///
        ladder_up_share < 0 | ladder_up_share > 1 | ///
        abs(ladder_down_share + ladder_lateral_share + ///
            ladder_up_share - 1) > 1e-12 | ///
        ladder_band < 0 | ladder_band > 1 | ///
        rows(firm_effect) != firms) {
        _error(3300, "ladder network design inputs are invalid")
    }
    design = fesim_netdesign_build(
        "random", workers, firms, 1, 0, 0, rng_state)
    design.validated = 0
    design.mode = "ladder"
    design.ladder_down_share = ladder_down_share
    design.ladder_lateral_share = ladder_lateral_share
    design.ladder_up_share = ladder_up_share
    design.ladder_band = ladder_band
    design.firm_rank = fesim_netdesign_midranks(firm_effect)
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
    design.firm_cumulative = J(
        design.block_count, rows(firm_weight), .)
    for (block = 1; block <= design.block_count; block++) {
        if (design.mode == "bridges") {
            adjusted = firm_weight :* (design.firm_block :== block)
        }
        else {
            factor = exp(design.block_log_bonus)
            adjusted = firm_weight :* ///
                (1 :+ (factor - 1) :* (design.firm_block :== block))
        }
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
    if (design.mode == "random" | design.mode == "ladder" | ///
        (design.mode == "blocks" & design.block_log_bonus == 0)) {
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
    if (design.mode == "random" | design.mode == "ladder" | ///
        (design.mode == "blocks" & design.block_log_bonus == 0)) {
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

real colvector fesim_netdesign_ladder_probs(
    struct fesim_network_design scalar design,
    real colvector ordinary_mass,
    real scalar current_firm)
{
    real scalar category
    real scalar firms
    real colvector available_share
    real colvector base_mass
    real colvector category_mass
    real colvector difference
    real colvector direction
    real colvector mask
    real colvector probability
    real colvector share

    fesim_netdesign_validate(design)
    firms = rows(design.firm_rank)
    if (design.mode != "ladder" | firms < 2 | ///
        cols(ordinary_mass) != 1 | rows(ordinary_mass) != firms | ///
        any(missing(ordinary_mass)) | any(ordinary_mass :< 0) | ///
        missing(current_firm) | current_firm < 1 | ///
        current_firm > firms | current_firm != floor(current_firm)) {
        _error(3300, "ladder destination probabilities are invalid")
    }
    base_mass = ordinary_mass
    base_mass[current_firm] = 0
    if (sum(base_mass) <= 0) {
        _error(3300, "ladder origin leaves no ordinary destination mass")
    }
    difference = design.firm_rank :- design.firm_rank[current_firm]
    direction = J(firms, 1, 0)
    direction = direction :- ///
        (difference :< -design.ladder_band - 1e-12)
    direction = direction :+ ///
        (difference :> design.ladder_band + 1e-12)
    direction[current_firm] = 2
    category_mass = (quadsum(base_mass :* (direction :== -1)) \
        quadsum(base_mass :* (direction :== 0)) \
        quadsum(base_mass :* (direction :== 1)))
    share = (design.ladder_down_share \
        design.ladder_lateral_share \
        design.ladder_up_share)
    available_share = share :* (category_mass :> 0)
    if (sum(available_share) <= 0) {
        _error(3300, "ladder shares assign no mass to an available direction")
    }
    available_share = available_share / sum(available_share)
    probability = J(firms, 1, 0)
    for (category = 1; category <= 3; category++) {
        if (available_share[category] > 0) {
            mask = direction :== category - 2
            probability = probability :+ base_mass :* mask :* ///
                (available_share[category] / category_mass[category])
        }
    }
    if (probability[current_firm] != 0 | ///
        abs(sum(probability) - 1) > 1e-10) {
        _error(3300, "ladder destination mixture is invalid")
    }
    return(probability)
}

real scalar fesim_netdesign_ladder_draw(
    real colvector probability,
    real scalar uniform_draw)
{
    real rowvector cumulative

    if (cols(probability) != 1 | rows(probability) < 1 | ///
        any(missing(probability)) | any(probability :< 0) | ///
        abs(sum(probability) - 1) > 1e-10 | missing(uniform_draw) | ///
        uniform_draw < 0 | uniform_draw >= 1) {
        _error(3300, "ladder inverse-CDF inputs are invalid")
    }
    cumulative = runningsum(probability')
    return(fesim_destination_prefix_index(
        cumulative, cols(cumulative), uniform_draw))
}

real colvector fesim_net_ladder_akm(
    struct fesim_network_design scalar design,
    real colvector firm_weight,
    real colvector current_firm,
    real colvector uniform_draw)
{
    real scalar draw
    real colvector destination
    real colvector probability

    fesim_netdesign_validate(design)
    if (design.mode != "ladder" | ///
        cols(firm_weight) != 1 | ///
        rows(firm_weight) != rows(design.firm_rank) | ///
        any(missing(firm_weight)) | any(firm_weight :<= 0) | ///
        cols(current_firm) != 1 | cols(uniform_draw) != 1 | ///
        rows(current_firm) != rows(uniform_draw) | ///
        any(missing(current_firm)) | ///
        any(current_firm :< 1) | ///
        any(current_firm :> rows(firm_weight)) | ///
        any(current_firm :!= floor(current_firm)) | ///
        any(missing(uniform_draw)) | any(uniform_draw :< 0) | ///
        any(uniform_draw :>= 1)) {
        _error(3300, "simple ladder destination inputs are invalid")
    }
    destination = J(rows(uniform_draw), 1, .)
    for (draw = 1; draw <= rows(uniform_draw); draw++) {
        probability = fesim_netdesign_ladder_probs(
            design, firm_weight, current_firm[draw])
        destination[draw] = fesim_netdesign_ladder_draw(
            probability, uniform_draw[draw])
    }
    return(destination)
}

real colvector fesim_net_ladder_emp(
    struct fesim_network_design scalar design,
    struct fesim_destination_tables scalar tables,
    real colvector worker_type_index,
    real colvector current_firm,
    real colvector uniform_draw)
{
    real scalar draw
    real colvector destination
    real colvector probability

    fesim_netdesign_validate(design)
    fesim_destination_assert_valid(tables)
    if (design.mode != "ladder" | tables.network_mode != "random" | ///
        rows(tables.firm_id) != rows(design.firm_rank) | ///
        cols(worker_type_index) != 1 | cols(current_firm) != 1 | ///
        cols(uniform_draw) != 1 | ///
        rows(worker_type_index) != rows(current_firm) | ///
        rows(worker_type_index) != rows(uniform_draw) | ///
        any(missing(worker_type_index)) | ///
        any(worker_type_index :< 1) | any(worker_type_index :> 5) | ///
        any(worker_type_index :!= floor(worker_type_index)) | ///
        any(missing(current_firm)) | any(current_firm :< 1) | ///
        any(current_firm :> rows(tables.firm_id)) | ///
        any(current_firm :!= floor(current_firm)) | ///
        any(missing(uniform_draw)) | any(uniform_draw :< 0) | ///
        any(uniform_draw :>= 1)) {
        _error(3300, "stylized ladder destination inputs are invalid")
    }
    destination = J(rows(uniform_draw), 1, .)
    for (draw = 1; draw <= rows(uniform_draw); draw++) {
        probability = fesim_destination_ee_probs(
            tables, worker_type_index[draw], current_firm[draw])
        probability = fesim_netdesign_ladder_probs(
            design, probability, current_firm[draw])
        destination[draw] = fesim_netdesign_ladder_draw(
            probability, uniform_draw[draw])
    }
    return(destination)
}

struct fesim_network_design scalar fesim_netdesign_begin_output(
    struct fesim_network_design scalar design,
    real scalar output_period)
{
    fesim_netdesign_validate(design)
    if (missing(output_period) | output_period < 1 | ///
        output_period != floor(output_period)) {
        _error(3300, "bridge output period is invalid")
    }
    design.bridge_output_period = output_period
    design.bridge_interval_count = J(
        rows(design.worker_block), 1, 0)
    fesim_netdesign_validate(design)
    return(design)
}

struct fesim_network_design scalar fesim_netdesign_set_bridge_phase(
    struct fesim_network_design scalar design,
    real scalar phase)
{
    fesim_netdesign_validate(design)
    if (design.mode != "bridges" | missing(phase) | ///
        phase < 0 | phase > 2 | phase != floor(phase)) {
        _error(3300, "bridge planning phase is invalid")
    }
    design.bridge_phase = phase
    fesim_netdesign_validate(design)
    return(design)
}

struct fesim_network_design scalar fesim_netdesign_note_candidates(
    struct fesim_network_design scalar design,
    real colvector direct_rows,
    real colvector current_firm,
    real scalar internal_period)
{
    real scalar i
    real scalar worker
    real colvector candidate_internal
    real colvector candidate_output

    fesim_netdesign_validate(design)
    if (design.mode != "bridges" | design.bridge_phase != 1 | ///
        design.bridge_output_period < 2 | ///
        cols(direct_rows) != 1 | cols(current_firm) != 1 | ///
        rows(direct_rows) != rows(current_firm) | ///
        any(missing(direct_rows)) | any(direct_rows :< 1) | ///
        any(direct_rows :> rows(design.worker_block)) | ///
        any(direct_rows :!= floor(direct_rows)) | ///
        any(missing(current_firm)) | any(current_firm :< 1) | ///
        any(current_firm :> rows(design.firm_block)) | ///
        any(current_firm :!= floor(current_firm)) | ///
        missing(internal_period) | internal_period < 1 | ///
        internal_period != floor(internal_period)) {
        _error(3300, "bridge candidate inputs are invalid")
    }
    candidate_output = design.bridge_candidate_output_period
    candidate_internal = design.bridge_candidate_internal_period
    for (i = 1; i <= rows(direct_rows); i++) {
        worker = direct_rows[i]
        if (design.worker_block[worker] != ///
            design.firm_block[current_firm[i]]) {
            _error(3300, "ordinary bridge candidate left its home block")
        }
        if (missing(candidate_internal[worker])) {
            candidate_output[worker] = ///
                design.bridge_output_period
            candidate_internal[worker] = internal_period
        }
    }
    design.bridge_candidate_output_period = candidate_output
    design.bridge_candidate_internal_period = candidate_internal
    return(design)
}

struct fesim_network_design scalar fesim_netdesign_finish_plan(
    struct fesim_network_design scalar design)
{
    real scalar bridge
    real scalar worker
    real colvector candidates
    real matrix ledger
    real colvector plan_internal
    real colvector plan_output
    real colvector plan_worker
    real colvector used
    real colvector selected_order

    fesim_netdesign_validate(design)
    if (design.mode != "bridges" | design.bridge_phase != 1) {
        _error(3300, "bridge plan is not ready for finalization")
    }
    used = J(rows(design.worker_block), 1, 0)
    plan_worker = design.bridge_plan_worker
    plan_output = design.bridge_plan_output_period
    plan_internal = design.bridge_plan_internal_period
    ledger = design.bridge_ledger
    for (bridge = 1; bridge <= design.bridge_count; bridge++) {
        candidates = selectindex(
            design.worker_block :== design.bridge_source_block[bridge] :& ///
            design.bridge_candidate_internal_period :< . :& used :== 0)
        if (!length(candidates)) {
            _error(3300, "insufficient eligible retained-sample EE events for bridge source block " + ///
                strofreal(design.bridge_source_block[bridge]))
        }
        selected_order = order((design.worker_priority[candidates], ///
            candidates), (1, 2))
        worker = candidates[selected_order[1]]
        used[worker] = 1
        plan_worker[bridge] = worker
        plan_output[bridge] = ///
            design.bridge_candidate_output_period[worker]
        plan_internal[bridge] = ///
            design.bridge_candidate_internal_period[worker]
        ledger[bridge, 2] = worker
        ledger[bridge, 3] = plan_output[bridge]
        ledger[bridge, 4] = plan_internal[bridge]
    }
    design.bridge_plan_worker = plan_worker
    design.bridge_plan_output_period = plan_output
    design.bridge_plan_internal_period = plan_internal
    design.bridge_ledger = ledger
    design.bridge_phase = 2
    design.bridge_output_period = 0
    design.bridge_interval_count = J(
        rows(design.worker_block), 1, 0)
    fesim_netdesign_validate(design)
    return(design)
}

real colvector fesim_netdesign_due_plan(
    struct fesim_network_design scalar design,
    real colvector direct_rows,
    real scalar internal_period)
{
    real scalar i
    real colvector due
    real colvector found

    fesim_netdesign_validate(design)
    if (design.mode != "bridges" | design.bridge_phase != 2 | ///
        design.bridge_output_period < 2 | cols(direct_rows) != 1 | ///
        any(missing(direct_rows)) | any(direct_rows :< 1) | ///
        any(direct_rows :> rows(design.worker_block)) | ///
        any(direct_rows :!= floor(direct_rows)) | ///
        missing(internal_period) | internal_period < 1 | ///
        internal_period != floor(internal_period)) {
        _error(3300, "bridge execution inputs are invalid")
    }
    due = J(rows(direct_rows), 1, .)
    for (i = 1; i <= rows(direct_rows); i++) {
        found = selectindex(
            design.bridge_plan_worker :== direct_rows[i] :& ///
            design.bridge_plan_output_period :== ///
                design.bridge_output_period :& ///
            design.bridge_plan_internal_period :== internal_period)
        if (length(found) > 1) {
            _error(3300, "worker has duplicate bridge assignments")
        }
        if (length(found)) due[i] = found[1]
    }
    return(due)
}

struct fesim_network_design scalar fesim_netdesign_record_bridge(
    struct fesim_network_design scalar design,
    real scalar bridge,
    real scalar worker,
    real scalar source_firm,
    real scalar target_firm)
{
    real matrix ledger
    real colvector interval_count

    fesim_netdesign_validate(design)
    if (design.mode != "bridges" | design.bridge_phase != 2 | ///
        missing(bridge) | bridge < 1 | bridge > design.bridge_count | ///
        bridge != floor(bridge) | missing(worker) | worker < 1 | ///
        worker > rows(design.worker_block) | worker != floor(worker) | ///
        design.bridge_plan_worker[bridge] != worker | ///
        design.bridge_plan_output_period[bridge] != ///
            design.bridge_output_period | ///
        missing(source_firm) | source_firm < 1 | ///
        source_firm > rows(design.firm_block) | ///
        source_firm != floor(source_firm) | missing(target_firm) | ///
        target_firm < 1 | target_firm > rows(design.firm_block) | ///
        target_firm != floor(target_firm) | ///
        design.firm_block[source_firm] != ///
            design.bridge_source_block[bridge] | ///
        design.firm_block[target_firm] != ///
            design.bridge_target_block[bridge] | ///
        !missing(design.bridge_ledger[bridge, 5]) | ///
        design.bridge_interval_count[worker] != 0) {
        _error(3300, "recorded bridge transition is invalid")
    }
    ledger = design.bridge_ledger
    interval_count = design.bridge_interval_count
    ledger[bridge, 5] = source_firm
    ledger[bridge, 6] = target_firm
    interval_count[worker] = 1
    design.bridge_ledger = ledger
    design.bridge_interval_count = interval_count
    design.bridge_filled = design.bridge_filled + 1
    fesim_netdesign_validate(design)
    return(design)
}

struct fesim_network_design scalar fesim_netdesign_assert_complete(
    struct fesim_network_design scalar design)
{
    fesim_netdesign_validate(design)
    if (design.mode != "bridges" | design.bridge_phase != 2 | ///
        design.bridge_filled != design.bridge_count | ///
        any(missing(design.bridge_ledger))) {
        _error(3300, "bridge execution did not complete its exact plan")
    }
    design.bridge_phase = 3
    fesim_netdesign_validate(design)
    return(design)
}

end
