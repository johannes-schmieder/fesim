version 16.0

mata:

real scalar fesim_bm_schema_version()
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
    return(delta :* offer_cdf :/ ///
        (delta :+ lambda_e :* (1 :- offer_cdf)))
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
        _error(430, "BM analytical solution failed validation")
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
        _error(430, "BM analytical solution failed validation")
    }
    if (any(solution.firm_employment :<= 0) | ///
        any(solution.firm_profit :<= 0) | ///
        max(abs(solution.firm_profit :- ///
            (solution.p :- solution.support_grid) :* ///
            solution.firm_employment)) > tolerance | ///
        max(abs(solution.firm_profit :- ///
            solution.equilibrium_profit)) / ///
            max((1, abs(solution.equilibrium_profit))) > tolerance) {
        _error(430, "BM analytical solution failed validation")
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
        _error(430, "BM analytical solution failed validation")
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
        _error(430, "BM analytical solution failed validation")
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

end
