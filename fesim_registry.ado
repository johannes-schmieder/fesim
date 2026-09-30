*! fesim configuration registry 1.2.0-rc.1 06sep2026
program define fesim_registry, rclass
    version 16.0
    syntax , ACTION(string) [ DGP(string) PRESet(string) PARAmeter(string) ]

    local action = lower(strtrim(`"`action'"'))

    if `"`action'"' == "list" {
        if strtrim(`"`dgp'`preset'`parameter'"') != "" {
            di as error "dgp(), preset(), and parameter() are not allowed with registry action list"
            exit 198
        }
        return local dgps "akm akmpaygap bm cpv blm"
        return local aliases "akmsimple akmempirical bmsimple"
        return local qualified "akm/simple akm/stylized akm/germany_chk_2002_2009 akmpaygap/simple akmpaygap/cck2016 bm/simple cpv/simple cpv/heterogeneous blm/static blm/dynamic"
        return local status "partial"
        return scalar n_dgps = 5
        exit
    }

    if !inlist(`"`action'"', "resolve", "parameters", "parameter") {
        di as error "unknown fesim registry action: `action'"
        exit 198
    }

    quietly fesim_registry__resolve, dgp(`dgp') preset(`preset')
    if `"`action'"' == "resolve" {
        return add
        exit
    }

    local canonical `"`r(dgp)'"'
    local resolved_preset `"`r(preset)'"'

    if "`canonical'"=="blm" {
        fesim__blm_registry, action(`action') preset(`resolved_preset') parameter(`parameter')
        return add
        exit
    }
    if !inlist(`"`canonical'/`resolved_preset'"', ///
        "akm/simple", "akm/stylized", "akm/germany_chk_2002_2009", ///
        "akmpaygap/simple", "akmpaygap/cck2016", "bm/simple", ///
        "cpv/simple", "cpv/heterogeneous") {
        if `"`action'"' == "parameters" {
            return local common_options ""
            return local scalar_parameters ""
            return local model_parameters ""
            return local config_schema ""
            return local dgp `"`canonical'"'
            return local preset `"`resolved_preset'"'
            exit
        }
        di as error "parameter metadata is not yet registered for dgp(`canonical') preset(`resolved_preset')"
        exit 498
    }

    if `"`action'"' == "parameters" {
        return local common_options "workers firms periods frequency start seed initial burnin jobrule truth connectivity network report"
        if `"`canonical'"' == "cpv" {
            return local scalar_parameters "workers firms periods burnin b p_min p_max lambda_u lambda_e delta r beta sd_worker random_firms"
            return local model_parameters "b p_min p_max lambda_u lambda_e delta r beta sd_worker random_firms"
            return local network_parameters ""
            return local config_schema "cpv_`resolved_preset'_v1"
        }
        else if `"`canonical'"' == "bm" {
            return local scalar_parameters "workers firms periods burnin b p lambda_u lambda_e delta r random_firms"
            return local model_parameters "b p lambda_u lambda_e delta r random_firms"
            return local network_parameters ""
            return local config_schema "bm_simple_v1"
        }
        else if `"`canonical'"' == "akmpaygap" {
            return local scalar_parameters "workers firms periods burnin female_share mu_m mu_f sd_worker_m sd_worker_f premium_intercept_m premium_intercept_f premium_loading_m premium_loading_f premium_deviation_sd_m premium_deviation_sd_f sd_error_m sd_error_f firm_size_sd p_eu_m p_ee_m p_ue_m p_eu_f p_ee_f p_ue_f group_sort_m group_sort_f worker_sort_m worker_sort_f wage_trend_m wage_trend_f block_count block_log_bonus bridge_count ladder_down_share ladder_lateral_share ladder_up_share ladder_band"
            return local model_parameters "female_share mu_m mu_f sd_worker_m sd_worker_f premium_intercept_m premium_intercept_f premium_loading_m premium_loading_f premium_deviation_sd_m premium_deviation_sd_f sd_error_m sd_error_f firm_size_sd p_eu_m p_ee_m p_ue_m p_eu_f p_ee_f p_ue_f group_sort_m group_sort_f worker_sort_m worker_sort_f wage_trend_m wage_trend_f"
            return local network_parameters "block_count block_log_bonus bridge_count ladder_down_share ladder_lateral_share ladder_up_share ladder_band"
            return local config_schema "akmpaygap_`resolved_preset'_v1"
        }
        else if `"`resolved_preset'"' == "simple" {
            return local scalar_parameters "workers firms periods burnin mu sd_worker sd_firm sd_error firm_size_sd p_eu p_ee p_ue wage_trend block_count block_log_bonus bridge_count ladder_down_share ladder_lateral_share ladder_up_share ladder_band"
            return local model_parameters "mu sd_worker sd_firm sd_error firm_size_sd p_eu p_ee p_ue wage_trend"
            return local network_parameters "block_count block_log_bonus bridge_count ladder_down_share ladder_lateral_share ladder_up_share ladder_band"
            return local config_schema "akm_simple_v3"
        }
        else {
            return local scalar_parameters "workers firms periods burnin mu sd_worker sd_firm sd_error firm_size_sd wage_trend rho_z_alpha rho_q_psi kappa_eu eu_worker eu_firm eu_duration kappa_ee ee_worker ee_firm ee_duration kappa_ue ue_worker ue_duration theta_sort theta_quality theta_up theta_down block_count block_log_bonus bridge_count ladder_down_share ladder_lateral_share ladder_up_share ladder_band"
            return local model_parameters "mu sd_worker sd_firm sd_error firm_size_sd wage_trend rho_z_alpha rho_q_psi kappa_eu eu_worker eu_firm eu_duration kappa_ee ee_worker ee_firm ee_duration kappa_ue ue_worker ue_duration theta_sort theta_quality theta_up theta_down"
            return local network_parameters "block_count block_log_bonus bridge_count ladder_down_share ladder_lateral_share ladder_up_share ladder_band"
            if `"`resolved_preset'"' == "stylized" {
                return local config_schema "akm_stylized_v3"
            }
            else return local config_schema "akm_germany_chk_2002_2009_v1"
        }
        return local dgp `"`canonical'"'
        return local preset `"`resolved_preset'"'
        exit
    }

    local name = lower(strtrim(`"`parameter'"'))
    if `"`name'"' == "" {
        di as error "parameter() is required with registry action parameter"
        exit 198
    }

    local common "workers firms periods frequency start seed initial burnin jobrule truth connectivity network report"
    if `"`canonical'"' == "cpv" {
        local model "b p_min p_max lambda_u lambda_e delta r beta sd_worker random_firms"
    }
    else if `"`canonical'"' == "bm" {
        local model "b p lambda_u lambda_e delta r random_firms"
    }
    else if `"`canonical'"' == "akmpaygap" {
        local model "female_share mu_m mu_f sd_worker_m sd_worker_f premium_intercept_m premium_intercept_f premium_loading_m premium_loading_f premium_deviation_sd_m premium_deviation_sd_f sd_error_m sd_error_f firm_size_sd p_eu_m p_ee_m p_ue_m p_eu_f p_ee_f p_ue_f group_sort_m group_sort_f worker_sort_m worker_sort_f wage_trend_m wage_trend_f"
    }
    else if `"`resolved_preset'"' == "simple" {
        local model "mu sd_worker sd_firm sd_error firm_size_sd p_eu p_ee p_ue wage_trend"
    }
    else {
        local model "mu sd_worker sd_firm sd_error firm_size_sd wage_trend rho_z_alpha rho_q_psi kappa_eu eu_worker eu_firm eu_duration kappa_ee ee_worker ee_firm ee_duration kappa_ue ue_worker ue_duration theta_sort theta_quality theta_up theta_down"
    }
    local network_model "block_count block_log_bonus bridge_count ladder_down_share ladder_lateral_share ladder_up_share ladder_band"
    if inlist(`"`canonical'"', "bm", "cpv") local network_model ""
    local all `"`common' `model' `network_model'"'
    if !`: list name in all' {
        di as error "unknown fesim parameter: `name'"
        exit 198
    }

    local type "real"
    local unit "level"
    local default ""
    local lower "."
    local upper "."
    local lower_closed "no"
    local upper_closed "no"
    local scope "model"
    local default_source "preset"
    local named_option "no"
    local parameters_allowed "yes"
    local description ""
    local applicability `"`canonical'/`resolved_preset'"'

    if inlist(`"`name'"', "workers", "firms", "periods", "burnin") {
        local type "integer"
        local unit "count"
        local lower "0"
        local upper "2147483647"
        local lower_closed "yes"
        local upper_closed "yes"
        local scope "common"
        local named_option "yes"
        if `"`name'"' != "burnin" local lower "1"
        if `"`name'"' == "workers" {
            local default "10000"
            local description "Number of workers"
        }
        else if `"`name'"' == "firms" {
            if inlist(`"`resolved_preset'"', ///
                "germany_chk_2002_2009", "cck2016") ///
                local default "1000"
            else local default "500"
            local description "Number of firms"
        }
        else if `"`name'"' == "periods" {
            if inlist(`"`resolved_preset'"', ///
                "germany_chk_2002_2009", "cck2016") ///
                local default "8"
            else local default "10"
            local description "Number of retained periods"
        }
        else {
            if `"`canonical'"' == "akm" & ///
                `"`resolved_preset'"' == "simple" {
                local default "0"
                local default_source "package"
                local unit "internal periods"
            }
            else {
                local default "5"
                local unit "years"
            }
            local description "Pre-sample duration discarded after initialization"
        }
    }
    else if inlist(`"`name'"', "frequency", "start", "initial", "jobrule", "truth", "connectivity", "network", "report") {
        local type "string"
        local unit "category"
        local scope "common"
        local default_source "package"
        local named_option "yes"
        local parameters_allowed "no"
        if `"`name'"' == "frequency" {
            local default "year"
            local description "Panel time frequency"
        }
        else if `"`name'"' == "start" {
            if inlist(`"`resolved_preset'"', ///
                "germany_chk_2002_2009", "cck2016") {
                local default "2002"
                local default_source "preset"
            }
            else local default "frequency-specific"
            local description "First retained period"
        }
        else if `"`name'"' == "initial" {
            if `"`canonical'"' == "akm" & ///
                `"`resolved_preset'"' == "simple" local default "stationary"
            else {
                local default "random"
                local default_source "preset"
            }
            local description "Initial worker-state rule"
        }
        else if `"`name'"' == "jobrule" {
            local default "end"
            local description "Within-period employer assignment rule"
        }
        else if `"`name'"' == "truth" {
            local default "basic"
            local description "Truth-data output level"
        }
        else if `"`name'"' == "connectivity" {
            local default "keep"
            local description "Connected-set handling rule"
        }
        else if `"`name'"' == "network" {
            local default "random"
            local description "Mobility-network stress design"
        }
        else {
            local default "report"
            local description "Configuration-reporting mode"
        }
    }
    else if `"`name'"' == "seed" {
        local type "integer-or-current"
        local unit "RNG seed"
        local default "current"
        local lower "0"
        local upper "2147483647"
        local lower_closed "yes"
        local upper_closed "yes"
        local scope "common"
        local default_source "package"
        local named_option "yes"
        local parameters_allowed "no"
        local description "Requested simulation seed; current leaves RNG selection to execution"
    }
    else if `"`canonical'"' == "cpv" {
        local description "Canonical CPV primitive: `name'"
        local lower "0"
        local upper "1000"
        local upper_closed "yes"
        local unit "annual continuous-time rate"
        if inlist(`"`name'"', "b", "p_min", "p_max") {
            local upper "."
            local unit "level per efficiency unit"
            if `"`name'"' == "b" local default "1"
            if `"`name'"' == "p_min" local default "1.5"
            if `"`name'"' == "p_max" local default "2"
        }
        else if `"`name'"' == "lambda_u" local default ".5"
        else if `"`name'"' == "lambda_e" {
            local default ".3"
            local lower_closed "yes"
        }
        else if `"`name'"' == "delta" local default ".2"
        else if `"`name'"' == "r" local default ".05"
        else if `"`name'"' == "beta" {
            local default ".5"
            local lower_closed "yes"
            local upper "1"
            local unit "worker bargaining share"
        }
        else if `"`name'"' == "sd_worker" {
            local default "0"
            if `"`resolved_preset'"' == "heterogeneous" local default ".4"
            local lower_closed "yes"
            local upper "."
            local unit "log ability standard deviation"
        }
        else if `"`name'"' == "random_firms" {
            local default "0"
            local type "integer"
            local unit "0 midpoint quantiles; 1 random quantiles"
            local lower_closed "yes"
            local upper "1"
        }
    }
    else if `"`canonical'"' == "bm" {
        local description "Canonical BM primitive: `name'"
        local lower "0"
        local upper "1000"
        local upper_closed "yes"
        local unit "annual continuous-time rate"
        if `"`name'"' == "b" {
            local default ".4"
            local lower "."
            local upper "."
            local unit "wage level"
        }
        else if `"`name'"' == "p" {
            local default "1"
            local upper "."
            local unit "productivity level"
        }
        else if `"`name'"' == "lambda_u" local default "1"
        else if `"`name'"' == "lambda_e" local default ".5"
        else if `"`name'"' == "delta" local default ".2"
        else if `"`name'"' == "r" local default ".05"
        else if `"`name'"' == "random_firms" {
            local default "0"
            local type "integer"
            local unit "0 midpoint quantiles; 1 random quantiles"
            local lower_closed "yes"
            local upper "1"
        }
    }
    else if `"`name'"' == "block_count" {
        local type "integer"
        local unit "communities"
        local default "4"
        local lower "2"
        local upper "2147483647"
        local lower_closed "yes"
        local upper_closed "yes"
        local scope "network"
        local description "Balanced worker and firm community count"
    }
    else if `"`name'"' == "block_log_bonus" {
        local unit "log destination weight"
        local default "2.1972245773362196"
        local lower "0"
        local upper "30"
        local lower_closed "yes"
        local upper_closed "yes"
        local scope "network"
        local description "Same-block destination log-weight bonus"
    }
    else if `"`name'"' == "bridge_count" {
        local type "integer"
        local unit "imposed EE destinations"
        local default "3"
        local lower "1"
        local upper "2147483647"
        local lower_closed "yes"
        local upper_closed "yes"
        local scope "network"
        local description "Exact bridge count; defaults dynamically to block_count minus one"
    }
    else if inlist(`"`name'"', "ladder_down_share", ///
        "ladder_lateral_share", "ladder_up_share") {
        local unit "EE destination direction share"
        if `"`name'"' == "ladder_down_share" {
            local default ".1"
            local description "Downward firm-wage-rank destination share"
        }
        else if `"`name'"' == "ladder_lateral_share" {
            local default ".2"
            local description "Lateral firm-wage-rank destination share"
        }
        else {
            local default ".7"
            local description "Upward firm-wage-rank destination share"
        }
        local lower "0"
        local upper "1"
        local lower_closed "yes"
        local upper_closed "yes"
        local scope "network"
    }
    else if `"`name'"' == "ladder_band" {
        local unit "percentile-rank distance"
        local default ".1"
        local lower "0"
        local upper "1"
        local lower_closed "yes"
        local upper_closed "yes"
        local scope "network"
        local description "Maximum absolute firm-wage-rank distance classified as lateral"
    }
    else {
        local named_option "no"
        if `"`canonical'"' == "akmpaygap" {
            if `"`resolved_preset'"' == "simple" {
                if `"`name'"' == "female_share" local default ".5"
                else if `"`name'"' == "mu_m" local default "3"
                else if `"`name'"' == "mu_f" local default "2.9"
                else if inlist(`"`name'"', "sd_worker_m", ///
                    "sd_worker_f") local default ".4"
                else if `"`name'"' == "premium_intercept_m" ///
                    local default ".05"
                else if `"`name'"' == "premium_intercept_f" ///
                    local default ".03"
                else if `"`name'"' == "premium_loading_m" ///
                    local default ".15"
                else if `"`name'"' == "premium_loading_f" ///
                    local default ".12"
                else if `"`name'"' == "premium_deviation_sd_m" ///
                    local default "0"
                else if `"`name'"' == "premium_deviation_sd_f" ///
                    local default ".09"
                else if inlist(`"`name'"', "sd_error_m", ///
                    "sd_error_f") local default ".2"
                else if `"`name'"' == "firm_size_sd" local default "1"
                else if inlist(`"`name'"', "p_eu_m", ///
                    "p_eu_f") local default ".08"
                else if inlist(`"`name'"', "p_ee_m", ///
                    "p_ee_f") local default ".12"
                else if inlist(`"`name'"', "p_ue_m", ///
                    "p_ue_f") local default ".6"
                else if `"`name'"' == "group_sort_m" local default ".3"
                else if `"`name'"' == "group_sort_f" local default "0"
                else if inlist(`"`name'"', "worker_sort_m", ///
                    "worker_sort_f") local default ".3"
                else if inlist(`"`name'"', "wage_trend_m", ///
                    "wage_trend_f") local default "0"
            }
            else {
                if `"`name'"' == "female_share" local default ".46"
                else if `"`name'"' == "mu_m" local default "3"
                else if `"`name'"' == "mu_f" local default "2.815"
                else if `"`name'"' == "sd_worker_m" local default ".420"
                else if `"`name'"' == "sd_worker_f" local default ".400"
                else if `"`name'"' == "premium_intercept_m" ///
                    local default ".113"
                else if `"`name'"' == "premium_intercept_f" ///
                    local default ".099"
                else if `"`name'"' == "premium_loading_m" ///
                    local default ".247"
                else if `"`name'"' == "premium_loading_f" ///
                    local default ".12567"
                else if `"`name'"' == "premium_deviation_sd_m" ///
                    local default "0"
                else if `"`name'"' == "premium_deviation_sd_f" ///
                    local default ".171976891180182"
                else if `"`name'"' == "sd_error_m" local default ".143"
                else if `"`name'"' == "sd_error_f" local default ".125"
                else if `"`name'"' == "firm_size_sd" local default "1"
                else if inlist(`"`name'"', "p_eu_m", ///
                    "p_eu_f") local default ".08"
                else if inlist(`"`name'"', "p_ee_m", ///
                    "p_ee_f") local default ".12"
                else if inlist(`"`name'"', "p_ue_m", ///
                    "p_ue_f") local default ".6"
                else if `"`name'"' == "group_sort_m" local default ".142"
                else if `"`name'"' == "group_sort_f" local default "0"
                else if `"`name'"' == "worker_sort_m" local default ".18"
                else if `"`name'"' == "worker_sort_f" local default ".273"
                else if inlist(`"`name'"', "wage_trend_m", ///
                    "wage_trend_f") local default ".05"
            }
            if `"`name'"' == "female_share" {
                local unit "population share"
                local lower "0"
                local upper "1"
                local description "Population share coded as women"
            }
            else if inlist(`"`name'"', "sd_worker_m", ///
                "sd_worker_f", "premium_deviation_sd_m", ///
                "premium_deviation_sd_f", "sd_error_m", ///
                "sd_error_f", "firm_size_sd") {
                local unit "standard deviation"
                local lower "0"
                local lower_closed "yes"
                local description "Group-specific or firm primitive standard deviation"
            }
            else if inlist(`"`name'"', "p_eu_m", "p_ee_m", ///
                "p_ue_m", "p_eu_f", "p_ee_f", "p_ue_f") {
                local unit "annual probability"
                local lower "0"
                local upper "1"
                local lower_closed "yes"
                if inlist(`"`name'"', "p_ue_m", "p_ue_f") ///
                    local upper_closed "yes"
                local description "Group-specific annual employment transition probability"
            }
            else if inlist(`"`name'"', "mu_m", "mu_f") ///
                local description "Group-specific log-wage intercept"
            else if inlist(`"`name'"', "premium_intercept_m", ///
                "premium_intercept_f") ///
                local description "Group-specific firm-premium intercept"
            else if inlist(`"`name'"', "premium_loading_m", ///
                "premium_loading_f") ///
                local description "Group-specific loading on common firm surplus"
            else if inlist(`"`name'"', "group_sort_m", ///
                "group_sort_f") ///
                local description "Group-specific destination surplus tilt"
            else if inlist(`"`name'"', "worker_sort_m", ///
                "worker_sort_f") ///
                local description "Worker-type by surplus destination tilt"
            else if inlist(`"`name'"', "wage_trend_m", ///
                "wage_trend_f") ///
                local description "Group-specific annual log-wage trend"
        }
        else if `"`name'"' == "mu" {
            local default "3"
            local description "Mean log wage"
        }
        else if `"`name'"' == "sd_worker" {
            if `"`resolved_preset'"' == "germany_chk_2002_2009" ///
                local default ".357"
            else local default ".4"
            local lower "0"
            local lower_closed "yes"
            local unit "standard deviation"
            local description "Worker-effect standard deviation"
        }
        else if `"`name'"' == "sd_firm" {
            if `"`resolved_preset'"' == "germany_chk_2002_2009" ///
                local default ".230"
            else local default ".15"
            local lower "0"
            local lower_closed "yes"
            local unit "standard deviation"
            local description "Firm-effect standard deviation"
        }
        else if `"`name'"' == "sd_error" {
            if `"`resolved_preset'"' == "germany_chk_2002_2009" ///
                local default ".135"
            else local default ".2"
            local lower "0"
            local lower_closed "yes"
            local unit "standard deviation"
            local description "Idiosyncratic-error standard deviation"
        }
        else if `"`name'"' == "firm_size_sd" {
            local default "1"
            local lower "0"
            local lower_closed "yes"
            local unit "standard deviation"
            local description "Firm-size log-weight standard deviation"
        }
        else if inlist(`"`name'"', "p_eu", "p_ee") {
            if `"`name'"' == "p_eu" local default ".08"
            else local default ".12"
            local lower "0"
            local upper "1"
            local lower_closed "yes"
            local upper_closed "no"
            local unit "probability"
            local description "Annual employment transition probability"
        }
        else if `"`name'"' == "p_ue" {
            local default ".6"
            local lower "0"
            local upper "1"
            local lower_closed "yes"
            local upper_closed "yes"
            local unit "probability"
            local description "Annual job-finding probability"
        }
        else if `"`name'"' == "wage_trend" {
            local default "0"
            local description "Linear log-wage time trend"
        }
        else if inlist(`"`name'"', "rho_z_alpha", "rho_q_psi") {
            if `"`name'"' == "rho_z_alpha" {
                local default ".3"
                local description "Latent worker mobility-index and wage-effect correlation"
            }
            else {
                local default ".5"
                local description "Latent firm quality-index and wage-effect correlation"
            }
            local lower "-1"
            local upper "1"
            local lower_closed "yes"
            local upper_closed "yes"
            local unit "correlation"
        }
        else if inlist(`"`name'"', "kappa_eu", "kappa_ee", "kappa_ue") {
            if `"`name'"' == "kappa_eu" {
                local default "-2.416230718633671"
                local description "EU annual log-hazard intercept"
            }
            else if `"`name'"' == "kappa_ee" {
                local default "-2.0107656105255063"
                local description "EE annual log-hazard intercept"
            }
            else {
                local default "-.08742157179075517"
                local description "UE annual log-hazard intercept"
            }
            local unit "log annual hazard"
        }
        else if `"`name'"' == "eu_worker" {
            local default ".1"
            local description "Worker mobility-type coefficient in the EU log hazard"
        }
        else if `"`name'"' == "eu_firm" {
            local default "-.1"
            local description "Firm-quality coefficient in the EU log hazard"
        }
        else if `"`name'"' == "eu_duration" {
            local default "-.2"
            local description "Log-one-plus tenure coefficient in the EU log hazard"
        }
        else if `"`name'"' == "ee_worker" {
            local default ".1"
            local description "Worker mobility-type coefficient in the EE log hazard"
        }
        else if `"`name'"' == "ee_firm" {
            local default "-.1"
            local description "Firm-quality coefficient in the EE log hazard"
        }
        else if `"`name'"' == "ee_duration" {
            local default "-.15"
            local description "Log-one-plus tenure coefficient in the EE log hazard"
        }
        else if `"`name'"' == "ue_worker" {
            local default ".15"
            local description "Worker mobility-type coefficient in the UE log hazard"
        }
        else if `"`name'"' == "ue_duration" {
            local default "-.25"
            local description "Log-one-plus unemployment-duration coefficient in the UE log hazard"
        }
        else if `"`name'"' == "theta_sort" {
            if `"`resolved_preset'"' == "germany_chk_2002_2009" ///
                local default "2.2"
            else local default ".25"
            local description "Worker-type by firm-quality destination sorting coefficient"
        }
        else if `"`name'"' == "theta_quality" {
            local default ".1"
            local description "Destination firm-quality preference coefficient"
        }
        else if `"`name'"' == "theta_up" {
            local default ".2"
            local description "Upward firm-quality distance coefficient for EE moves"
        }
        else if `"`name'"' == "theta_down" {
            local default "-.1"
            local description "Downward firm-quality distance coefficient for EE moves"
        }
    }

    if inlist(`"`canonical'"', "bm", "cpv") {
        if `"`name'"' == "workers" local upper "10000000"
        if `"`name'"' == "firms" local upper "1000000"
        if `"`name'"' == "burnin" {
            local type "real"
            local unit "years"
            local default "0"
            local upper "100000"
        }
        if `"`name'"' == "initial" local default "stationary"
    }

    return local parameter `"`name'"'
    return local type `"`type'"'
    return local unit `"`unit'"'
    return local default `"`default'"'
    return local lower `"`lower'"'
    return local upper `"`upper'"'
    return local lower_closed `"`lower_closed'"'
    return local upper_closed `"`upper_closed'"'
    return local scope `"`scope'"'
    return local default_source `"`default_source'"'
    return local named_option `"`named_option'"'
    return local parameters_allowed `"`parameters_allowed'"'
    return local description `"`description'"'
    return local applicability `"`applicability'"'
    if `"`type'"' != "string" & `"`default'"' != "current" {
        return scalar default_value = real(`"`default'"')
    }
    return scalar lower_value = real(`"`lower'"')
    return scalar upper_value = real(`"`upper'"')
end

program define fesim_registry__resolve, rclass
    version 16.0
    syntax , DGP(string) [ PRESet(string) ]

    local requested = lower(strtrim(`"`dgp'"'))
    local requested_preset = lower(strtrim(`"`preset'"'))
    if `"`requested'"' == "" {
        di as error "a DGP name is required"
        exit 198
    }

    local canonical ""
    local alias_preset ""
    if `"`requested'"' == "akm" local canonical "akm"
    else if `"`requested'"' == "akmsimple" {
        local canonical "akm"
        local alias_preset "simple"
    }
    else if `"`requested'"' == "akmempirical" {
        local canonical "akm"
        local alias_preset "stylized"
    }
    else if `"`requested'"' == "akmpaygap" local canonical "akmpaygap"
    else if `"`requested'"' == "bm" local canonical "bm"
    else if `"`requested'"' == "cpv" local canonical "cpv"
    else if `"`requested'"' == "blm" local canonical "blm"
    else if `"`requested'"' == "bmsimple" {
        local canonical "bm"
        local alias_preset "simple"
    }
    else {
        di as error "unknown fesim DGP: `requested'"
        di as error "run {cmd:fesim list} to see registered names"
        exit 198
    }

    if `"`alias_preset'"' != "" & `"`requested_preset'"' != "" & ///
        `"`requested_preset'"' != `"`alias_preset'"' {
        di as error "DGP alias `requested' fixes preset(`alias_preset')"
        exit 198
    }

    local resolved_preset `"`requested_preset'"'
    if `"`resolved_preset'"' == "" local resolved_preset `"`alias_preset'"'
    if "`resolved_preset'"=="" & "`canonical'"=="blm" local resolved_preset "static"
    if `"`resolved_preset'"' == "" local resolved_preset "simple"

    local presets ""
    local aliases ""
    local title ""
    local calibration_class ""
    local config_schema ""
    local configurable "no"
    if `"`canonical'"' == "akm" {
        local presets "simple stylized germany_chk_2002_2009"
        local aliases "akmsimple akmempirical"
        if !inlist(`"`resolved_preset'"', "simple", "stylized", ///
            "germany_chk_2002_2009") {
            di as error "unknown preset for dgp(akm): `resolved_preset'"
            di as error "registered presets are simple, stylized, and germany_chk_2002_2009"
            exit 198
        }
        if `"`resolved_preset'"' == "simple" {
            local title "Simple additive AKM with exogenous random mobility"
            local calibration_class "stylized"
            local config_schema "akm_simple_v3"
            local configurable "yes"
        }
        else if `"`resolved_preset'"' == "stylized" {
            local title "Reduced-form AKM with stylized empirical mobility"
            local calibration_class "stylized"
            local config_schema "akm_stylized_v3"
            local configurable "yes"
        }
        else {
            local title "Reduced-form AKM targeted to CHK West Germany, 2002-2009"
            local calibration_class "targeted"
            local config_schema "akm_germany_chk_2002_2009_v1"
            local configurable "yes"
        }
    }
    else if `"`canonical'"' == "akmpaygap" {
        local presets "simple cck2016"
        if !inlist(`"`resolved_preset'"', "simple", "cck2016") {
            di as error "unknown preset for dgp(akmpaygap): `resolved_preset'"
            di as error "registered presets are simple and cck2016"
            exit 198
        }
        if `"`resolved_preset'"' == "simple" {
            local title "Stylized two-group AKM pay-gap design"
            local calibration_class "stylized"
        }
        else {
            local title "Two-group AKM pay-gap design targeted to CCK Portugal, 2002-2009"
            local calibration_class "targeted"
        }
        local config_schema "akmpaygap_`resolved_preset'_v1"
        local configurable "yes"
    }

    else if "`canonical'"=="blm" {
        local presets "static dynamic"
        if !inlist("`resolved_preset'","static","dynamic") {
            di as error "BLM presets are static and dynamic"
            exit 198
        }
        local title "BLM-style finite worker and firm types"
        local calibration_class "stylized"
        local config_schema "blm_`resolved_preset'_v1"
        local configurable "yes"
    }
    else if `"`canonical'"' == "cpv" {
        local presets "simple heterogeneous"
        if !inlist(`"`resolved_preset'"', "simple", "heterogeneous") {
            di as error "unknown preset for dgp(cpv): `resolved_preset'"
            exit 198
        }
        local title "Cahuc-Postel-Vinay-Robin sequential wage bargaining"
        local calibration_class "stylized"
        local config_schema "cpv_`resolved_preset'_v1"
        local configurable "yes"
    }
    else {
        local presets "simple"
        local aliases "bmsimple"
        if `"`resolved_preset'"' != "simple" {
            di as error "unknown preset for dgp(bm): `resolved_preset'"
            di as error "the registered preset is simple"
            exit 198
        }
        local title "Canonical Burdett-Mortensen wage-posting model"
        local calibration_class "stylized"
        local config_schema "bm_simple_v1"
        local configurable "yes"
    }

    return local dgp `"`canonical'"'
    return local dgp_alias `"`requested'"'
    return local preset `"`resolved_preset'"'
    return local presets `"`presets'"'
    return local aliases `"`aliases'"'
    return local title `"`title'"'
    return local calibration_class `"`calibration_class'"'
    if "`canonical'"=="blm" | inlist(`"`canonical'/`resolved_preset'"', ///
        "akm/simple", "akm/stylized", "akm/germany_chk_2002_2009", ///
        "akmpaygap/simple", "akmpaygap/cck2016", "bm/simple", ///
        "cpv/simple", "cpv/heterogeneous") {
        return local status "qualified"
        return local implemented "yes"
    }
    else {
        return local status "planned"
        return local implemented "no"
    }
    return local configurable `"`configurable'"'
    return local config_schema `"`config_schema'"'
    return local frequencies "year quarter month"
    return local jobrules "end"
end
