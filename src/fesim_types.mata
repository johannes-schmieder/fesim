version 16.0

mata:

struct fesim_config {
    string scalar dgp
    string scalar preset
}

real scalar fesim_mata_api_version()
{
    return(1)
}

end
