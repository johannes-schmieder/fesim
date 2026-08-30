version 16.0
clear all
set more off
set varabbrev off

args repository_root source_sha requested_workers requested_firms ///
    requested_periods result_path
local workers = real(`"`requested_workers'"')
local firms = real(`"`requested_firms'"')
local periods = real(`"`requested_periods'"')
if `"`repository_root'"' == "" | `"`source_sha'"' == "" | ///
    missing(`workers') | missing(`firms') | missing(`periods') | ///
    `"`result_path'"' == "" {
    di as error "benchmark_network_ladder.do received invalid arguments"
    exit 198
}

quietly adopath ++ `"`repository_root'"'
foreach preset in simple stylized {
    foreach design in random ladder {
        local preset_key = cond(`"`preset'"' == "simple", "s", "e")
        local design_key = cond(`"`design'"' == "random", "r", "l")
        local key `"`preset_key'`design_key'"'
        timer clear 1
        timer on 1
        di as txt "benchmarking akm/`preset' network(`design')"
        capture quietly fesim, dgp(akm) preset(`preset') network(`design') ///
            workers(`workers') firms(`firms') periods(`periods') ///
            seed(20260830) truth(none) connectivity(keep) ///
            noreport clear
        local run_rc = _rc
        if `run_rc' {
            di as error "`preset'/`design' benchmark failed (rc=`run_rc')"
            exit `run_rc'
        }
        di as txt "completed akm/`preset' network(`design')"
        local N_`key' = r(N)
        local total_`key' = r(runtime_total)
        local simulate_`key' = r(runtime_simulate)
        local output_`key' = r(runtime_output)
        matrix benchmark_network = r(network)
        local components_`key' = ///
            benchmark_network["components", "generated"]
        local edges_`key' = ///
            benchmark_network["edges", "generated"]
        timer off 1
        quietly timer list 1
        local command_`key' = r(t1)
    }
}

tempname result_file
file open `result_file' using `"`result_path'"', write text replace
file write `result_file' "{" _n
file write `result_file' `"  "sha": "`source_sha'","' _n
file write `result_file' `"  "workers": `workers',"' _n
file write `result_file' `"  "firms": `firms',"' _n
file write `result_file' `"  "periods": `periods',"' _n
foreach preset in simple stylized {
    file write `result_file' `"  "`preset'": {"' _n
    foreach design in random ladder {
        local preset_key = cond(`"`preset'"' == "simple", "s", "e")
        local design_key = cond(`"`design'"' == "random", "r", "l")
        local key `"`preset_key'`design_key'"'
        local comma = cond(`"`design'"' == "random", ",", "")
        file write `result_file' `"    "`design'": {"' _n
        file write `result_file' `"      "observations": `N_`key'',"' _n
        file write `result_file' `"      "components": `components_`key'',"' _n
        file write `result_file' `"      "edges": `edges_`key'',"' _n
        file write `result_file' `"      "command_seconds": `command_`key'',"' _n
        file write `result_file' `"      "runtime_total": `total_`key'',"' _n
        file write `result_file' `"      "runtime_simulate": `simulate_`key'',"' _n
        file write `result_file' `"      "runtime_output": `output_`key''"' _n
        file write `result_file' `"    }`comma'"' _n
    }
    local preset_comma = cond(`"`preset'"' == "simple", ",", "")
    file write `result_file' `"  }`preset_comma'"' _n
}
file write `result_file' "}" _n
file close `result_file'

di as result "FESIM NETWORK-LADDER BENCHMARK PASS: `result_path'"
exit 0
