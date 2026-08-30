version 16.0

mata:

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

real scalar fesim_mata_api_version()
{
    return(17)
}

real scalar fesim_config_schema_version()
{
    return(2)
}

real scalar fesim_population_schema_version()
{
    return(3)
}

real scalar fesim_state_schema_version()
{
    return(4)
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
