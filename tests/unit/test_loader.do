version 16.0
clear all
set more off
set varabbrev off

args repository_root
if `"`repository_root'"' == "" {
    di as error "test_loader.do requires the repository root"
    exit 198
}

local build_path `"`repository_root'/build"'
local stale_path `"`repository_root'/tests/fixtures/stale_mata"'

capture quietly adopath - `"`build_path'"'
quietly adopath ++ `"`stale_path'"'
mata: mata clear
mata: mata mlib index

capture noisily _fesim_load
assert _rc == 0
mata: assert(fesim_mata_api_version() == 22)
mata: assert(fesim_network_schema_version() == 3)

capture quietly adopath - `"`stale_path'"'
quietly adopath ++ `"`build_path'"'
mata: mata clear
mata: mata mlib index
mata: assert(fesim_mata_api_version() == 22)

di as result "FESIM CHECKOUT SOURCE LOADER TESTS PASS"
