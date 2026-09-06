version 16.0

mata:

struct fesim_bm_draw_buffer {
    real colvector event_buffer
    real colvector destination_buffer
    real scalar event_index
    real scalar destination_index
}

struct fesim_config {
    real scalar schema_version
    string scalar dgp
    string scalar preset
    string scalar calibration_class
    real scalar workers
    real scalar firms
    real scalar periods
    string scalar frequency
    string scalar start
    real scalar start_value
    real scalar end_value
    real scalar delta_years
    string scalar time_format
    string scalar internal_clock
    string scalar seed
    string scalar initial
    real scalar burnin
    string scalar jobrule
    string scalar truth
    string scalar connectivity
    string scalar report
    string rowvector parameter_names
    real rowvector parameter_values
    string scalar serialized
    real scalar validated
}

struct fesim_population {
    real scalar schema_version
    real scalar workers
    real scalar firms
    real colvector worker_id
    real colvector firm_id
    real colvector worker_value
    real colvector firm_value
    real colvector firm_weight
    real colvector worker_type_index
    real colvector worker_mobility
    real colvector firm_quality
    real colvector group
    real colvector firm_alt_value
    real colvector firm_surplus
    real scalar validated
}

struct fesim_state {
    real scalar schema_version
    real scalar period
    real colvector employed
    real colvector firm_id
    real colvector spell_id
    real colvector tenure
    real colvector unemployment_duration
    real colvector ntransitions
    real colvector current_value
    real colvector last_destination_uniform
    real scalar validated
}

struct fesim_results {
    real scalar schema_version
    string scalar status
    string scalar lifecycle
    real scalar N
    real scalar workers
    real scalar firms
    real scalar periods
    real rowvector parameters
    real rowvector targets
    real rowvector moments
    string rowvector metadata_names
    string rowvector metadata_values
    real matrix observed
    real scalar validated
}

struct fesim_handler {
    real scalar schema_version
    string scalar dgp
    string scalar preset
    string scalar lifecycle_stages
    real scalar solve_required
    string scalar qualification
}

struct fesim_network_results {
    real scalar schema_version
    real colvector diagnostics
    real colvector worker_component
    real colvector firm_component
    real scalar validated
}

struct fesim_network_design {
    real scalar schema_version
    string scalar mode
    real scalar block_count
    real scalar block_log_bonus
    real scalar bridge_count
    real scalar ladder_down_share
    real scalar ladder_lateral_share
    real scalar ladder_up_share
    real scalar ladder_band
    real colvector firm_rank
    real colvector worker_block
    real colvector firm_block
    real colvector worker_priority
    real matrix firm_cumulative
    real scalar bridge_phase
    real scalar bridge_output_period
    real scalar bridge_filled
    real colvector bridge_source_block
    real colvector bridge_target_block
    real colvector bridge_plan_worker
    real colvector bridge_plan_output_period
    real colvector bridge_plan_internal_period
    real colvector bridge_candidate_output_period
    real colvector bridge_candidate_internal_period
    real colvector bridge_interval_count
    real matrix bridge_ledger
    real scalar prepared
    real scalar validated
}

struct fesim_destination_tables {
    real scalar schema_version
    real rowvector worker_type_support
    real colvector firm_id
    real colvector firm_quality
    real colvector firm_weight
    real colvector firm_order
    real colvector firm_position
    real matrix ue_cumulative
    real colvector ue_log_scale
    real matrix ee_lower_cumulative
    real colvector ee_lower_log_scale
    real matrix ee_upper_reverse_cumulative
    real colvector ee_upper_log_scale
    real scalar theta_sort
    real scalar theta_quality
    real scalar theta_up
    real scalar theta_down
    string scalar network_mode
    real scalar block_count
    real scalar block_log_bonus
    real colvector firm_block
    real matrix ue_block_cumulative
    real colvector ue_block_log_scale
    real matrix ee_lower_block_cumulative
    real colvector ee_lower_block_log_scale
    real matrix ee_upper_block_reverse
    real colvector ee_upper_block_log_scale
    real scalar validated
}

struct fesim_empirical_params {
    real scalar schema_version
    real scalar kappa_eu
    real scalar eu_worker
    real scalar eu_firm
    real scalar eu_duration
    real scalar kappa_ee
    real scalar ee_worker
    real scalar ee_firm
    real scalar ee_duration
    real scalar kappa_ue
    real scalar ue_worker
    real scalar ue_duration
    real scalar validated
}

struct fesim_bm_solution {
    real scalar schema_version
    string scalar status
    real scalar b
    real scalar p
    real scalar lambda_u
    real scalar lambda_e
    real scalar delta
    real scalar discount
    real scalar surplus_coefficient
    real scalar reservation_wage
    real scalar upper_wage
    real scalar unemployment_rate
    real scalar employment_rate
    real scalar job_to_job_rate
    real scalar equilibrium_profit
    real scalar reservation_residual
    real scalar reservation_scaled_residual
    real scalar equal_profit_residual
    real scalar equal_profit_scaled_residual
    real scalar monotonicity_violation
    real scalar cdf_violation
    real colvector support_grid
    real colvector offer_cdf
    real colvector worker_cdf
    real colvector firm_employment
    real colvector firm_profit
    real scalar validated
}

struct fesim_bm_firms {
    real scalar schema_version
    string scalar status
    string scalar mode
    real scalar firms
    real scalar productivity
    real colvector firm_id
    real colvector offer_quantile
    real colvector posted_wage
    real colvector firm_productivity
    real colvector continuum_employment
    real colvector continuum_employment_mass
    real colvector continuum_profit
    real colvector expected_employment_mass
    real colvector expected_employment_share
    real colvector finite_scaled_employment
    real colvector finite_scaled_profit
    real colvector finite_worker_cdf
    real scalar continuum_aggregate_employment
    real scalar finite_aggregate_employment
    real scalar finite_job_to_job_rate
    real scalar offer_cdf_error
    real scalar worker_cdf_error
    real scalar continuum_employment_error
    real scalar finite_employment_error
    real scalar stationary_residual
    real scalar minimum_wage_gap
    real scalar wage_ties
    real scalar validated
}

struct fesim_bm_history {
    real scalar schema_version
    string scalar status
    real scalar workers
    real scalar firms
    real scalar horizon
    real scalar record_events
    real colvector initial_employed
    real colvector initial_firm_id
    real colvector initial_spell_id
    real colvector initial_tenure
    real colvector initial_unemployment_duration
    real colvector final_employed
    real colvector final_firm_id
    real colvector final_spell_id
    real colvector final_tenure
    real colvector final_unemployment_duration
    real colvector final_transitions
    real matrix events
    real scalar total_events
    real scalar unemployment_offers
    real scalar employed_offers
    real scalar destructions
    real scalar accepted_entries
    real scalar accepted_moves
    real scalar rejected_offers
    real scalar total_transitions
    real scalar validated
}

struct fesim_bm_state {
    real scalar schema_version
    string scalar status
    string scalar initial_mode
    real scalar workers
    real scalar firms
    real scalar elapsed_time
    real colvector employed
    real colvector firm_id
    real colvector spell_id
    real colvector tenure
    real colvector unemployment_duration
    real colvector ntransitions
    real scalar validated
}

struct fesim_bm_panel {
    real scalar schema_version
    string scalar status
    string scalar frequency
    real scalar workers
    real scalar firms
    real scalar periods
    real scalar period_length
    real scalar horizon
    real colvector worker_id
    real colvector period_index
    real colvector employed
    real colvector firm_id
    real colvector spell_id
    real colvector tenure
    real colvector unemployment_duration
    real colvector n_eu
    real colvector n_ee
    real colvector n_ue
    real colvector n_unemployment_offers
    real colvector n_employed_offers
    real colvector n_rejected_offers
    real colvector n_events
    real colvector ntransitions
    real colvector employment_exposure
    real colvector unemployment_exposure
    real colvector newjob
    real colvector from_unemp
    real colvector to_unemp
    real colvector jobtojob
    real scalar validated
}

real scalar fesim_mata_api_version()
{
    return(36)
}

real scalar fesim_config_schema_version()
{
    return(2)
}

real scalar fesim_population_schema_version()
{
    return(4)
}

real scalar fesim_state_schema_version()
{
    return(5)
}

real scalar fesim_results_schema_version()
{
    return(2)
}

real scalar fesim_handler_schema_version()
{
    return(1)
}

end
