version 16.0
clear all
set more off

args requested_root requested_output
local repository_root `"`requested_root'"'
if `"`repository_root'"' == "" local repository_root `"`c(pwd)'"'

capture confirm file `"`repository_root'/src/fesim_types.mata"'
if _rc {
    di as error "repository root does not contain src/fesim_types.mata: `repository_root'"
    exit 601
}

local output_dir `"`requested_output'"'
if `"`output_dir'"' == "" local output_dir `"`repository_root'/build"'
capture mkdir `"`output_dir'"'

capture erase `"`output_dir'/lfesim.mlib"'
mata: mata clear
quietly do `"`repository_root'/src/fesim_types.mata"'
quietly do `"`repository_root'/src/fesim_rng.mata"'
quietly do `"`repository_root'/src/fesim_time.mata"'
quietly do `"`repository_root'/src/fesim_hazards.mata"'
quietly do `"`repository_root'/src/fesim_bm.mata"'
quietly do `"`repository_root'/src/fesim_destinations.mata"'
quietly do `"`repository_root'/src/fesim_network_design.mata"'
quietly do `"`repository_root'/src/fesim_flows.mata"'
quietly do `"`repository_root'/src/fesim_moments.mata"'
quietly do `"`repository_root'/src/fesim_network.mata"'
quietly do `"`repository_root'/src/fesim_runtime.mata"'
quietly do `"`repository_root'/src/fesim_output.mata"'
quietly do `"`repository_root'/src/fesim_lifecycle.mata"'
quietly do `"`repository_root'/src/fesim_akm_simple.mata"'
quietly do `"`repository_root'/src/fesim_empirical.mata"'
quietly do `"`repository_root'/src/fesim_paygap.mata"'
quietly do `"`repository_root'/src/fesim_akm_handler.mata"'
quietly do `"`repository_root'/src/fesim_emp_handler.mata"'
quietly do `"`repository_root'/src/fesim_paygap_handler.mata"'
quietly do `"`repository_root'/src/fesim_dispatch.mata"'

mata: mata mlib create lfesim, dir(`"`output_dir'"') replace
mata: mata mlib add lfesim fesim_*(), dir(`"`output_dir'"') complete

quietly adopath ++ `"`output_dir'"'
mata: mata clear
mata: mata mlib index
mata: assert(fesim_mata_api_version() == 27)
mata: assert(fesim_config_schema_version() == 2)
mata: assert(fesim_rng_schema_version() == 2)
mata: assert(cols(fesim_rng_component_names()) == 9)
mata: assert(fesim_netdesign_schema_version() == 3)
mata: assert(fesim_time_schema_version() == 1)
mata: assert(fesim_time_delta_years("quarter") == .25)
mata: assert(fesim_hazard_schema_version() == 1)
mata: assert(fesim_bm_schema_version() == 1)
mata: assert(fesim_destination_schema_version() == 3)
mata: assert(fesim_flow_schema_version() == 1)
mata: assert(fesim_moment_schema_version() == 1)
mata: assert(fesim_network_schema_version() == 4)
mata: assert(fesim_runtime_schema_version() == 1)
mata: assert(fesim_output_schema_version() == 7)
mata: assert(fesim_output_checked_rows(10000, 10) == 100000)
mata: assert(fesim_population_schema_version() == 4)
mata: assert(fesim_akm_simple_schema_version() == 4)
mata: assert(fesim_emp_schema_version() == 2)
mata: assert(fesim_paygap_schema_version() == 1)
mata: assert(fesim_akm_handler_schema_version() == 5)
mata: assert(fesim_emp_handler_schema_version() == 5)
mata: assert(fesim_paygap_handler_version() == 1)
mata: assert(fesim_state_schema_version() == 5)
mata: assert(fesim_results_schema_version() == 2)
mata: assert(fesim_handler_schema_version() == 1)
mata: assert(fesim_dispatch_status() == "akm_and_paygap_public")
mata: assert(fesim_dispatch_toy_smoke() == 1)

capture confirm file `"`output_dir'/lfesim.mlib"'
if _rc {
    di as error "Mata library build did not create lfesim.mlib"
    exit 601
}

di as result "FESIM MATA BUILD PASS: `output_dir'/lfesim.mlib"
