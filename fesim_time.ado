*! fesim common time normalizer 0.2.0-dev 29aug2026
program define fesim_time, rclass
    version 16.0
    syntax , FREQuency(string) [START(string) PERIODs(integer 1)]

    local frequency = lower(strtrim(`"`frequency'"'))
    if !inlist(`"`frequency'"', "year", "quarter", "month") {
        di as error "frequency() must be year, quarter, or month"
        exit 198
    }
    if `periods' < 1 {
        di as error "periods() must be a positive integer"
        exit 198
    }

    local start = lower(strtrim(`"`start'"'))
    if `"`start'"' == "" {
        if `"`frequency'"' == "year" local start "2000"
        else if `"`frequency'"' == "quarter" local start "2000q1"
        else local start "2000m1"
    }

    local year_text = substr(`"`start'"', 1, 4)
    local year_valid = strlen(`"`year_text'"') == 4 & ///
        regexm(`"`year_text'"', "^[0-9]+$")
    if `"`frequency'"' == "year" {
        if strlen(`"`start'"') != 4 | !`year_valid' {
            di as error "start() must have form YYYY with frequency(year)"
            exit 198
        }
        local start_value = yearly(`"`start'"', "Y")
        local time_format "%ty"
        local periods_per_year 1
        local interval_unit "year"
    }
    else if `"`frequency'"' == "quarter" {
        if strlen(`"`start'"') != 6 | !`year_valid' | ///
            substr(`"`start'"', 5, 1) != "q" | ///
            !regexm(substr(`"`start'"', 6, 1), "^[1-4]$") {
            di as error "start() must have form YYYYqQ with frequency(quarter)"
            exit 198
        }
        local start_value = quarterly(`"`start'"', "YQ")
        local time_format "%tq"
        local periods_per_year 4
        local interval_unit "quarter"
    }
    else {
        local month_text = substr(`"`start'"', 6, .)
        if !inlist(strlen(`"`start'"'), 6, 7) | !`year_valid' | ///
            substr(`"`start'"', 5, 1) != "m" | ///
            !regexm(`"`month_text'"', "^([1-9]|1[0-2])$") {
            di as error "start() must have form YYYYmM with frequency(month)"
            exit 198
        }
        local start_value = monthly(`"`start'"', "YM")
        local time_format "%tm"
        local periods_per_year 12
        local interval_unit "month"
    }
    if missing(`start_value') {
        di as error "start() is invalid for frequency(`frequency')"
        exit 198
    }

    return local frequency `"`frequency'"'
    return local start `"`start'"'
    return local format `"`time_format'"'
    return local interval_unit `"`interval_unit'"'
    return local internal_clock "output_period"
    return scalar start_value = `start_value'
    return scalar end_value = `start_value' + `periods' - 1
    return scalar periods = `periods'
    return scalar periods_per_year = `periods_per_year'
    return scalar delta_years = 1 / `periods_per_year'
end
