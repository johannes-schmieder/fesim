*! fesim Mata source loader 1.2.0-rc.1 06sep2026
program define fesim__load
    version 16.0

    capture mata: assert(fesim_mata_api_version() == 37)
    if !_rc exit

    quietly findfile fesim__load.ado
    local loader_path `"`r(fn)'"'
    local loader_name "fesim__load.ado"
    local package_root = substr(`"`loader_path'"', 1, ///
        strlen(`"`loader_path'"') - strlen(`"`loader_name'"') - 1)
    foreach source in types rng cpv time hazards bm bm_events destinations bm_initial network_design flows moments network runtime output bm_aggregate bm_output lifecycle ///
        akm_simple empirical paygap akm_handler emp_handler paygap_handler bm_handler cpv_simulate blm blm_simulate dispatch {
        local source_path `"`package_root'/src/fesim_`source'.mata"'
        capture confirm file `"`source_path'"'
        if _rc {
            local source_path `"`package_root'/fesim_`source'.mata"'
            capture confirm file `"`source_path'"'
        }
        if _rc {
            capture quietly findfile fesim_`source'.mata
            if _rc {
                di as error "installed fesim Mata source is missing: fesim_`source'.mata"
                exit 601
            }
            local source_path `"`r(fn)'"'
        }
        quietly do `"`source_path'"'
    }
    capture mata: assert(fesim_mata_api_version() == 37)
    if _rc {
        di as error "fesim Mata source failed to load"
        exit 3000
    }
end
