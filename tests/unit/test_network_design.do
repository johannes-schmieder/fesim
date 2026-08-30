version 16.0
clear all
set more off
set varabbrev off

mata:
assert(fesim_netdesign_schema_version() == 1)

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
end

capture mata: fesim_netdesign_build( ///
    "blocks", 3, 3, 4, ln(9), 0, fesim_rng_init(1, 1))
assert _rc == 3300
capture mata: fesim_netdesign_build( ///
    "blocks", 8, 8, 4, -1, 0, fesim_rng_init(1, 1))
assert _rc == 3300

di as result "FESIM NETWORK-DESIGN UNIT TESTS PASS"
