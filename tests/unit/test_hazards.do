version 16.0
clear all
set more off
set varabbrev off

mata:
assert(fesim_hazard_schema_version() == 1)

duration = (0 \ .25 \ 1 \ 4)
assert(fesim_hazard_duration_transform(duration) == ln(1 :+ duration))

z = (-1 \ 0 \ 1)
q = (1 \ 0 \ -1)
d = (0 \ 1 \ 3)
employed_log = fesim_hazard_employed_log(-2, .3, z, -.2, q, .5, d)
assert(mreldif(employed_log, -2 :+ .3 :* z :- .2 :* q :+ ///
    .5 :* ln(1 :+ d)) < 1e-15)
unemployed_log = fesim_hazard_unemployed_log(-1, .4, z, -.3, d)
assert(mreldif(unemployed_log, -1 :+ .4 :* z :- .3 :* ln(1 :+ d)) < 1e-15)

zero_one = fesim_hazard_one_from_rates(J(3, 1, 0), 1 / 12)
assert(zero_one == J(3, 1, 0))
constant_one = fesim_hazard_one_from_rates(J(3, 1, .7), 1 / 12)
assert(max(abs(constant_one :- (1 - exp(-.7 / 12)))) < 1e-15)
assert(abs((1 - constant_one[1])^12 - exp(-.7)) < 1e-14)

heterogeneous_log = ln((.01 \ .7 \ 10))
heterogeneous = fesim_hazard_one_from_log(heterogeneous_log, 1 / 12)
assert(max(abs(heterogeneous :- (1 :- exp(-(1 / 12) :* exp(heterogeneous_log))))) < 1e-14)
extreme = fesim_hazard_one_from_log((-1000 \ 1000), 1 / 12)
assert(extreme == (0 \ 1))
extreme_rates = fesim_hazard_one_from_rates((0 \ 1e300), 1 / 12)
assert(extreme_rates == (0 \ 1))

zero_competing = fesim_hazard_competing_rates(J(2, 1, 0), ///
    J(2, 1, 0), 1 / 12)
assert(zero_competing[, 1..2] == J(2, 2, 0))
assert(zero_competing[, 3] == J(2, 1, 1))
competing = fesim_hazard_competing_rates((.2 \ .4), (.3 \ .1), 1 / 12)
assert(max(abs(rowsum(competing) :- 1)) < 1e-15)
assert(abs(competing[1, 1] / competing[1, 2] - 2 / 3) < 1e-14)
assert(abs(competing[2, 1] / competing[2, 2] - 4) < 1e-14)
assert(abs(competing[1, 3]^12 - exp(-.5)) < 1e-14)

log_competing = fesim_hazard_competing_from_log(ln((.2 \ .4)), ///
    ln((.3 \ .1)), 1 / 12)
assert(mreldif(log_competing, competing) < 1e-14)
extreme_competing = fesim_hazard_competing_from_log((1000 \ -1000), ///
    (999 \ -1000), 1 / 12)
assert(max(abs(rowsum(extreme_competing) :- 1)) < 1e-15)
assert(extreme_competing[1, 3] == 0)
assert(extreme_competing[1, 1] > extreme_competing[1, 2])
assert(extreme_competing[2, 1] == 0 & extreme_competing[2, 2] == 0)
assert(extreme_competing[2, 3] == 1)
extreme_rate_competing = fesim_hazard_competing_rates((1e300 \ 0), ///
    (1e300 \ 1e300), 1 / 12)
assert(extreme_rate_competing[1, 1] == .5)
assert(extreme_rate_competing[1, 2] == .5)
assert(extreme_rate_competing[1, 3] == 0)
assert(extreme_rate_competing[2, 1] == 0)
assert(extreme_rate_competing[2, 2] == 1)
assert(extreme_rate_competing[2, 3] == 0)
end

capture mata: fesim_hazard_duration_transform((-1 \ 0))
assert _rc == 3300
capture mata: fesim_hazard_employed_log(0, 0, (1 \ 2), 0, 1, 0, (0 \ 0))
assert _rc == 3300
capture mata: fesim_hazard_unemployed_log(0, 0, (1 \ .), 0, (0 \ 0))
assert _rc == 3300
capture mata: fesim_hazard_one_from_rates((-1 \ 0), 1 / 12)
assert _rc == 3300
capture mata: fesim_hazard_one_from_log((0 \ .), 1 / 12)
assert _rc == 3300
capture mata: fesim_hazard_competing_rates((.1 \ .2), .1, 1 / 12)
assert _rc == 3300
capture mata: fesim_hazard_competing_from_log((0 \ 0), (0 \ 0), 0)
assert _rc == 3300

di as result "FESIM EMPIRICAL HAZARD ENGINE TESTS PASS"
