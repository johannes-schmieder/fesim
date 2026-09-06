version 19.0
clear all
set more off
set varabbrev off
args repository_root source_sha family preset network truth result_path
quietly adopath ++ "`repository_root'"
local extra ""
if "`network'" == "bridges" local extra "burnin(4)"
timer clear 1
timer on 1
quietly fesim, dgp(`family') preset(`preset') network(`network') ///
    workers(10000) firms(500) periods(10) truth(`truth') ///
    seed(20260906) `extra' noreport clear
local seconds = r(runtime_total)
local rows = r(N)
timer off 1
quietly timer list 1
local elapsed = r(t1)
quietly datasignature
local signature "`r(datasignature)'"
tempname output
file open `output' using "`result_path'", write text replace
file write `output' `"{"sha":"`source_sha'","status":"passed","observations":`rows',"runtime_total":`seconds',"command_seconds":`elapsed',"signature":"`signature'"}"' _n
file close `output'
display "FESIM RELEASE BENCHMARK PASS"
exit, STATA clear
