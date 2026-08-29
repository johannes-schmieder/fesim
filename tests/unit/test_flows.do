version 16.0
clear all
set more off
set varabbrev off

mata:
assert(fesim_flow_schema_version() == 1)

flow_observed = (
    1, 1, 1, 1, 2.1, 1, 0, 0 \
    1, 2, ., 0,   ., ., ., 1 \
    1, 3, 1, 1, 2.2, 2, 0, 1 \
    1, 4, 1, 1, 2.3, 3, 0, 2 \
    2, 1, 2, 1, 2.4, 1, 0, 0 \
    2, 2, 3, 1, 2.5, 2, 0, 1 \
    2, 3, 3, 1, 2.6, 2, 1, 0 \
    2, 4, ., 0,   ., ., ., 1)

flow_actual = fesim_finalize_flows(flow_observed, 4)
flow_expected = (
    ., ., 1, ., . \
    0,  0, 0,  0, 1 \
    1,  1, 0,  0, 1 \
    1,  0, .,  0, 2 \
    ., ., 0,  ., . \
    1,  0, 0,  1, 1 \
    0,  0, 1,  0, 0 \
    0,  0, .,  0, 1)
assert(mreldif(flow_actual, flow_expected) == 0)

/* Same-firm return after nonemployment is a new spell, not job-to-job. */
assert(flow_actual[3, 1] == 1)
assert(flow_actual[3, 2] == 1)
assert(flow_actual[3, 4] == 0)

/* Two latent moves can imply a new spell with the same observed firm. */
assert(flow_actual[4, 1] == 1)
assert(flow_actual[4, 4] == 0)
assert(flow_actual[4, 5] == 2)

single_observed = (1, 1, 1, 1, 2.1, 1, 0, 0)
single_flows = fesim_finalize_flows(single_observed, 1)
assert(all(missing(single_flows)))
end

mata: bad_flow = flow_observed; bad_flow[2, 1] = 2
capture mata: fesim_finalize_flows(bad_flow, 4)
assert _rc == 3300

mata: bad_flow = flow_observed; bad_flow[3, 3] = .
capture mata: fesim_finalize_flows(bad_flow, 4)
assert _rc == 3300

mata: bad_flow = flow_observed; bad_flow[4, 8] = 1.5
capture mata: fesim_finalize_flows(bad_flow, 4)
assert _rc == 3300

capture mata: fesim_finalize_flows(flow_observed, 3)
assert _rc == 3300

di as result "FESIM COMMON FLOW FINALIZATION TESTS PASS"
