version 16.0

mata:

real scalar fesim_hazard_schema_version()
{
    return(1)
}

real colvector fesim_hazard_duration_transform(real colvector duration_years)
{
    if (cols(duration_years) != 1 | any(missing(duration_years)) | ///
        any(duration_years :< 0)) {
        _error(3300, "duration in years must be a nonnegative column vector")
    }
    return(ln(1 :+ duration_years))
}

real colvector fesim_hazard_employed_log(
    real scalar intercept,
    real scalar worker_coefficient,
    real colvector worker_type,
    real scalar firm_coefficient,
    real colvector firm_quality,
    real scalar duration_coefficient,
    real colvector tenure_years)
{
    real scalar n

    n = rows(worker_type)
    if (cols(worker_type) != 1 | cols(firm_quality) != 1 | ///
        cols(tenure_years) != 1 | rows(firm_quality) != n | ///
        rows(tenure_years) != n | n < 1 | ///
        any(missing((intercept, worker_coefficient, firm_coefficient, ///
            duration_coefficient))) | any(missing(worker_type)) | ///
        any(missing(firm_quality))) {
        _error(3300, "employed hazard inputs must be nonmissing conformable columns")
    }
    return(intercept :+ worker_coefficient :* worker_type :+ ///
        firm_coefficient :* firm_quality :+ ///
        duration_coefficient :* fesim_hazard_duration_transform(tenure_years))
}

real colvector fesim_hazard_unemployed_log(
    real scalar intercept,
    real scalar worker_coefficient,
    real colvector worker_type,
    real scalar duration_coefficient,
    real colvector unemployment_years)
{
    real scalar n

    n = rows(worker_type)
    if (cols(worker_type) != 1 | cols(unemployment_years) != 1 | ///
        rows(unemployment_years) != n | n < 1 | ///
        any(missing((intercept, worker_coefficient, duration_coefficient))) | ///
        any(missing(worker_type))) {
        _error(3300, "unemployed hazard inputs must be nonmissing conformable columns")
    }
    return(intercept :+ worker_coefficient :* worker_type :+ ///
        duration_coefficient :* ///
        fesim_hazard_duration_transform(unemployment_years))
}

real scalar fesim_hazard_one_minus_exp_neg(real scalar exposure)
{
    if (missing(exposure) | exposure < 0) {
        _error(3300, "hazard exposure must be nonnegative")
    }
    if (exposure == 0) return(0)
    if (exposure >= 36.7368005696771) return(1)
    if (exposure < 1e-5) {
        return(exposure - exposure^2 / 2 + exposure^3 / 6 - ///
            exposure^4 / 24)
    }
    return(1 - exp(-exposure))
}

real colvector fesim_hazard_one_from_rates(
    real colvector annual_hazard,
    real scalar delta_years)
{
    real scalar i
    real colvector probability

    if (cols(annual_hazard) != 1 | any(missing(annual_hazard)) | ///
        any(annual_hazard :< 0) | missing(delta_years) | delta_years <= 0) {
        _error(3300, "annual hazards must be nonnegative and interval length positive")
    }
    probability = J(rows(annual_hazard), 1, .)
    for (i = 1; i <= rows(annual_hazard); i++) {
        if (annual_hazard[i] == 0) probability[i] = 0
        else probability[i] = fesim_hazard_one_from_log(
            ln(annual_hazard[i]), delta_years)
    }
    return(probability)
}

real colvector fesim_hazard_one_from_log(
    real colvector log_annual_hazard,
    real scalar delta_years)
{
    real scalar i, log_saturation, exposure
    real colvector probability

    if (cols(log_annual_hazard) != 1 | ///
        any(missing(log_annual_hazard)) | missing(delta_years) | ///
        delta_years <= 0) {
        _error(3300, "log annual hazards must be nonmissing and interval length positive")
    }
    log_saturation = ln(36.7368005696771) - ln(delta_years)
    probability = J(rows(log_annual_hazard), 1, .)
    for (i = 1; i <= rows(log_annual_hazard); i++) {
        if (log_annual_hazard[i] >= log_saturation) probability[i] = 1
        else {
            exposure = delta_years * exp(log_annual_hazard[i])
            probability[i] = fesim_hazard_one_minus_exp_neg(exposure)
        }
    }
    return(probability)
}

real matrix fesim_hazard_competing_from_log(
    real colvector log_first,
    real colvector log_second,
    real scalar delta_years)
{
    real scalar i, largest, first_relative, second_relative
    real scalar relative_sum, log_total, event_probability
    real matrix probability

    if (cols(log_first) != 1 | cols(log_second) != 1 | ///
        rows(log_first) != rows(log_second) | rows(log_first) < 1 | ///
        any(missing(log_first)) | any(missing(log_second)) | ///
        missing(delta_years) | delta_years <= 0) {
        _error(3300, "competing log hazards must be nonmissing conformable columns")
    }
    probability = J(rows(log_first), 3, .)
    for (i = 1; i <= rows(log_first); i++) {
        largest = max((log_first[i], log_second[i]))
        first_relative = exp(log_first[i] - largest)
        second_relative = exp(log_second[i] - largest)
        relative_sum = first_relative + second_relative
        log_total = largest + ln(relative_sum)
        event_probability = fesim_hazard_one_from_log(log_total, delta_years)
        probability[i, 1] = first_relative / relative_sum * event_probability
        probability[i, 2] = second_relative / relative_sum * event_probability
        probability[i, 3] = 1 - event_probability
    }
    return(probability)
}

real matrix fesim_hazard_competing_rates(
    real colvector annual_first,
    real colvector annual_second,
    real scalar delta_years)
{
    real scalar i, largest, first_relative, second_relative
    real scalar relative_sum, log_total, event_probability
    real matrix probability

    if (cols(annual_first) != 1 | cols(annual_second) != 1 | ///
        rows(annual_first) != rows(annual_second) | rows(annual_first) < 1 | ///
        any(missing(annual_first)) | any(missing(annual_second)) | ///
        any(annual_first :< 0) | any(annual_second :< 0) | ///
        missing(delta_years) | delta_years <= 0) {
        _error(3300, "competing annual hazards must be nonnegative conformable columns")
    }
    probability = J(rows(annual_first), 3, .)
    for (i = 1; i <= rows(annual_first); i++) {
        largest = max((annual_first[i], annual_second[i]))
        if (largest == 0) probability[i, .] = (0, 0, 1)
        else {
            first_relative = annual_first[i] / largest
            second_relative = annual_second[i] / largest
            relative_sum = first_relative + second_relative
            log_total = ln(largest) + ln(relative_sum)
            event_probability = fesim_hazard_one_from_log(log_total, delta_years)
            probability[i, 1] = first_relative / relative_sum * event_probability
            probability[i, 2] = second_relative / relative_sum * event_probability
            probability[i, 3] = 1 - event_probability
        }
    }
    return(probability)
}

end
