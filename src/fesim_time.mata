version 16.0

mata:

real scalar fesim_time_schema_version()
{
    return(1)
}

real scalar fesim_time_periods_per_year(string scalar frequency)
{
    frequency = strlower(strtrim(frequency))
    if (frequency == "year") return(1)
    if (frequency == "quarter") return(4)
    if (frequency == "month") return(12)
    _error(3300, "frequency must be year, quarter, or month")
}

real scalar fesim_time_delta_years(string scalar frequency)
{
    return(1 / fesim_time_periods_per_year(frequency))
}

real colvector fesim_time_values(real scalar start_value, real scalar periods)
{
    if (missing(start_value) | missing(periods) | periods < 1 | ///
        periods != floor(periods)) {
        _error(3300, "start value must be nonmissing and periods must be positive")
    }
    return(start_value :+ (0::(periods - 1)))
}

real scalar fesim_rate_annual_to_interval(
    real scalar annual_probability,
    real scalar delta_years)
{
    if (missing(annual_probability) | annual_probability < 0 | ///
        annual_probability > 1) {
        _error(3300, "annual probability must lie in [0,1]")
    }
    if (missing(delta_years) | delta_years <= 0) {
        _error(3300, "interval length must be positive")
    }
    return(1 - (1 - annual_probability)^delta_years)
}

real rowvector fesim_rate_competing_to_interval(
    real scalar annual_first,
    real scalar annual_second,
    real scalar delta_years)
{
    real scalar annual_any
    real scalar interval_any
    real scalar stay

    if (missing(annual_first) | missing(annual_second) | ///
        annual_first < 0 | annual_second < 0 | ///
        annual_first + annual_second >= 1) {
        _error(3300, "competing annual probabilities must be nonnegative and sum below 1")
    }
    if (missing(delta_years) | delta_years <= 0) {
        _error(3300, "interval length must be positive")
    }
    annual_any = annual_first + annual_second
    if (annual_any == 0) return((0, 0, 1))
    stay = (1 - annual_any)^delta_years
    interval_any = 1 - stay
    return((annual_first / annual_any * interval_any, ///
        annual_second / annual_any * interval_any, stay))
}

end
