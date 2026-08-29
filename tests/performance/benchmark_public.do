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
local edges = benchmark_network["edges", "generated"]
local employed_observations = ///
    benchmark_network["employed_observations", "generated"]
timer off 1
quietly timer list 1
local command_seconds = r(t1)
quietly describe, short
local data_width = r(width)
local dataset_bytes = `N' * `data_width'

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
file write `result_file' `"  "command_seconds": `command_seconds',"' _n
file write `result_file' `"  "runtime_total": `runtime_total',"' _n
file write `result_file' `"  "runtime_solve": `runtime_solve',"' _n
file write `result_file' `"  "runtime_simulate": `runtime_simulate',"' _n
file write `result_file' `"  "runtime_output": `runtime_output'"' _n
file write `result_file' "}" _n
file close `result_file'

di as result "FESIM PUBLIC BENCHMARK PASS: `result_path'"
