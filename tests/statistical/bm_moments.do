version 16.0
clear all
set more off
set varabbrev off
set rng mt64
set seed 24680
local rng_before `"`c(rngstate)'"'

mata:
// Independent workers, not correlated worker-period rows, are the sampling units.
void fesim_test_bm_cluster_bound(real colvector residual)
{
    real scalar se
    se = sqrt(variance(residual) / rows(residual))
    assert(abs(mean(residual)) <= 8 * se + 1e-10)
}

real rowvector fesim_test_bm_moments(
    real rowvector primitives, real scalar workers, real scalar firms,
    real scalar seed, string scalar mode)
{
    struct fesim_bm_solution scalar s
    struct fesim_bm_firms scalar f
    struct fesim_bm_state scalar initial
    struct fesim_bm_history scalar h
    struct fesim_bm_panel scalar p
    struct fesim_rng_state scalar rng
    real scalar j, k, row, worker, q, bound, cdf_error
    real scalar emp, count, horizon
    real colvector masses, empirical, exposure_e, exposure_u
    real colvector ue, eu, ee, offers_e, offers_u, rejection
    real colvector offered_low, entry_low, expected_acceptance

    horizon = 5
    s = fesim_bm_solve(primitives[1], primitives[2], primitives[3],
        primitives[4], primitives[5], primitives[6], 1001, 4000, 1e-10)
    rng = fesim_rng_init(seed, 1)
    f = fesim_bm_construct_firms(s, firms, mode, rng, 1e-10)
    initial = fesim_bm_initialize_state(s, f, workers, "stationary", rng, 1e-10)
    h = fesim_bm_simulate_events(s, f, initial.employed, initial.firm_id,
        initial.spell_id, initial.tenure, initial.unemployment_duration,
        horizon, 1, 10000000, rng, 1e-10)
    p = fesim_bm_aggregate_history(s, f, h, "year", horizon, 1e-10)
    masses = (s.unemployment_rate \ f.expected_employment_mass)
    empirical = J(firms + 1, 1, 0)
    for (worker = 1; worker <= workers; worker++) {
        j = h.final_firm_id[worker] + 1
        empirical[j] = empirical[j] + 1 / workers
    }
    // DKW simultaneous bound for the entire finite joint unemployment/wage CDF.
    // alpha=1e-10 per scenario, independent of the number of firms.
    bound = sqrt(ln(2 / 1e-10) / (2 * workers))
    cdf_error = max(abs(runningsum(empirical) - runningsum(masses)))
    assert(cdf_error < bound)
    assert(abs(empirical[1] - s.unemployment_rate) <
        8 * sqrt(s.unemployment_rate * s.employment_rate / workers))
    assert(min(f.posted_wage) >= s.reservation_wage)
    assert(max(f.posted_wage) <= s.upper_wage)
    assert(s.equal_profit_scaled_residual < 1e-10)
    assert(f.stationary_residual < 1e-10)
    if (firms > 1) {
        assert(min(f.expected_employment_mass[2..firms] -
            f.expected_employment_mass[1..(firms - 1)]) >= -1e-12)
    }
    // Employed stock CDF G is different from the UE-entry/offer CDF F.
    emp = 1 - empirical[1]
    assert(emp > 0)
    assert(max(abs(runningsum(empirical[2..(firms + 1)]) / emp -
        f.finite_worker_cdf)) < 2 * bound / emp)

    exposure_e = rowsum(rowshape(p.employment_exposure, workers))
    exposure_u = rowsum(rowshape(p.unemployment_exposure, workers))
    ue = rowsum(rowshape(p.n_ue, workers))
    eu = rowsum(rowshape(p.n_eu, workers))
    ee = rowsum(rowshape(p.n_ee, workers))
    offers_e = rowsum(rowshape(p.n_employed_offers, workers))
    offers_u = rowsum(rowshape(p.n_unemployment_offers, workers))
    rejection = rowsum(rowshape(p.n_rejected_offers, workers))
    fesim_test_bm_cluster_bound(exposure_u :- horizon * s.unemployment_rate)
    fesim_test_bm_cluster_bound(ue - s.lambda_u * exposure_u)
    fesim_test_bm_cluster_bound(eu - s.delta * exposure_e)
    fesim_test_bm_cluster_bound(offers_e - s.lambda_e * exposure_e)
    fesim_test_bm_cluster_bound(ee - f.finite_job_to_job_rate * exposure_e)
    assert(offers_u == ue)
    assert(offers_e == ee + rejection)

    // Contact/acceptance checks use the actual pre-offer firm and strict ties.
    // Cluster all offers from one worker to allow arbitrary within-worker dependence.
    expected_acceptance = J(workers, 1, 0)
    for (row = 1; row <= h.total_events; row++) {
        if (h.events[row, 3] != 2) continue
        worker = h.events[row, 1]
        j = h.events[row, 5]
        expected_acceptance[worker] = expected_acceptance[worker] +
            mean(f.posted_wage :> f.posted_wage[j])
    }
    fesim_test_bm_cluster_bound(ee - expected_acceptance)
    for (k = 1; k <= 3; k++) {
        j = max((1, floor(firms * k / 4)))
        q = mean(f.posted_wage :<= f.posted_wage[j])
        offered_low = J(workers, 1, 0)
        entry_low = J(workers, 1, 0)
        for (row = 1; row <= h.total_events; row++) {
            if (h.events[row, 3] == 3) continue
            worker = h.events[row, 1]
            count = f.posted_wage[h.events[row, 6]] <= f.posted_wage[j]
            offered_low[worker] = offered_low[worker] + count
            if (h.events[row, 3] == 1) entry_low[worker] =
                entry_low[worker] + count
        }
        fesim_test_bm_cluster_bound(offered_low - q * (offers_e + offers_u))
        fesim_test_bm_cluster_bound(entry_low - q * ue)
    }
    printf("BM moments: N=%g J=%g seed=%g mode=%s CDF error=%g bound=%g\n",
        workers, firms, seed, mode, cdf_error, bound)
    return((cdf_error, bound))
}

void fesim_test_bm_validate_all()
{
    struct fesim_bm_solution scalar s, limit
    struct fesim_bm_firms scalar f
    struct fesim_rng_state scalar rng
    real scalar seed, j, previous_offer, previous_worker, previous_ee
    real rowvector small, large

    for (seed = 1; seed <= 3; seed++) {
        small = fesim_test_bm_moments((.4, 1, 1, .5, .2, .05),
            2000, 40, 12000 + seed, "quantile")
        large = fesim_test_bm_moments((.4, 1, 1, .5, .2, .05),
            32000, 40, 12000 + seed, "quantile")
        assert(abs(small[2] / large[2] - 4) < 1e-12)
    }
    (void) fesim_test_bm_moments((.4, 1, .5, .5, .2, .05),
        16000, 100, 97531, "random")
    (void) fesim_test_bm_moments((1.2, 2, .2, .8, .5, .04),
        16000, 50, 24680, "quantile")
    (void) fesim_test_bm_moments((.4, 1, 1, .5, .2, .05),
        8000, 1, 86420, "quantile")

    s = fesim_bm_solve(.4, 1, 1, .5, .2, .05, 1001, 4000, 1e-10)
    rng = fesim_rng_init(13579, 1)
    previous_offer = previous_worker = previous_ee = 1
    for (j = 10; j <= 10000; j = j * 10) {
        f = fesim_bm_construct_firms(s, j, "quantile", rng, 1e-10)
        assert(abs(f.offer_cdf_error - .5 / j) < 1e-12)
        assert(f.offer_cdf_error < previous_offer)
        assert(f.worker_cdf_error < previous_worker)
        assert(abs(f.finite_job_to_job_rate - s.job_to_job_rate) < previous_ee)
        previous_offer = f.offer_cdf_error
        previous_worker = f.worker_cdf_error
        previous_ee = abs(f.finite_job_to_job_rate - s.job_to_job_rate)
    }
    limit = fesim_bm_solve(.4, 1, 1, 1e-7, .2, .05, 401, 4000, 1e-9)
    assert(abs(limit.reservation_wage - .4) < 2e-6)
    assert(limit.upper_wage - limit.reservation_wage < 1e-6)
    assert(abs(limit.job_to_job_rate / 1e-7 - .5) < 1e-6)
    limit = fesim_bm_solve(.4, 1, .5, .5, .2, 1e-7, 401, 4000, 1e-9)
    assert(limit.reservation_wage == .4)
    assert(abs(limit.unemployment_rate - .2 / .7) < 1e-14)
    limit = fesim_bm_solve(.4, 1, .5, .5, 1e-5, .05, 401, 4000, 1e-8)
    assert(limit.unemployment_rate < 2e-5)
    assert(abs(limit.upper_wage - 1) < 1e-8)
}

fesim_test_bm_validate_all()
end
assert `"`c(rngstate)'"' == `"`rng_before'"'
di as result "FESIM BM THEORETICAL MOMENTS TESTS PASS"
