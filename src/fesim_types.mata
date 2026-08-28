version 16.0

mata:

struct fesim_config {
    string scalar dgp
    string scalar preset
    real scalar workers
    real scalar firms
    real scalar periods
    string scalar frequency
    string scalar start
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
}

real scalar fesim_mata_api_version()
{
    return(1)
}

real scalar fesim_config_schema_version()
{
    return(1)
}

end
