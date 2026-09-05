version 16.0

mata:

real scalar fesim_bm_schema_version()
{
    return(1)
}

real scalar fesim_bm_firms_schema_version()
{
    return(1)
}

real scalar fesim_bm_log1p(real scalar x)
{
    real scalar power, sign, term, total, order

    if (missing(x) | x <= -1) {
        _error(3300, "BM log1p input must exceed -1")
    }
    if (abs(x) >= .1) return(ln(1 + x))
    power = x
    sign = 1
    total = 0
    for (order = 1; order <= 40; order++) {
        term = sign * power / order
        total = total + term
        power = power * x
        sign = -sign
    }
    return(total)
}

real scalar fesim_bm_surplus_coefficient(
    real scalar lambda_e,
    real scalar delta,
    real scalar discount)
{
    real scalar scale, ratio, rho, bracket
    real scalar power, sign, order

    if (any(missing((lambda_e, delta, discount))) | ///
        lambda_e <= 0 | delta <= 0 | discount <= 0) {
        _error(3300, "BM rates and discount must be positive")
    }
    scale = discount + delta
    ratio = lambda_e / scale
    rho = discount / scale
    if (ratio < .1) {
        bracket = .5 * (1 - rho)
        power = ratio
        sign = 1
        for (order = 1; order <= 30; order++) {
            bracket = bracket + rho * sign * power / (order + 2)
            power = power * ratio
            sign = -sign
        }
    }
    else {
        bracket = .5 + rho * ///
            (fesim_bm_log1p(ratio) / ratio / ratio - 1 / ratio)
    }
    if (missing(bracket) | bracket <= 0) {
        _error(430, "BM surplus coefficient could not be evaluated")
    }
    return(2 * (lambda_e / (delta + lambda_e)) / ///
        (delta + lambda_e) * bracket)
}

real scalar fesim_bm_upper_wage(
    real scalar p,
    real scalar reservation,
    real scalar lambda_e,
    real scalar delta)
{
    real scalar ratio

    if (any(missing((p, reservation, lambda_e, delta))) | ///
        p <= reservation | lambda_e <= 0 | delta <= 0) {
        _error(3300, "BM support inputs are invalid")
    }
    ratio = delta / (delta + lambda_e)
    return(p - (p - reservation) * ratio^2)
}

real colvector fesim_bm_offer_cdf(
    real colvector wage,
    real scalar p,
    real scalar reservation,
    real scalar lambda_e,
    real scalar delta)
{
    real scalar i, upper
    real colvector cdf

    if (cols(wage) != 1 | rows(wage) < 1 | any(missing(wage))) {
        _error(3300, "BM wages must be a nonmissing column")
    }
    upper = fesim_bm_upper_wage(p, reservation, lambda_e, delta)
    cdf = J(rows(wage), 1, .)
    for (i = 1; i <= rows(wage); i++) {
        if (wage[i] <= reservation) cdf[i] = 0
        else if (wage[i] >= upper) cdf[i] = 1
        else {
            cdf[i] = (delta + lambda_e) / lambda_e * ///
                (1 - sqrt((p - wage[i]) / (p - reservation)))
        }
    }
    return(cdf)
}

real colvector fesim_bm_worker_cdf(
    real colvector offer_cdf,
    real scalar lambda_e,
    real scalar delta)
{
    if (cols(offer_cdf) != 1 | rows(offer_cdf) < 1 | ///
        any(missing(offer_cdf)) | any(offer_cdf :< 0) | ///
        any(offer_cdf :> 1) | missing(lambda_e) | lambda_e <= 0 | ///
        missing(delta) | delta <= 0) {
        _error(3300, "BM offer CDF or rates are invalid")
    }
    /* Preserve exact probability boundaries despite vector division rounding. */
    real colvector cdf, endpoints
    cdf = delta :* offer_cdf :/ ///
        (delta :+ lambda_e :* (1 :- offer_cdf))
    endpoints = selectindex(offer_cdf :== 1)
    if (length(endpoints)) cdf[endpoints] = J(length(endpoints), 1, 1)
    return(cdf)
}

real colvector fesim_bm_firm_employment(
    real colvector offer_cdf,
    real scalar lambda_u,
    real scalar lambda_e,
    real scalar delta)
{
    if (cols(offer_cdf) != 1 | rows(offer_cdf) < 1 | ///
        any(missing(offer_cdf)) | any(offer_cdf :< 0) | ///
        any(offer_cdf :> 1) | ///
        any(missing((lambda_u, lambda_e, delta))) | ///
        lambda_u <= 0 | lambda_e <= 0 | delta <= 0) {
        _error(3300, "BM offer CDF or rates are invalid")
    }
    return(delta * lambda_u * (delta + lambda_e) :/ ///
        ((delta + lambda_u) :* ///
        (delta :+ lambda_e :* (1 :- offer_cdf)):^2))
}

real scalar fesim_bm_job_to_job_rate(
    real scalar lambda_e,
    real scalar delta)
{
    real scalar ratio, power, sign, order, scaled

    if (any(missing((lambda_e, delta))) | lambda_e <= 0 | delta <= 0) {
        _error(3300, "BM employed-offer and destruction rates must be positive")
    }
    ratio = lambda_e / delta
    if (ratio < .1) {
        scaled = 0
        power = ratio
        sign = 1
        for (order = 1; order <= 30; order++) {
            scaled = scaled + sign * power / (order * (order + 1))
            power = power * ratio
            sign = -sign
        }
        return(delta * scaled)
    }
    return(delta * ((1 + ratio) / ratio * ///
        fesim_bm_log1p(ratio) - 1))
}

real scalar fesim_bm_reservation_residual(
    real scalar reservation,
    real scalar b,
    real scalar p,
    real scalar lambda_u,
    real scalar lambda_e,
    real scalar delta,
    real scalar discount,
    real scalar intervals)
{
    real scalar upper, step, i, surplus
    real colvector wage, offer_cdf, integrand, weight

    if (any(missing((reservation, b, p, lambda_u, lambda_e, ///
        delta, discount, intervals))) | reservation >= p | ///
        lambda_u <= 0 | lambda_e <= 0 | delta <= 0 | discount <= 0 | ///
        intervals < 100 | intervals != floor(intervals) | ///
        mod(intervals, 2) != 0) {
        _error(3300, "BM numerical residual inputs are invalid")
    }
    upper = fesim_bm_upper_wage(p, reservation, lambda_e, delta)
    step = (upper - reservation) / intervals
    if (missing(step) | step <= 0) {
        _error(430, "BM numerical support collapsed")
    }
    wage = reservation :+ (0::intervals) * step
    offer_cdf = fesim_bm_offer_cdf(
        wage, p, reservation, lambda_e, delta)
    integrand = (1 :- offer_cdf) :/ ///
        (discount + delta :+ lambda_e :* (1 :- offer_cdf))
    weight = J(intervals + 1, 1, 2)
    weight[1] = 1
    weight[intervals + 1] = 1
    for (i = 2; i <= intervals; i++) {
        if (mod(i, 2) == 0) weight[i] = 4
    }
    surplus = step / 3 * sum(weight :* integrand)
    return(reservation - b - (lambda_u - lambda_e) * surplus)
}

void fesim_bm_solution_validate(
    struct fesim_bm_solution scalar solution,
    real scalar tolerance)
{
    real scalar n
    real colvector grid_difference, offer_difference, worker_difference

    n = rows(solution.support_grid)
    if (solution.schema_version != fesim_bm_schema_version() | ///
        solution.status != "converged_analytic" | ///
        missing(tolerance) | tolerance <= 0 | ///
        any(missing((solution.b, solution.p, solution.lambda_u, ///
            solution.lambda_e, solution.delta, solution.discount, ///
            solution.surplus_coefficient, solution.reservation_wage, ///
            solution.upper_wage, solution.unemployment_rate, ///
            solution.employment_rate, solution.job_to_job_rate, ///
            solution.equilibrium_profit, solution.reservation_residual, ///
            solution.reservation_scaled_residual, ///
            solution.equal_profit_residual, ///
            solution.equal_profit_scaled_residual, ///
            solution.monotonicity_violation, solution.cdf_violation)))) {
        _error(3300, "BM solution structure is invalid")
    }
    if (n < 3 | cols(solution.support_grid) != 1 | ///
        rows(solution.offer_cdf) != n | cols(solution.offer_cdf) != 1 | ///
        rows(solution.worker_cdf) != n | cols(solution.worker_cdf) != 1 | ///
        rows(solution.firm_employment) != n | ///
        cols(solution.firm_employment) != 1 | ///
        rows(solution.firm_profit) != n | cols(solution.firm_profit) != 1 | ///
        any(missing(solution.support_grid)) | ///
        any(missing(solution.offer_cdf)) | ///
        any(missing(solution.worker_cdf)) | ///
        any(missing(solution.firm_employment)) | ///
        any(missing(solution.firm_profit))) {
        _error(3300, "BM solution structure is invalid")
    }
    grid_difference = solution.support_grid[|2 \ n|] :- ///
        solution.support_grid[|1 \ (n - 1)|]
    offer_difference = solution.offer_cdf[|2 \ n|] :- ///
        solution.offer_cdf[|1 \ (n - 1)|]
    worker_difference = solution.worker_cdf[|2 \ n|] :- ///
        solution.worker_cdf[|1 \ (n - 1)|]
    if (solution.p <= solution.b | solution.reservation_wage <= 0 | ///
        solution.lambda_u <= 0 | solution.lambda_e <= 0 | ///
        solution.delta <= 0 | solution.discount <= 0 | ///
        solution.surplus_coefficient <= 0 | ///
        solution.reservation_wage >= solution.upper_wage | ///
        solution.upper_wage >= solution.p | ///
        solution.unemployment_rate <= 0 | solution.unemployment_rate >= 1 | ///
        solution.employment_rate <= 0 | solution.employment_rate >= 1 | ///
        solution.job_to_job_rate <= 0 | ///
        solution.job_to_job_rate >= solution.lambda_e | ///
        solution.equilibrium_profit <= 0) {
        _error(430, "BM solution violates interior support or rate conditions")
    }
    if (solution.support_grid[1] != solution.reservation_wage | ///
        solution.support_grid[n] != solution.upper_wage | ///
        solution.offer_cdf[1] != 0 | solution.offer_cdf[n] != 1 | ///
        solution.worker_cdf[1] != 0 | solution.worker_cdf[n] != 1 | ///
        min(grid_difference) <= 0 | min(offer_difference) < -tolerance | ///
        min(worker_difference) < -tolerance | ///
        min(solution.offer_cdf) < -tolerance | ///
        max(solution.offer_cdf) > 1 + tolerance | ///
        min(solution.worker_cdf) < -tolerance | ///
        max(solution.worker_cdf) > 1 + tolerance) {
        _error(430, "BM support grid or CDF failed validation")
    }
    if (any(solution.firm_employment :<= 0) | ///
        any(solution.firm_profit :<= 0) | ///
        max(abs(solution.firm_profit :- ///
            (solution.p :- solution.support_grid) :* ///
            solution.firm_employment)) > tolerance | ///
        max(abs(solution.firm_profit :- ///
            solution.equilibrium_profit)) / ///
            max((1, abs(solution.equilibrium_profit))) > tolerance) {
        _error(430, "BM firm profit failed equal-profit validation")
    }
    if (mreldif(solution.offer_cdf, fesim_bm_offer_cdf(
            solution.support_grid, solution.p, ///
            solution.reservation_wage, solution.lambda_e, ///
            solution.delta)) > tolerance | ///
        mreldif(solution.worker_cdf, fesim_bm_worker_cdf(
            solution.offer_cdf, solution.lambda_e, ///
            solution.delta)) > tolerance | ///
        mreldif(solution.firm_employment, fesim_bm_firm_employment(
            solution.offer_cdf, solution.lambda_u, ///
            solution.lambda_e, solution.delta)) > tolerance) {
        _error(430, "BM distribution or employment failed recomputation validation")
    }
    if (abs(solution.surplus_coefficient - ///
            fesim_bm_surplus_coefficient(solution.lambda_e, ///
            solution.delta, solution.discount)) / ///
            max((1, abs(solution.surplus_coefficient))) > tolerance | ///
        abs(solution.upper_wage - fesim_bm_upper_wage(
            solution.p, solution.reservation_wage, ///
            solution.lambda_e, solution.delta)) / ///
            max((1, abs(solution.upper_wage))) > tolerance | ///
        abs(solution.reservation_residual) / ///
            max((1, abs(solution.b), abs(solution.p), ///
            abs(solution.reservation_wage))) > tolerance | ///
        abs(solution.unemployment_rate + solution.employment_rate - 1) > ///
            tolerance | ///
        min((solution.reservation_scaled_residual, ///
            solution.equal_profit_scaled_residual, ///
            solution.monotonicity_violation, solution.cdf_violation)) < 0 | ///
        solution.reservation_scaled_residual > tolerance | ///
        solution.equal_profit_scaled_residual > tolerance | ///
        solution.monotonicity_violation > tolerance | ///
        solution.cdf_violation > tolerance) {
        _error(430, "BM solution residuals exceed tolerance")
    }
}

struct fesim_bm_solution scalar fesim_bm_solve(
    real scalar b,
    real scalar p,
    real scalar lambda_u,
    real scalar lambda_e,
    real scalar delta,
    real scalar discount,
    real scalar grid_points,
    real scalar quadrature_intervals,
    real scalar tolerance)
{
    real scalar denominator, grid_scale, n
    real colvector grid_difference, offer_difference, worker_difference
    struct fesim_bm_solution scalar solution

    if (any(missing((b, p, lambda_u, lambda_e, delta, discount, ///
        grid_points, quadrature_intervals, tolerance))) | p <= b | ///
        lambda_u <= 0 | lambda_e <= 0 | delta <= 0 | discount <= 0 | ///
        grid_points < 3 | grid_points != floor(grid_points) | ///
        quadrature_intervals < 100 | ///
        quadrature_intervals != floor(quadrature_intervals) | ///
        mod(quadrature_intervals, 2) != 0 | ///
        grid_points > 1000000 | quadrature_intervals > 1000000 | ///
        tolerance <= 0 | tolerance > 1e-4) {
        _error(3300, "BM solver primitives or controls are invalid")
    }
    solution.schema_version = fesim_bm_schema_version()
    solution.status = "converged_analytic"
    solution.b = b
    solution.p = p
    solution.lambda_u = lambda_u
    solution.lambda_e = lambda_e
    solution.delta = delta
    solution.discount = discount
    solution.surplus_coefficient = ///
        fesim_bm_surplus_coefficient(lambda_e, delta, discount)
    denominator = 1 + (lambda_u - lambda_e) * ///
        solution.surplus_coefficient
    if (missing(denominator) | denominator <= 0) {
        _error(430, "BM reservation-wage denominator is invalid")
    }
    solution.reservation_wage = ///
        (b + (lambda_u - lambda_e) * ///
        solution.surplus_coefficient * p) / denominator
    if (missing(solution.reservation_wage) | ///
        solution.reservation_wage <= 0 | ///
        solution.reservation_wage >= p) {
        _error(3300, "BM solution requires a positive reservation wage below productivity")
    }
    solution.upper_wage = fesim_bm_upper_wage(
        p, solution.reservation_wage, lambda_e, delta)
    if (missing(solution.upper_wage) | ///
        solution.upper_wage <= solution.reservation_wage | ///
        solution.upper_wage >= p) {
        _error(430, "BM analytical wage support is invalid")
    }
    solution.unemployment_rate = delta / (delta + lambda_u)
    solution.employment_rate = 1 - solution.unemployment_rate
    solution.job_to_job_rate = fesim_bm_job_to_job_rate(lambda_e, delta)
    solution.equilibrium_profit = ///
        delta * lambda_u / ((delta + lambda_u) * ///
        (delta + lambda_e)) * (p - solution.reservation_wage)
    solution.reservation_residual = fesim_bm_reservation_residual(
        solution.reservation_wage, b, p, lambda_u, lambda_e, delta, ///
        discount, quadrature_intervals)
    solution.reservation_scaled_residual = ///
        abs(solution.reservation_residual) / ///
        max((1, abs(b), abs(p), abs(solution.reservation_wage)))
    grid_scale = (solution.upper_wage - solution.reservation_wage) / ///
        (grid_points - 1)
    solution.support_grid = solution.reservation_wage :+ ///
        (0::(grid_points - 1)) * grid_scale
    solution.support_grid[1] = solution.reservation_wage
    solution.support_grid[grid_points] = solution.upper_wage
    solution.offer_cdf = fesim_bm_offer_cdf(
        solution.support_grid, p, solution.reservation_wage, ///
        lambda_e, delta)
    solution.worker_cdf = fesim_bm_worker_cdf(
        solution.offer_cdf, lambda_e, delta)
    solution.firm_employment = fesim_bm_firm_employment(
        solution.offer_cdf, lambda_u, lambda_e, delta)
    solution.firm_profit = (p :- solution.support_grid) :* ///
        solution.firm_employment
    solution.equal_profit_residual = max(abs(
        solution.firm_profit :- solution.equilibrium_profit))
    solution.equal_profit_scaled_residual = ///
        solution.equal_profit_residual / ///
        max((1, abs(solution.equilibrium_profit)))
    n = rows(solution.support_grid)
    grid_difference = solution.support_grid[|2 \ n|] :- ///
        solution.support_grid[|1 \ (n - 1)|]
    offer_difference = solution.offer_cdf[|2 \ n|] :- ///
        solution.offer_cdf[|1 \ (n - 1)|]
    worker_difference = solution.worker_cdf[|2 \ n|] :- ///
        solution.worker_cdf[|1 \ (n - 1)|]
    solution.monotonicity_violation = max((0, -min(grid_difference), ///
        -min(offer_difference), -min(worker_difference)))
    solution.cdf_violation = max((0, -min(solution.offer_cdf), ///
        max(solution.offer_cdf) - 1, -min(solution.worker_cdf), ///
        max(solution.worker_cdf) - 1, abs(solution.offer_cdf[1]), ///
        abs(solution.offer_cdf[n] - 1), abs(solution.worker_cdf[1]), ///
        abs(solution.worker_cdf[n] - 1)))
    solution.validated = 0
    fesim_bm_solution_validate(solution, tolerance)
    solution.validated = 1
    return(solution)
}

real colvector fesim_bm_inverse_offer_cdf(
    real colvector quantile,
    real scalar p,
    real scalar reservation,
    real scalar lambda_e,
    real scalar delta)
{
    real scalar share

    if (cols(quantile) != 1 | rows(quantile) < 1 | ///
        any(missing(quantile)) | any(quantile :< 0) | ///
        any(quantile :> 1) | missing(p) | missing(reservation) | ///
        missing(lambda_e) | missing(delta) | p <= reservation | ///
        lambda_e <= 0 | delta <= 0) {
        _error(3300, "BM inverse-CDF inputs are invalid")
    }
    share = lambda_e / (delta + lambda_e)
    return(p :- (p - reservation) :* (1 :- share :* quantile):^2)
}

real colvector fesim_bm_expected_mass(
    struct fesim_bm_solution scalar solution,
    real colvector wage)
{
    real scalar firms, i, last, count, lower_mass, higher_count
    real scalar inflow, firm_mass
    real colvector expected_mass

    firms = rows(wage)
    if (solution.validated != 1 | firms < 1 | cols(wage) != 1 | ///
        any(missing(wage)) | any(wage :< solution.reservation_wage) | ///
        any(wage :> solution.upper_wage)) {
        _error(3300, "BM finite wage support is invalid")
    }
    if (firms > 1) {
        if (min(wage[2..firms] :- wage[1..(firms - 1)]) < 0) {
            _error(3300, "BM finite wages must be sorted")
        }
    }
    expected_mass = J(firms, 1, .)
    lower_mass = 0
    i = 1
    while (i <= firms) {
        last = i
        while (last < firms) {
            if (wage[last + 1] != wage[i]) break
            last = last + 1
        }
        count = last - i + 1
        higher_count = firms - last
        inflow = solution.lambda_u * solution.unemployment_rate / firms + ///
            solution.lambda_e * lower_mass / firms
        firm_mass = inflow / (solution.delta + ///
            solution.lambda_e * higher_count / firms)
        expected_mass[i..last] = J(count, 1, firm_mass)
        lower_mass = lower_mass + count * firm_mass
        i = last + 1
    }
    return(expected_mass)
}

real scalar fesim_bm_stationary_residual(
    struct fesim_bm_solution scalar solution,
    real colvector wage,
    real colvector employment_mass)
{
    real scalar i, last, firms, lower_mass, higher_count, inflow
    real scalar residual

    firms = rows(wage)
    if (solution.validated != 1 | firms < 1 | cols(wage) != 1 | ///
        rows(employment_mass) != firms | cols(employment_mass) != 1 | ///
        any(missing(wage)) | any(missing(employment_mass)) | ///
        any(employment_mass :< 0)) {
        _error(3300, "BM finite stationary inputs are invalid")
    }
    if (firms > 1) {
        if (min(wage[2..firms] :- wage[1..(firms - 1)]) < 0) {
            _error(3300, "BM finite stationary wages must be sorted")
        }
    }
    residual = 0
    lower_mass = 0
    i = 1
    while (i <= firms) {
        last = i
        while (last < firms) {
            if (wage[last + 1] != wage[i]) break
            last = last + 1
        }
        higher_count = firms - last
        inflow = solution.lambda_u * solution.unemployment_rate / firms + ///
            solution.lambda_e * lower_mass / firms
        residual = max((residual, max(abs(inflow :- ///
            (solution.delta + solution.lambda_e * higher_count / firms) :* ///
            employment_mass[i..last]))))
        lower_mass = lower_mass + sum(employment_mass[i..last])
        i = last + 1
    }
    return(residual)
}

real scalar fesim_bm_finite_ee_rate(
    struct fesim_bm_solution scalar solution,
    real colvector wage,
    real colvector employment_mass)
{
    real scalar firms, i, last, higher_count, weighted_acceptance

    firms = rows(wage)
    if (solution.validated != 1 | firms < 1 | cols(wage) != 1 | ///
        rows(employment_mass) != firms | cols(employment_mass) != 1 | ///
        any(missing(wage)) | any(missing(employment_mass)) | ///
        any(employment_mass :< 0) | sum(employment_mass) <= 0) {
        _error(3300, "BM finite job-to-job inputs are invalid")
    }
    if (firms > 1) {
        if (min(wage[2..firms] :- wage[1..(firms - 1)]) < 0) {
            _error(3300, "BM finite job-to-job wages must be sorted")
        }
    }
    weighted_acceptance = 0
    i = 1
    while (i <= firms) {
        last = i
        while (last < firms) {
            if (wage[last + 1] != wage[i]) break
            last = last + 1
        }
        higher_count = firms - last
        weighted_acceptance = weighted_acceptance + ///
            sum(employment_mass[i..last]) * higher_count / firms
        i = last + 1
    }
    return(solution.lambda_e * weighted_acceptance / sum(employment_mass))
}

void fesim_bm_firms_validate(
    struct fesim_bm_solution scalar solution,
    struct fesim_bm_firms scalar universe,
    real scalar tolerance)
{
    real scalar firms, stationary_scale
    real colvector id, empirical_right, empirical_left, theoretical_worker
    real colvector wage_difference, size_difference

    firms = universe.firms
    if (solution.validated != 1 | ///
        universe.schema_version != fesim_bm_firms_schema_version() | ///
        universe.status != "constructed" | ///
        (universe.mode != "quantile" & universe.mode != "random") | ///
        missing(firms) | firms < 1 | firms != floor(firms) | ///
        missing(tolerance) | tolerance <= 0 | tolerance > 1e-4 | ///
        any(missing((universe.productivity, ///
            universe.continuum_aggregate_employment, ///
            universe.finite_aggregate_employment, ///
            universe.finite_job_to_job_rate, universe.offer_cdf_error, ///
            universe.worker_cdf_error, ///
            universe.continuum_employment_error, ///
            universe.finite_employment_error, ///
            universe.stationary_residual, universe.wage_ties)))) {
        _error(3300, "BM finite-firm structure is invalid")
    }
    if (rows(universe.firm_id) != firms | ///
        rows(universe.offer_quantile) != firms | ///
        rows(universe.posted_wage) != firms | ///
        rows(universe.firm_productivity) != firms | ///
        rows(universe.continuum_employment) != firms | ///
        rows(universe.continuum_employment_mass) != firms | ///
        rows(universe.continuum_profit) != firms | ///
        rows(universe.expected_employment_mass) != firms | ///
        rows(universe.expected_employment_share) != firms | ///
        rows(universe.finite_scaled_employment) != firms | ///
        rows(universe.finite_scaled_profit) != firms | ///
        rows(universe.finite_worker_cdf) != firms | ///
        cols(universe.firm_id) != 1 | ///
        cols(universe.offer_quantile) != 1 | ///
        cols(universe.posted_wage) != 1 | ///
        cols(universe.firm_productivity) != 1 | ///
        cols(universe.continuum_employment) != 1 | ///
        cols(universe.continuum_employment_mass) != 1 | ///
        cols(universe.continuum_profit) != 1 | ///
        cols(universe.expected_employment_mass) != 1 | ///
        cols(universe.expected_employment_share) != 1 | ///
        cols(universe.finite_scaled_employment) != 1 | ///
        cols(universe.finite_scaled_profit) != 1 | ///
        cols(universe.finite_worker_cdf) != 1 | ///
        any(missing((universe.firm_id, universe.offer_quantile, ///
            universe.posted_wage, universe.firm_productivity, ///
            universe.continuum_employment, ///
            universe.continuum_employment_mass, ///
            universe.continuum_profit, ///
            universe.expected_employment_mass, ///
            universe.expected_employment_share, ///
            universe.finite_scaled_employment, ///
            universe.finite_scaled_profit, universe.finite_worker_cdf)))) {
        _error(3300, "BM finite-firm arrays are invalid")
    }
    id = 1::firms
    if (any(universe.firm_id :!= id) | ///
        universe.productivity != solution.p | ///
        any(universe.firm_productivity :!= solution.p) | ///
        any(universe.offer_quantile :< 0) | ///
        any(universe.offer_quantile :> 1) | ///
        any(universe.posted_wage :< solution.reservation_wage) | ///
        any(universe.posted_wage :> solution.upper_wage) | ///
        any(universe.continuum_employment :<= 0) | ///
        any(universe.continuum_employment_mass :<= 0) | ///
        any(universe.continuum_profit :<= 0) | ///
        any(universe.expected_employment_mass :<= 0) | ///
        any(universe.expected_employment_share :<= 0) | ///
        any(universe.finite_scaled_employment :<= 0) | ///
        any(universe.finite_scaled_profit :<= 0) | ///
        any(universe.finite_worker_cdf :<= 0) | ///
        any(universe.finite_worker_cdf :> 1 + tolerance)) {
        _error(430, "BM finite-firm support or mass validation failed")
    }
    if (firms > 1) {
        wage_difference = universe.posted_wage[2..firms] :- ///
            universe.posted_wage[1..(firms - 1)]
        size_difference = universe.expected_employment_mass[2..firms] :- ///
            universe.expected_employment_mass[1..(firms - 1)]
        if (min(wage_difference) < 0 | min(size_difference) < -tolerance | ///
            universe.minimum_wage_gap != min(wage_difference) | ///
            universe.wage_ties != sum(wage_difference :== 0)) {
            _error(430, "BM finite-firm ordering validation failed")
        }
    }
    else if (!missing(universe.minimum_wage_gap) | universe.wage_ties != 0) {
        _error(430, "BM one-firm diagnostics are invalid")
    }
    if (mreldif(universe.posted_wage, fesim_bm_inverse_offer_cdf(
            universe.offer_quantile, solution.p, ///
            solution.reservation_wage, solution.lambda_e, ///
            solution.delta)) > tolerance | ///
        mreldif(universe.continuum_employment, fesim_bm_firm_employment(
            universe.offer_quantile, solution.lambda_u, ///
            solution.lambda_e, solution.delta)) > tolerance | ///
        mreldif(universe.continuum_employment_mass, ///
            universe.continuum_employment / firms) > tolerance | ///
        mreldif(universe.continuum_profit, ///
            (solution.p :- universe.posted_wage) :* ///
            universe.continuum_employment) > tolerance | ///
        max(abs(universe.continuum_profit :- ///
            solution.equilibrium_profit)) / ///
            max((1, abs(solution.equilibrium_profit))) > tolerance | ///
        mreldif(universe.expected_employment_share, ///
            universe.expected_employment_mass / ///
            universe.finite_aggregate_employment) > tolerance | ///
        mreldif(universe.finite_scaled_employment, ///
            firms :* universe.expected_employment_mass) > tolerance | ///
        mreldif(universe.finite_scaled_profit, ///
            (solution.p :- universe.posted_wage) :* ///
            universe.finite_scaled_employment) > tolerance) {
        _error(430, "BM finite-firm derived quantities are invalid")
    }
    empirical_right = (1::firms) / firms
    empirical_left = (0::(firms - 1)) / firms
    theoretical_worker = fesim_bm_worker_cdf(
        universe.offer_quantile, solution.lambda_e, solution.delta)
    if (abs(universe.offer_cdf_error - max((
            abs(empirical_right :- universe.offer_quantile)', ///
            abs(empirical_left :- universe.offer_quantile)'))) > tolerance | ///
        abs(universe.worker_cdf_error - ///
            max(abs(universe.finite_worker_cdf :- theoretical_worker))) > ///
            tolerance | ///
        abs(universe.continuum_aggregate_employment - ///
            mean(universe.continuum_employment)) > tolerance | ///
        abs(universe.finite_aggregate_employment - ///
            sum(universe.expected_employment_mass)) > tolerance | ///
        abs(universe.continuum_employment_error - ///
            (universe.continuum_aggregate_employment - ///
            solution.employment_rate)) > tolerance | ///
        abs(universe.finite_employment_error - ///
            (universe.finite_aggregate_employment - ///
            solution.employment_rate)) > tolerance) {
        _error(430, "BM finite-firm approximation diagnostics are invalid")
    }
    stationary_scale = max((1, solution.lambda_u, solution.lambda_e, ///
        solution.delta))
    if (abs(universe.finite_aggregate_employment - ///
            solution.employment_rate) > tolerance | ///
        abs(universe.finite_worker_cdf[firms] - 1) > tolerance | ///
        universe.stationary_residual / stationary_scale > tolerance | ///
        abs(universe.stationary_residual - ///
            fesim_bm_stationary_residual(solution, ///
            universe.posted_wage, ///
            universe.expected_employment_mass)) > tolerance | ///
        abs(universe.finite_job_to_job_rate - ///
            fesim_bm_finite_ee_rate(solution, universe.posted_wage, ///
            universe.expected_employment_mass)) > tolerance | ///
        universe.finite_job_to_job_rate < 0 | ///
        universe.finite_job_to_job_rate >= solution.lambda_e) {
        _error(430, "BM finite-firm stationary validation failed")
    }
}

struct fesim_bm_firms scalar fesim_bm_construct_firms(
    struct fesim_bm_solution scalar solution,
    real scalar firms,
    string scalar mode,
    struct fesim_rng_state scalar rng_state,
    real scalar tolerance)
{
    struct fesim_bm_firms scalar universe
    real scalar i, last
    real colvector draw_order, original_order, wage_difference

    mode = strlower(strtrim(mode))
    if (solution.validated != 1 | missing(firms) | firms < 1 | ///
        firms != floor(firms) | firms > 1000000 | ///
        (mode != "quantile" & mode != "random") | ///
        missing(tolerance) | tolerance <= 0 | tolerance > 1e-4 | ///
        rng_state.schema_version != fesim_rng_schema_version()) {
        _error(3300, "BM finite-firm controls are invalid")
    }
    universe.schema_version = fesim_bm_firms_schema_version()
    universe.status = "constructed"
    universe.mode = mode
    universe.firms = firms
    universe.productivity = solution.p
    if (mode == "quantile") {
        universe.offer_quantile = ((1::firms) :- .5) / firms
    }
    else {
        universe.offer_quantile = fesim_rng_runiform(
            rng_state, "firm_primitives", firms, 1)
        original_order = 1::firms
        draw_order = order((universe.offer_quantile, original_order), (1, 2))
        universe.offer_quantile = universe.offer_quantile[draw_order]
    }
    universe.firm_id = 1::firms
    universe.posted_wage = fesim_bm_inverse_offer_cdf(
        universe.offer_quantile, solution.p, ///
        solution.reservation_wage, solution.lambda_e, solution.delta)
    universe.firm_productivity = J(firms, 1, solution.p)
    universe.continuum_employment = fesim_bm_firm_employment(
        universe.offer_quantile, solution.lambda_u, ///
        solution.lambda_e, solution.delta)
    universe.continuum_employment_mass = ///
        universe.continuum_employment / firms
    universe.continuum_profit = ///
        (solution.p :- universe.posted_wage) :* ///
        universe.continuum_employment

    universe.expected_employment_mass = fesim_bm_expected_mass(
        solution, universe.posted_wage)
    universe.finite_aggregate_employment = ///
        sum(universe.expected_employment_mass)
    universe.expected_employment_share = ///
        universe.expected_employment_mass / ///
        universe.finite_aggregate_employment
    universe.finite_scaled_employment = ///
        firms :* universe.expected_employment_mass
    universe.finite_scaled_profit = ///
        (solution.p :- universe.posted_wage) :* ///
        universe.finite_scaled_employment
    universe.finite_worker_cdf = runningsum(
        universe.expected_employment_mass) / ///
        universe.finite_aggregate_employment
    i = 1
    while (i <= firms) {
        last = i
        while (last < firms) {
            if (universe.posted_wage[last + 1] != ///
                universe.posted_wage[i]) break
            last = last + 1
        }
        universe.finite_worker_cdf[i..last] = ///
            universe.finite_worker_cdf[last]
        i = last + 1
    }
    universe.finite_job_to_job_rate = fesim_bm_finite_ee_rate(
        solution, universe.posted_wage, universe.expected_employment_mass)
    universe.continuum_aggregate_employment = ///
        mean(universe.continuum_employment)
    universe.offer_cdf_error = max((
        abs((1::firms) / firms :- universe.offer_quantile)', ///
        abs((0::(firms - 1)) / firms :- universe.offer_quantile)'))
    universe.worker_cdf_error = max(abs(
        universe.finite_worker_cdf :- fesim_bm_worker_cdf(
        universe.offer_quantile, solution.lambda_e, solution.delta)))
    universe.continuum_employment_error = ///
        universe.continuum_aggregate_employment - solution.employment_rate
    universe.finite_employment_error = ///
        universe.finite_aggregate_employment - solution.employment_rate
    universe.stationary_residual = fesim_bm_stationary_residual(
        solution, universe.posted_wage, universe.expected_employment_mass)
    if (firms > 1) {
        wage_difference = universe.posted_wage[2..firms] :- ///
            universe.posted_wage[1..(firms - 1)]
        universe.minimum_wage_gap = min(wage_difference)
        universe.wage_ties = sum(wage_difference :== 0)
    }
    else {
        universe.minimum_wage_gap = .
        universe.wage_ties = 0
    }
    universe.validated = 0
    fesim_bm_firms_validate(solution, universe, tolerance)
    universe.validated = 1
    return(universe)
}

end
