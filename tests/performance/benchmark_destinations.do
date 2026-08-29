version 16.0
clear all
set more off
set varabbrev off

args repository_root source_sha requested_firms requested_draws result_path
local firms = real(`"`requested_firms'"')
local draws = real(`"`requested_draws'"')
if `"`repository_root'"' == "" | `"`source_sha'"' == "" | ///
    missing(`firms') | `firms' < 2 | `firms' != floor(`firms') | ///
    missing(`draws') | `draws' < 1 | `draws' != floor(`draws') | ///
    `"`result_path'"' == "" {
    di as error "benchmark_destinations.do received invalid arguments"
    exit 198
}

quietly adopath ++ `"`repository_root'"'
quietly _fesim_load

mata:
firm_count = strtoreal(st_local("requested_firms"))
draw_count = strtoreal(st_local("requested_draws"))
benchmark_firm_id = 1::firm_count
benchmark_firm_weight = 1 :+ mod(benchmark_firm_id, 17) / 17
benchmark_firm_quality = benchmark_firm_id :- mean(benchmark_firm_id)
benchmark_firm_quality = benchmark_firm_quality / ///
    sqrt(variance(benchmark_firm_quality))
benchmark_worker_type = 1 :+ mod((0::(draw_count - 1)), 5)
benchmark_current_firm = 1 :+ mod((0::(draw_count - 1)), firm_count)
benchmark_uniform = ((.5::(draw_count - .5)) / draw_count)
end

timer clear 1
timer on 1
mata: benchmark_tables = fesim_destination_build(benchmark_firm_id, ///
    benchmark_firm_weight, benchmark_firm_quality, .25, .10, .20, -.10)
timer off 1
quietly timer list 1
local build_seconds = r(t1)

timer clear 2
timer on 2
mata: benchmark_destination = fesim_destination_sample_ue( ///
    benchmark_tables, benchmark_worker_type, benchmark_uniform)
timer off 2
quietly timer list 2
local ue_seconds = r(t2)
mata: st_numscalar("benchmark_ue_valid", ///
    rows(benchmark_destination) == draw_count & ///
    all(benchmark_destination :>= 1 :& benchmark_destination :<= firm_count))
assert scalar(benchmark_ue_valid) == 1

timer clear 3
timer on 3
mata: benchmark_destination = fesim_destination_sample_ee( ///
    benchmark_tables, benchmark_worker_type, benchmark_current_firm, ///
    benchmark_uniform)
timer off 3
quietly timer list 3
local ee_seconds = r(t3)
mata: st_numscalar("benchmark_ee_valid", ///
    rows(benchmark_destination) == draw_count & ///
    all(benchmark_destination :>= 1 :& benchmark_destination :<= firm_count) & ///
    all(benchmark_destination :!= benchmark_current_firm))
assert scalar(benchmark_ee_valid) == 1

// Five firm vectors, three 5 x J tables, four 5-vectors, and six scalars.
local table_payload_bytes = 8 * (20 * `firms' + 26)

tempname result_file
file open `result_file' using `"`result_path'"', write text replace
file write `result_file' "{" _n
file write `result_file' `"  "sha": "`source_sha'","' _n
file write `result_file' `"  "firms": `firms',"' _n
file write `result_file' `"  "draws_per_kernel": `draws',"' _n
file write `result_file' `"  "worker_types": 5,"' _n
file write `result_file' `"  "table_payload_bytes": `table_payload_bytes',"' _n
file write `result_file' `"  "build_seconds": `build_seconds',"' _n
file write `result_file' `"  "ue_sample_seconds": `ue_seconds',"' _n
file write `result_file' `"  "ee_sample_seconds": `ee_seconds',"' _n
file write `result_file' `"  "current_firm_exclusion_verified": true"' _n
file write `result_file' "}" _n
file close `result_file'

di as result "FESIM DESTINATION BENCHMARK PASS: `result_path'"
