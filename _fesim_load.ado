*! fesim Mata source loader 0.2.0-dev 29aug2026
program define _fesim_load
    version 16.0

    capture mata: assert(fesim_mata_api_version() == 15)
    if !_rc exit

    quietly findfile _fesim_load.ado
    local loader_path `"`r(fn)'"'
    local loader_name "_fesim_load.ado"
    local package_root = substr(`"`loader_path'"', 1, ///
        strlen(`"`loader_path'"') - strlen(`"`loader_name'"') - 1)
    foreach source in types rng time hazards destinations flows moments network runtime output lifecycle ///
        akm_simple akm_handler dispatch {
        capture quietly findfile fesim_`source'.mata
        if !_rc local source_path `"`r(fn)'"'
        else {
            local source_path `"`package_root'/src/fesim_`source'.mata"'
            capture confirm file `"`source_path'"'
            if _rc {
                di as error "installed fesim Mata source is missing: fesim_`source'.mata"
                exit 601
            }
        }
        quietly do `"`source_path'"'
    }
    capture mata: assert(fesim_mata_api_version() == 15)
    if _rc {
        di as error "fesim Mata source failed to load"
        exit 3000
    }
end
