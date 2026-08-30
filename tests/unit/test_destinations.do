version 16.0
clear all
set more off
set varabbrev off

mata:
assert(fesim_destination_schema_version() == 3)
assert(fesim_destination_type_support() == ///
    (-2, -1, 0, 1, 2) / sqrt(2))

firm_id = 1::4
firm_weight = (1 \ 2 \ 3 \ 4)
firm_quality = (-1.5 \ -.5 \ .5 \ 1.5)
zero = fesim_destination_build(firm_id, firm_weight, firm_quality, ///
    0, 0, 0, 0)
fesim_destination_assert_valid(zero)
for (type_index = 1; type_index <= 5; type_index++) {
    assert(mreldif(fesim_destination_ue_probs(zero, type_index), ///
        firm_weight / sum(firm_weight)) < 1e-15)
}

ue_draws = fesim_destination_sample_ue(zero, J(8, 1, 3), ///
    (0 \ .099999 \ .1 \ .299999 \ .3 \ .599999 \ .6 \ .999999))
assert(ue_draws == (1 \ 1 \ 2 \ 2 \ 3 \ 3 \ 4 \ 4))
common_draws = fesim_destination_sample_common(firm_weight, ///
    (0 \ .099999 \ .1 \ .299999 \ .3 \ .599999 \ .6 \ .999999))
assert(common_draws == ue_draws)
excluded_draws = fesim_destination_sample_excl((.1 \ .2 \ .7), ///
    (1 \ 1 \ 2 \ 2 \ 3 \ 3), (0 \ .3 \ .1 \ .2 \ .3 \ .4))
assert(excluded_draws == (2 \ 3 \ 1 \ 3 \ 1 \ 2))

for (current = 1; current <= 4; current++) {
    ee_probability = fesim_destination_ee_probs(zero, 3, current)
    expected = firm_weight
    expected[current] = 0
    expected = expected / sum(expected)
    assert(mreldif(ee_probability, expected) < 1e-15)
    assert(ee_probability[current] == 0)
    assert(abs(sum(ee_probability) - 1) < 1e-15)
}

equal_weight_neutral = fesim_destination_build(firm_id, J(4, 1, 1), ///
    firm_quality, 0, 0, 0, 0)
assert(mreldif(fesim_destination_ue_probs(equal_weight_neutral, 3), ///
    J(4, 1, .25)) < 1e-15)
equal_weight_ee = fesim_destination_ee_probs(equal_weight_neutral, 3, 2)
assert(equal_weight_ee[2] == 0)
assert(mreldif(equal_weight_ee[(1 \ 3 \ 4)], J(3, 1, 1 / 3)) < 1e-15)

current_firm = (1 \ 2 \ 3 \ 4 \ 1 \ 2 \ 3 \ 4)
ee_draws = fesim_destination_sample_ee(zero, J(8, 1, 3), ///
    current_firm, (0 \ .2 \ .4 \ .6 \ .8 \ .999999 \ .1 \ .9))
assert(all(ee_draws :!= current_firm))
assert(all(ee_draws :>= 1 :& ee_draws :<= 4))

sorted = fesim_destination_build(firm_id, J(4, 1, 1), firm_quality, ///
    1, 0, 0, 0)
low_type = fesim_destination_ue_probs(sorted, 1)
high_type = fesim_destination_ue_probs(sorted, 5)
assert(quadcross(high_type, firm_quality) > ///
    quadcross(low_type, firm_quality))

quality_preference = fesim_destination_build(firm_id, J(4, 1, 1), ///
    firm_quality, 0, 1, 0, 0)
neutral_mean = quadcross(fesim_destination_ue_probs(zero, 3), firm_quality)
quality_mean = quadcross(fesim_destination_ue_probs(quality_preference, 3), ///
    firm_quality)
assert(quality_mean > neutral_mean)

upward = fesim_destination_build(firm_id, J(4, 1, 1), firm_quality, ///
    0, 0, 2, -2)
neutral_ee = fesim_destination_ee_probs(zero, 3, 2)
upward_ee = fesim_destination_ee_probs(upward, 3, 2)
assert(quadcross(upward_ee, firm_quality) > ///
    quadcross(neutral_ee, firm_quality))
downward = fesim_destination_build(firm_id, J(4, 1, 1), firm_quality, ///
    0, 0, -2, 2)
downward_ee = fesim_destination_ee_probs(downward, 3, 2)
assert(quadcross(upward_ee, firm_quality) > ///
    quadcross(downward_ee, firm_quality))

extreme_quality = fesim_destination_build((1 \ 2 \ 3), J(3, 1, 1), ///
    (-1 \ 0 \ 1), 0, 1000, 1000, -1000)
extreme_ue = fesim_destination_ue_probs(extreme_quality, 3)
assert(all(extreme_ue :>= 0 :& extreme_ue :<= 1))
assert(sum(extreme_ue) == 1)
assert(extreme_ue[3] == 1)
extreme_ee = fesim_destination_ee_probs(extreme_quality, 3, 1)
assert(all(extreme_ee :>= 0 :& extreme_ee :<= 1))
assert(sum(extreme_ee) == 1)
assert(extreme_ee[1] == 0)

n_draws = 100000
uniform_grid = ((.5::(n_draws - .5)) / n_draws)
sampled = fesim_destination_sample_ue(zero, J(n_draws, 1, 3), uniform_grid)
for (firm = 1; firm <= 4; firm++) {
    realized = mean(sampled :== firm)
    assert(abs(realized - firm_weight[firm] / sum(firm_weight)) < 2 / n_draws)
}

sampled_low_type = fesim_destination_sample_ue(sorted, ///
    J(n_draws, 1, 1), uniform_grid)
sampled_high_type = fesim_destination_sample_ue(sorted, ///
    J(n_draws, 1, 5), uniform_grid)
assert(mean(firm_quality[sampled_high_type]) > ///
    mean(firm_quality[sampled_low_type]))

ee_sampled = fesim_destination_sample_ee(upward, J(n_draws, 1, 3), ///
    J(n_draws, 1, 2), uniform_grid)
ee_target = fesim_destination_ee_probs(upward, 3, 2)
assert(all(ee_sampled :!= 2))
for (firm = 1; firm <= 4; firm++) {
    realized = mean(ee_sampled :== firm)
    assert(abs(realized - ee_target[firm]) < 2 / n_draws)
}

large_firms = 10000
large_id = 1::large_firms
large_quality = (large_id :- mean(large_id)) / sqrt(variance(large_id))
large_table = fesim_destination_build(large_id, J(large_firms, 1, 1), ///
    large_quality, .25, .1, .2, -.1)
assert(rows(large_table.ue_cumulative) == 5)
assert(cols(large_table.ue_cumulative) == large_firms)
large_types = 1 :+ mod((0::9999), 5)
large_sample = fesim_destination_sample_ue(large_table, large_types, ///
    ((.5::9999.5) / 10000))
assert(rows(large_sample) == 10000)
assert(all(large_sample :>= 1 :& large_sample :<= large_firms))

one_firm = fesim_destination_build(1, 1, 0, 0, 0, 0, 0)
assert(fesim_destination_ue_probs(one_firm, 1) == 1)
end

capture mata: fesim_destination_build((1 \ 3), (1 \ 1), (0 \ 1), 0, 0, 0, 0)
assert _rc == 3300
capture mata: fesim_destination_build((1 \ 2), (1 \ 0), (0 \ 1), 0, 0, 0, 0)
assert _rc == 3300
capture mata: fesim_destination_sample_ue(zero, (1 \ 6), (0 \ .5))
assert _rc == 3300
capture mata: fesim_destination_sample_ue(zero, (1 \ 1), (0 \ 1))
assert _rc == 3300
capture mata: fesim_destination_sample_common((1 \ 0), (.5))
assert _rc == 3300
capture mata: fesim_destination_sample_excl((1 \ 0), 1, .5)
assert _rc == 3300
capture mata: fesim_destination_sample_ee(one_firm, 1, 1, .5)
assert _rc == 3300
capture mata: fesim_destination_ee_probs(zero, 3, 5)
assert _rc == 3300
capture mata: fesim_destination_build((1 \ 2), (1 \ 1), ///
    (-1e300 \ 1e300), 0, 1e300, 0, 0)
assert _rc == 3300

di as result "FESIM GROUPED DESTINATION ENGINE TESTS PASS"
