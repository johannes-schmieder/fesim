version 16.0
clear all
set more off
set varabbrev off

args repository_root source_sha requested_workers requested_firms ///
    requested_periods requested_truth result_path
local workers = real(`"`requested_workers'"')
local firms = real(`"`requested_firms'"')
local periods = real(`"`requested_periods'"')
local truth = lower(strtrim(`"`requested_truth'"'))
if `"`repository_root'"' == "" | `"`source_sha'"' == "" | ///
    missing(`workers') | missing(`firms') | missing(`periods') | ///
    !inlist(`"`truth'"', "none", "basic", "full") | ///
    `"`result_path'"' == "" {
    di as error "benchmark_public.do received invalid arguments"
    exit 198
}

quietly adopath ++ `"`repository_root'"'
timer clear 1
timer on 1
quietly fesim, dgp(akm) preset(simple) workers(`workers') ///
    firms(`firms') periods(`periods') seed(20260829) ///
    truth(`truth') connectivity(keep) noreport clear
local N = r(N)
local runtime_total = r(runtime_total)
local runtime_solve = r(runtime_solve)
local runtime_simulate = r(runtime_simulate)
local runtime_output = r(runtime_output)
local components = r(components)
matrix benchmark_network = r(network)
matrix benchmark_leaveout = r(leaveout)
local edges = benchmark_network["edges", "generated"]
local employed_observations = ///
    benchmark_network["employed_observations", "generated"]
foreach metric in worker_cut_vertices worker_set_observations ///
    worker_set_workers worker_set_firms worker_set_matches ///
    vulnerable_matches_largest vulnerable_matches_worker_set ///
    worker_out_connected match_out_connected {
    local `metric' = benchmark_leaveout["`metric'", "value"]
}
local worker_set_observation_share = ///
    benchmark_leaveout["worker_set_observation_share", "value"]
local vulnerable_match_share_largest = ///
    benchmark_leaveout["vulnerable_match_share_largest", "value"]
local vulnerable_match_share_worker = ///
    benchmark_leaveout["vulnerable_match_share_worker", "value"]
timer off 1
quietly timer list 1
local command_seconds = r(t1)
quietly describe, short
local data_width = r(width)
local dataset_bytes = `N' * `data_width'
local json_command_seconds = ///
    strtrim(string(`command_seconds', "%21.15f"))
local json_runtime_total = strtrim(string(`runtime_total', "%21.15f"))
local json_runtime_solve = strtrim(string(`runtime_solve', "%21.15f"))
local json_runtime_simulate = ///
    strtrim(string(`runtime_simulate', "%21.15f"))
local json_runtime_output = strtrim(string(`runtime_output', "%21.15f"))
local json_worker_obs_share "null"
if `worker_set_observation_share' < . local json_worker_obs_share = ///
    strtrim(string(`worker_set_observation_share', "%21.15f"))
local json_vuln_share_largest "null"
if `vulnerable_match_share_largest' < . local json_vuln_share_largest = ///
    strtrim(string(`vulnerable_match_share_largest', "%21.15f"))
local json_vuln_share_worker "null"
if `vulnerable_match_share_worker' < . local json_vuln_share_worker = ///
    strtrim(string(`vulnerable_match_share_worker', "%21.15f"))

tempname result_file
file open `result_file' using `"`result_path'"', write text replace
file write `result_file' "{" _n
file write `result_file' `"  "sha": "`source_sha'","' _n
file write `result_file' `"  "workers": `workers',"' _n
file write `result_file' `"  "firms": `firms',"' _n
file write `result_file' `"  "periods": `periods',"' _n
file write `result_file' `"  "truth": "`truth'","' _n
file write `result_file' `"  "observations": `N',"' _n
file write `result_file' `"  "data_width_bytes": `data_width',"' _n
file write `result_file' `"  "dataset_bytes": `dataset_bytes',"' _n
file write `result_file' `"  "components": `components',"' _n
file write `result_file' `"  "edges": `edges',"' _n
file write `result_file' ///
    `"  "employed_observations": `employed_observations',"' _n
file write `result_file' ///
    `"  "worker_cut_vertices": `worker_cut_vertices',"' _n
file write `result_file' ///
    `"  "worker_set_observations": `worker_set_observations',"' _n
file write `result_file' ///
    `"  "worker_set_workers": `worker_set_workers',"' _n
file write `result_file' ///
    `"  "worker_set_firms": `worker_set_firms',"' _n
file write `result_file' ///
    `"  "worker_set_matches": `worker_set_matches',"' _n
file write `result_file' ///
    `"  "worker_set_observation_share": `json_worker_obs_share',"' _n
file write `result_file' ///
    `"  "vulnerable_matches_largest": `vulnerable_matches_largest',"' _n
file write `result_file' ///
    `"  "vulnerable_match_share_largest": `json_vuln_share_largest',"' _n
file write `result_file' ///
    `"  "vulnerable_matches_worker_set": `vulnerable_matches_worker_set',"' _n
file write `result_file' ///
    `"  "vulnerable_match_share_worker": `json_vuln_share_worker',"' _n
file write `result_file' ///
    `"  "worker_out_connected": `worker_out_connected',"' _n
file write `result_file' ///
    `"  "match_out_connected": `match_out_connected',"' _n
file write `result_file' ///
    `"  "command_seconds": `json_command_seconds',"' _n
file write `result_file' `"  "runtime_total": `json_runtime_total',"' _n
file write `result_file' `"  "runtime_solve": `json_runtime_solve',"' _n
file write `result_file' ///
    `"  "runtime_simulate": `json_runtime_simulate',"' _n
file write `result_file' `"  "runtime_output": `json_runtime_output'"' _n
file write `result_file' "}" _n
file close `result_file'

di as result "FESIM PUBLIC BENCHMARK PASS: `result_path'"
