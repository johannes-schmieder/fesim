version 16.0
clear all
set more off
set varabbrev off

args repository_root requested_workers requested_periods requested_block_workers
if `"`repository_root'"' == "" {
    di as error "benchmark_output_blocks.do requires the repository root"
    exit 198
}
local workers = real(`"`requested_workers'"')
local periods = real(`"`requested_periods'"')
local block_workers = real(`"`requested_block_workers'"')
if missing(`workers') | missing(`periods') {
    di as error "benchmark requires numeric workers and periods"
    exit 198
}

quietly adopath ++ `"`repository_root'/build"'
mata: mata clear
mata: mata mlib index
if missing(`block_workers') {
    mata: st_numscalar("benchmark_block_workers", ///
        fesim_output_default_block(`workers', `periods'))
    local block_workers = benchmark_block_workers
}

timer clear 1
timer on 1
mata: st_numscalar("benchmark_rows", ///
    fesim_output_toy_panel(`workers', `periods', `block_workers'))
timer off 1
quietly timer list 1
local seconds = r(t1)
isid workerid time
assert _N == benchmark_rows
mata: st_numscalar("benchmark_estimated_peak", ///
    fesim_output_peak_bytes(`workers', `periods', `block_workers'))

di as result "FESIM_OUTPUT_BENCH workers=`workers' periods=`periods' rows=" ///
    %21.0f benchmark_rows " block_workers=`block_workers' seconds=" ///
    %12.6f `seconds' " estimated_peak_bytes=" %21.0f benchmark_estimated_peak ///
    " stata_memory_bytes=" %21.0f c(memory)
exit 0
