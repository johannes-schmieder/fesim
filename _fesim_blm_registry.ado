*! fesim BLM typed parameter registry 1.2.0-dev 06sep2026
program define _fesim_blm_registry, rclass
    version 16.0
    syntax , ACTION(string) PRESet(string) [ PARAmeter(string) ]
    local scalar_parameters "workers firms periods burnin worker_types firm_types mu sd_worker sd_firm interaction sd_error lambda_move sorting rho mobility_wage origin_dependence"
    local model "worker_types firm_types mu sd_worker sd_firm interaction sd_error lambda_move sorting rho mobility_wage origin_dependence"
    local matrices "worker_weights firm_weights mean_matrix sd_matrix move_rate_matrix rho_matrix mobility_wage_matrix destination_matrix move_shift_matrix"
    if "`action'"=="parameters" {
        return local common_options "workers firms periods frequency start seed initial burnin jobrule truth connectivity network report"
        return local scalar_parameters "`scalar_parameters'"
        return local model_parameters "`model'"
        return local matrix_parameters "`matrices'"
        return local matrix_results "blm_worker_weights blm_firm_weights blm_mean blm_sd blm_move_rate blm_rho blm_mobility_wage blm_destination blm_move_shift blm_firm_counts blm_worker_scores blm_firm_scores blm_monthly_rho blm_eligible_destination"
        return local network_parameters ""
        return local config_schema "blm_`preset'_v1"
        return local dgp "blm"
        return local preset "`preset'"
        exit
    }
    local name = lower(strtrim("`parameter'"))
    local type "real"
    local default "0"
    local lower "."
    local upper "."
    local lower_closed "yes"
    local upper_closed "yes"
    local unit "log wage points"
    local named "no"
    local allowed "yes"
    local scope "model"
    local description "BLM scalar recipe: `name'"
    if `: list name in matrices' {
        local type "matrix"
        local default "derived"
        local unit "resolved table; see matrix_shape"
        local description "Stata matrix name; copied by value before simulation"
        local shape "L by K"
        if "`name'"=="worker_weights" local shape "1 by L"
        if "`name'"=="firm_weights" local shape "1 by K"
        if inlist("`name'","destination_matrix","move_shift_matrix") local shape "(L*K) by K; row=(worker_type-1)*K+origin_class"
        return local matrix_shape "`shape'"
    }
    else if `: list name in scalar_parameters' {
        if inlist("`name'","workers","firms","periods","worker_types","firm_types") {
            local type "integer"
            local unit "count"
            local lower "1"
            local upper "2147483647"
            if "`name'"=="workers" {
                local default "10000"
                local upper "10000000"
            }
            if "`name'"=="firms" {
                local default "500"
                local upper "1000000"
            }
            if "`name'"=="periods" local default "10"
            if "`name'"=="worker_types" local default "6"
            if "`name'"=="firm_types" local default "10"
            if inlist("`name'","worker_types","firm_types") local upper "20"
        }
        if "`name'"=="burnin" {
            local default "20"
            local lower "0"
            local upper "100000"
            local unit "years, aligned to whole months"
        }
        if inlist("`name'","workers","firms","periods","burnin") {
            local scope "common"
            local named "yes"
        }
        if "`name'"=="mu" local default "3"
        if "`name'"=="sd_worker" local default ".4"
        if "`name'"=="sd_firm" local default ".15"
        if "`name'"=="interaction" local default ".1"
        if "`name'"=="sd_error" local default ".2"
        if inlist("`name'","sd_worker","sd_firm","sd_error","lambda_move") local lower "0"
        if "`name'"=="lambda_move" {
            local default ".25"
            local unit "annual baseline move intensity"
        }
        if "`name'"=="sorting" {
            local default ".5"
            local unit "worker-score by firm-score log destination weight"
        }
        if "`name'"=="rho" {
            if "`preset'"=="dynamic" local default ".6"
            local lower "0"
            local upper "1"
            local upper_closed "no"
            local unit "annual persistence; monthly coefficient = rho^(1/12)"
        }
        if "`name'"=="mobility_wage" {
            if "`preset'"=="dynamic" local default "-2"
            local unit "log move intensity per current log-wage deviation"
        }
        if "`name'"=="origin_dependence" {
            if "`preset'"=="dynamic" local default ".05"
            local unit "move shift per origin minus destination score"
        }
    }
    else {
        * Common nonnumeric discovery fields retain the common registry contract.
        quietly fesim_registry, action(parameter) dgp(akm) preset(stylized) parameter(`name')
        return add
        return local applicability "blm/`preset'"
        if "`name'"=="initial" return local default "random"
        exit
    }
    return local parameter "`name'"
    return local type "`type'"
    return local default "`default'"
    return local unit "`unit'"
    return local lower "`lower'"
    return local upper "`upper'"
    return local lower_closed "`lower_closed'"
    return local upper_closed "`upper_closed'"
    return local named_option "`named'"
    return local parameters_allowed "`allowed'"
    return local scope "`scope'"
    return local default_source "preset"
    return local description "`description'"
    return local applicability "blm/`preset'"
    return scalar lower_value = real("`lower'")
    return scalar upper_value = real("`upper'")
    if "`type'"!="matrix" return scalar default_value = real("`default'")
end
