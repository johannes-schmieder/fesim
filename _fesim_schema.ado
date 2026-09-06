*! fesim discovery output schema 1.2.0-rc.1 06sep2026
program define _fesim_schema, rclass
    version 16.0
    syntax , DGP(string) PRESet(string)
    local observed "workerid time firmid employed lnwage spellid tenure newjob from_unemp to_unemp jobtojob ntransitions"
    local basic "alpha_true psi_true time_true xb_true match_true epsilon_true lnwage_true"
    local full ""
    local initial "random allunemployed"
    local networks "random"
    local conditional ""
    local source "Stylized package design; no empirical replication claim."
    local targets "Primitive wage-component moments; mobility is stylized."
    if "`dgp'" == "akm" {
        local networks "random blocks bridges ladder"
        local conditional "blocks/bridges: worker_block_true firm_block_true under full truth; bridges: nbridges_imposed under every truth mode"
        if "`preset'" == "simple" local initial "stationary random allunemployed"
        else {
            local observed "`observed' unemp_duration"
            local full "worker_type_true firm_quality_true"
        }
        if "`preset'" == "germany_chk_2002_2009" {
            local source "Card, Heining, and Kline (2013), QJE 128(3), Tables 4-5; doi:10.1093/qje/qjt006."
            local targets "CHK 2002-2009 wage-component dispersions and covariance .0205; hazards/durations remain stylized."
        }
    }
    else if "`dgp'" == "akmpaygap" {
        local observed "`observed' group"
        local full "firm_surplus_true psi_male_true psi_female_true"
        if "`preset'" == "cck2016" {
            local source "Card, Cardoso, and Kline (2016), QJE 131(2), Tables II-III; doi:10.1093/qje/qjv038."
            local targets "Selected group moments and male-reference decomposition; package surplus normalization differs from CCK."
        }
    }
    else if "`dgp'" == "bm" {
        local observed "`observed' unemp_duration"
        local basic "lnwage_true posted_wage_true productivity_true"
        local full "reservation_wage_true unemployment_value_true employment_value_true offer_quantile_true expected_firm_mass_true expected_firm_share_true continuum_employment_true finite_scaled_employment_true continuum_profit_true finite_scaled_profit_true n_eu_true n_ee_true n_ue_true n_unemployment_offers_true n_employed_offers_true n_rejected_offers_true n_events_true ntransitions_true employment_exposure_true unemployment_exposure_true"
        local initial "stationary random allunemployed"
        local source "Burdett and Mortensen (1998), IER 39(2); doi:10.2307/2527292. Exact homogeneous model, stylized primitives."
        local targets "Continuum equilibrium and exact finite-firm stationary allocation are distinct; no empirical calibration."
    }
    else if "`dgp'" == "cpv" {
        local observed "`observed' unemp_duration"
        local basic "lnwage_true contract_wage_true worker_ability_true firm_productivity_true match_productivity_true"
        local full "bargaining_firm_true unemployment_value_true employment_value_true full_match_value_true reference_surplus_true reference_value_true n_eu_true n_ee_true n_ue_true n_unemployment_offers_true n_employed_offers_true n_rejected_offers_true n_events_true ntransitions_true n_renegotiations_true employment_exposure_true unemployment_exposure_true"
        local initial "stationary random allunemployed"
        local source "Cahuc, Postel-Vinay and Robin (2006), Econometrica 74(2); doi:10.1111/j.1468-0262.2006.00665.x. Stylized primitives."
        local targets "Exact finite-firm bargaining model; structural productivity is not an AKM firm effect. No empirical calibration."
    }
    else if "`dgp'"=="blm" {
        local observed "workerid time firmid employed lnwage spellid tenure unemp_duration newjob from_unemp to_unemp jobtojob ntransitions"
        local basic "worker_type_true firm_type_true wage_location_true conditional_mean_true epsilon_true lnwage_true"
        local full "lag_lnwage_true lag_firm_type_true persistence_true move_shift_true innovation_sd_true move_probability_true moved_month_true n_ee_true"
        local initial "random"
        local source "Bonhomme, Lamadon and Manresa (2019), Econometrica 87(3); doi:10.3982/ECTA15722. BLM-style forward monthly process."
        local targets "Illustrative finite-type parameters; no empirical calibration, BLM estimator, or population AKM projection."
    }
    else exit 198
    return local observed_variables "`observed'"
    return local truth_basic_variables "`basic'"
    return local truth_full_variables "`full'"
    return local conditional_variables "`conditional'"
    return local initial_modes "`initial'"
    return local networks "`networks'"
    return local source_note "`source'"
    return local target_scope "`targets'"
end
