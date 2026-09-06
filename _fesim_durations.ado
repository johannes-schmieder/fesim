*! fesim duration diagnostics 1.1.0-dev 05sep2026
program define _fesim_durations, rclass
    version 16.0
    syntax , DELTAYEARS(real)

    if missing(`deltayears') | `deltayears' <= 0 {
        di as error "deltayears() must be positive"
        exit 198
    }
    foreach variable in employed tenure unemp_duration {
        capture confirm numeric variable `variable'
        if _rc {
            di as error "required duration variable is missing: `variable'"
            exit 111
        }
    }
    capture assert inlist(employed, 0, 1)
    if _rc {
        di as error "employed must contain only zero and one"
        exit 459
    }
    capture assert tenure >= 0 & !missing(tenure) if employed
    if _rc {
        di as error "employed observations require nonnegative tenure"
        exit 459
    }
    capture assert missing(tenure) if !employed
    if _rc {
        di as error "nonemployed observations must have missing tenure"
        exit 459
    }
    capture assert unemp_duration >= 0 & !missing(unemp_duration) if !employed
    if _rc {
        di as error "nonemployed observations require nonnegative unemployment duration"
        exit 459
    }
    capture assert missing(unemp_duration) if employed
    if _rc {
        di as error "employed observations must have missing unemployment duration"
        exit 459
    }

    tempname durations
    matrix `durations' = J(12, 1, .)
    matrix rownames `durations' = tenure_years_N tenure_years_mean ///
        tenure_years_sd tenure_years_p10 tenure_years_p50 ///
        tenure_years_p90 unemployment_duration_years_N ///
        unemployment_duration_years_mean ///
        unemployment_duration_years_sd unemployment_duration_years_p10 ///
        unemployment_duration_years_p50 unemployment_duration_years_p90
    matrix colnames `durations' = realized

    quietly summarize tenure if employed
    matrix `durations'[1, 1] = r(N)
    if r(N) {
        matrix `durations'[2, 1] = r(mean) * `deltayears'
        if r(N) > 1 matrix `durations'[3, 1] = r(sd) * `deltayears'
        quietly _pctile tenure if employed, percentiles(10 50 90)
        matrix `durations'[4, 1] = r(r1) * `deltayears'
        matrix `durations'[5, 1] = r(r2) * `deltayears'
        matrix `durations'[6, 1] = r(r3) * `deltayears'
    }

    quietly summarize unemp_duration if !employed
    matrix `durations'[7, 1] = r(N)
    if r(N) {
        matrix `durations'[8, 1] = r(mean) * `deltayears'
        if r(N) > 1 matrix `durations'[9, 1] = r(sd) * `deltayears'
        quietly _pctile unemp_duration if !employed, percentiles(10 50 90)
        matrix `durations'[10, 1] = r(r1) * `deltayears'
        matrix `durations'[11, 1] = r(r2) * `deltayears'
        matrix `durations'[12, 1] = r(r3) * `deltayears'
    }

    return matrix durations = `durations'
end
