version 16.0
clear all
set more off
args root sha workers record result
capture log close _all
log using `"`result'.stata.log"', text replace
quietly adopath ++ `"`root'"'
quietly _fesim_load
mata:
void fesim_benchmark_bm_events(real scalar workers, real scalar record)
{
    struct fesim_bm_solution scalar s
    struct fesim_bm_firms scalar f
    struct fesim_bm_state scalar state
    struct fesim_bm_history scalar h
    struct fesim_bm_panel scalar p
    struct fesim_rng_state scalar rng
    real rowvector timers
    real scalar simulation, aggregation
    timers = fesim_runtime_claim_timers(2)
    s = fesim_bm_solve(.4,1,1,.5,.2,.05,1001,4000,1e-9)
    rng = fesim_rng_init(20260905,1)
    f = fesim_bm_construct_firms(s,500,"quantile",rng,1e-9)
    state = fesim_bm_initialize_state(s,f,workers,"stationary",rng,1e-9)
    fesim_runtime_start(timers[1])
    h = fesim_bm_simulate_events(s,f,state.employed,state.firm_id,
        state.spell_id,state.tenure,state.unemployment_duration,
        10,record,10000000,rng,1e-9)
    simulation = fesim_runtime_stop(timers[1])
    aggregation = 0
    if (record) {
        fesim_runtime_start(timers[2])
        p = fesim_bm_aggregate_history(s,f,h,"year",10,1e-9)
        aggregation = fesim_runtime_stop(timers[2])
    }
    st_matrix("benchmark", (simulation, aggregation, h.total_events,
        rows(h.events)*cols(h.events)*8, sum(h.final_employed),
        sum(h.final_firm_id), sum(h.final_transitions)))
    fesim_runtime_release(timers)
}
fesim_benchmark_bm_events(strtoreal(st_local("workers")),strtoreal(st_local("record")))
end
tempname handle
file open `handle' using `"`result'"', write text replace
file write `handle' "{" _n
file write `handle' `"  "sha": "`sha'","' _n
file write `handle' `"  "status": "passed","' _n
file write `handle' `"  "workers": `workers',"' _n
file write `handle' `"  "record_events": `record',"' _n
local column 0
foreach name in simulation_seconds aggregation_seconds events ledger_bytes final_employed final_firm_sum {
    local ++column
    local numeric = strtrim(string(benchmark[1,`column'], "%21.15f"))
    file write `handle' `"  "`name'": `numeric',"' _n
}
file write `handle' `"  "transitions": `=benchmark[1,7]'"' _n
file write `handle' "}" _n
file close `handle'
di as result "FESIM BM EVENT BENCHMARK PASS"
exit 0, STATA clear
