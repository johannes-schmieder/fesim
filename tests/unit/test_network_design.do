version 16.0
clear all
set more off
set varabbrev off

mata:
assert(fesim_netdesign_schema_version() == 3)

random_rng = fesim_rng_init(24680, 1)
random_design = fesim_netdesign_build(
    "random", 12, 8, 4, ln(9), 0, random_rng)
assert(random_design.mode == "random")
assert(random_design.block_count == 1)
assert(all(random_design.worker_block :== 1))
assert(all(random_design.firm_block :== 1))
random_after = fesim_rng_runiform(random_rng, "network_design", 20, 1)
random_baseline_rng = fesim_rng_init(24680, 1)
random_baseline = fesim_rng_runiform(
    random_baseline_rng, "network_design", 20, 1)
assert(random_after == random_baseline)

ladder_effect = (-2 \ -1 \ -.5 \ 0 \ .05 \ .1 \ .2 \ .3 \ .4 \ .5)
assert(fesim_netdesign_midranks((0 \ 0 \ 1 \ 2)) == ///
    (.25 \ .25 \ .625 \ .875))
ladder_rng = fesim_rng_init(24680, 1)
ladder_design = fesim_netdesign_build_ladder(
    12, 10, .1, .2, .7, .1, ladder_effect, ladder_rng)
assert(ladder_design.mode == "ladder")
assert(ladder_design.block_count == 1)
assert(ladder_design.ladder_down_share == .1)
assert(ladder_design.ladder_lateral_share == .2)
assert(ladder_design.ladder_up_share == .7)
assert(ladder_design.ladder_band == .1)
ladder_after = fesim_rng_runiform(ladder_rng, "network_design", 20, 1)
assert(ladder_after == random_baseline)
ladder_weight = (1::10)
ladder_weight = ladder_weight / sum(ladder_weight)
fesim_netdesign_prepare(ladder_design, ladder_weight)
ladder_probability = fesim_netdesign_ladder_probs(
    ladder_design, ladder_weight, 5)
ladder_difference = ladder_design.firm_rank :- ///
    ladder_design.firm_rank[5]
ladder_direction = J(10, 1, 0) :- ///
    (ladder_difference :< -ladder_design.ladder_band - 1e-12) :+ ///
    (ladder_difference :> ladder_design.ladder_band + 1e-12)
assert(abs(quadsum(ladder_probability :* (ladder_direction :== -1)) - .1) < 1e-12)
assert(abs(quadsum(ladder_probability :* (ladder_direction :== 0)) - .2) < 1e-12)
assert(abs(quadsum(ladder_probability :* (ladder_direction :== 1)) - .7) < 1e-12)
assert(abs(ladder_probability[1] / ladder_probability[2] - ///
    ladder_weight[1] / ladder_weight[2]) < 1e-12)
assert(ladder_probability[5] == 0)

boundary_probability = fesim_netdesign_ladder_probs(
    ladder_design, ladder_weight, 1)
boundary_difference = ladder_design.firm_rank :- ///
    ladder_design.firm_rank[1]
boundary_lateral = abs(boundary_difference) :<= ///
    ladder_design.ladder_band + 1e-12
boundary_up = boundary_difference :> ladder_design.ladder_band + 1e-12
assert(abs(quadsum(boundary_probability :* boundary_lateral) - 2 / 9) < 1e-12)
assert(abs(quadsum(boundary_probability :* boundary_up) - 7 / 9) < 1e-12)

ladder_uniform = ((.5::99999.5) / 100000)
ladder_current = J(100000, 1, 5)
ladder_sample = fesim_net_ladder_akm(
    ladder_design, ladder_weight, ladder_current, ladder_uniform)
sample_direction = ladder_design.firm_rank[ladder_sample] :- ///
    ladder_design.firm_rank[5]
assert(abs(mean(sample_direction :< ///
    -ladder_design.ladder_band - 1e-12) - .1) < 2e-5)
assert(abs(mean(abs(sample_direction) :<= ///
    ladder_design.ladder_band + 1e-12) - .2) < 2e-5)
assert(abs(mean(sample_direction :> ///
    ladder_design.ladder_band + 1e-12) - .7) < 2e-5)

tied_design = fesim_netdesign_build_ladder(
    4, 4, .1, .2, .7, 0, (0 \ 0 \ 1 \ 2), ///
    fesim_rng_init(55, 1))
fesim_netdesign_prepare(tied_design, J(4, 1, .25))
tied_probability = fesim_netdesign_ladder_probs(
    tied_design, J(4, 1, .25), 1)
assert(abs(tied_probability[2] - 2 / 9) < 1e-12)
assert(abs(tied_probability[3] + tied_probability[4] - 7 / 9) < 1e-12)

block_rng_a = fesim_rng_init(13579, 1)
block_design_a = fesim_netdesign_build(
    "blocks", 23, 11, 4, ln(9), 0, block_rng_a)
block_rng_b = fesim_rng_init(13579, 1)
block_design_b = fesim_netdesign_build(
    "blocks", 23, 11, 4, ln(9), 0, block_rng_b)
assert(block_design_a.worker_block == block_design_b.worker_block)
assert(block_design_a.firm_block == block_design_b.firm_block)
assert(block_design_a.worker_priority == block_design_b.worker_priority)
assert(sort(block_design_a.worker_priority, 1) == (1::23))
worker_counts = J(4, 1, .)
firm_counts = J(4, 1, .)
for (block = 1; block <= 4; block++) {
    worker_counts[block] = sum(block_design_a.worker_block :== block)
    firm_counts[block] = sum(block_design_a.firm_block :== block)
}
assert(max(worker_counts) - min(worker_counts) <= 1)
assert(max(firm_counts) - min(firm_counts) <= 1)

equal_weights = J(11, 1, 1 / 11)
fesim_netdesign_prepare(block_design_a, equal_weights)
assert(block_design_a.prepared == 1)
for (block = 1; block <= 4; block++) {
    block_probability = fesim_netdesign_common_probs(block_design_a, block)
    assert(abs(sum(block_probability) - 1) < 1e-12)
    assert(sum(select(block_probability, ///
        block_design_a.firm_block :== block)) > .65)
}

zero_rng = fesim_rng_init(86420, 1)
zero_design = fesim_netdesign_build(
    "blocks", 20, 8, 4, 0, 0, zero_rng)
zero_weights = (1::8)
zero_weights = zero_weights / sum(zero_weights)
fesim_netdesign_prepare(zero_design, zero_weights)
uniforms = ((.5::199.5) / 200)
reference_blocks = J(200, 1, 2)
current_firms = 1 :+ mod((0::199), 8)
assert(fesim_netdesign_sample_common(
    zero_design, zero_weights, reference_blocks, uniforms) ==
    fesim_destination_sample_common(zero_weights, uniforms))
assert(fesim_netdesign_sample_excl(
    zero_design, zero_weights, reference_blocks, current_firms, uniforms) ==
    fesim_destination_sample_excl(zero_weights, current_firms, uniforms))
assert(all(fesim_netdesign_sample_excl(
    zero_design, zero_weights, reference_blocks, current_firms, uniforms) :!=
    current_firms))

bridge_rng = fesim_rng_init(112233, 1)
bridge_design = fesim_netdesign_build(
    "bridges", 24, 12, 4, 0, 3, bridge_rng)
bridge_weights = J(12, 1, 1 / 12)
fesim_netdesign_prepare(bridge_design, bridge_weights)
assert(bridge_design.bridge_source_block == (1::3))
assert(bridge_design.bridge_target_block == (2::4))
for (block = 1; block <= 4; block++) {
    block_probability = fesim_netdesign_common_probs(bridge_design, block)
    assert(abs(sum(block_probability) - 1) < 1e-12)
    assert(sum(select(block_probability, ///
        bridge_design.firm_block :!= block)) == 0)
}
bridge_current = J(24, 1, .)
for (worker = 1; worker <= 24; worker++) {
    block_firms = selectindex(
        bridge_design.firm_block :== bridge_design.worker_block[worker])
    bridge_current[worker] = block_firms[1]
}
bridge_design = fesim_netdesign_set_bridge_phase(bridge_design, 1)
bridge_design = fesim_netdesign_begin_output(bridge_design, 2)
bridge_design = fesim_netdesign_note_candidates(
    bridge_design, (1::24), bridge_current, 10)
bridge_design = fesim_netdesign_finish_plan(bridge_design)
assert(length(uniqrows(bridge_design.bridge_plan_worker)) == 3)
for (bridge = 1; bridge <= 3; bridge++) {
    candidates = selectindex(bridge_design.worker_block :== bridge)
    selected_order = order((bridge_design.worker_priority[candidates], ///
        candidates), (1, 2))
    assert(bridge_design.bridge_plan_worker[bridge] == ///
        candidates[selected_order[1]])
}
bridge_design = fesim_netdesign_begin_output(bridge_design, 2)
due = fesim_netdesign_due_plan(
    bridge_design, bridge_design.bridge_plan_worker, 10)
assert(due == (1::3))
for (bridge = 1; bridge <= 3; bridge++) {
    worker = bridge_design.bridge_plan_worker[bridge]
    source_firms = selectindex(bridge_design.firm_block :== ///
        bridge_design.bridge_source_block[bridge])
    target_firms = selectindex(bridge_design.firm_block :== ///
        bridge_design.bridge_target_block[bridge])
    bridge_design = fesim_netdesign_record_bridge(
        bridge_design, bridge, worker, source_firms[1], target_firms[1])
}
bridge_design = fesim_netdesign_assert_complete(bridge_design)
assert(bridge_design.bridge_phase == 3)
assert(bridge_design.bridge_filled == 3)
assert(sum(bridge_design.bridge_interval_count) == 3)
assert(!any(missing(bridge_design.bridge_ledger)))
infeasible_ladder = fesim_netdesign_build_ladder(
    8, 8, 1, 0, 0, 0, (1::8), fesim_rng_init(1, 1))
fesim_netdesign_prepare(infeasible_ladder, J(8, 1, .125))
end

capture mata: fesim_netdesign_build( ///
    "blocks", 3, 3, 4, ln(9), 0, fesim_rng_init(1, 1))
assert _rc == 3300
capture mata: fesim_netdesign_build( ///
    "blocks", 8, 8, 4, -1, 0, fesim_rng_init(1, 1))
assert _rc == 3300
capture mata: fesim_netdesign_build_ladder( ///
    8, 8, .1, .2, .6, .1, (1::8), fesim_rng_init(1, 1))
assert _rc == 3300
capture mata: fesim_netdesign_ladder_probs( ///
    infeasible_ladder, J(8, 1, .125), 1)
assert _rc == 3300

di as result "FESIM NETWORK-DESIGN UNIT TESTS PASS"
