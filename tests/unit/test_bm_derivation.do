version 16.0
clear all
set more off
set varabbrev off

mata:
real scalar _fesim_test_bm_surplus(
    real scalar p,
    real scalar reservation,
    real scalar lambda_e,
    real scalar delta,
    real scalar discount,
    real scalar intervals)
{
    real scalar upper, step, i
    real colvector wage, offer_cdf, tail, weight

    upper = p - (p - reservation) * (delta / (delta + lambda_e))^2
    step = (upper - reservation) / intervals
    wage = reservation :+ (0::intervals) * step
    offer_cdf = (delta + lambda_e) / lambda_e :* ///
        (1 :- sqrt((p :- wage) / (p - reservation)))
    tail = (1 :- offer_cdf) :/ ///
        (discount + delta :+ lambda_e :* (1 :- offer_cdf))
    weight = J(intervals + 1, 1, 2)
    weight[1] = 1
    weight[intervals + 1] = 1
    for (i = 2; i <= intervals; i++) {
        if (mod(i, 2) == 0) weight[i] = 4
    }
    return(step / 3 * sum(weight :* tail))
}

real scalar _fesim_test_bm_residual(
    real scalar reservation,
    real scalar p,
    real scalar b,
    real scalar lambda_u,
    real scalar lambda_e,
    real scalar delta,
    real scalar discount)
{
    return(reservation - b - (lambda_u - lambda_e) * ///
        _fesim_test_bm_surplus(
            p, reservation, lambda_e, delta, discount, 4000))
}

p = 1
b = .4
lambda_u = 1
lambda_e = .5
delta = .2
discount = .05
a = discount + delta
j = .5 - discount / lambda_e + ///
    discount * a / lambda_e^2 * ln(1 + lambda_e / a)
c = 2 * lambda_e / (delta + lambda_e)^2 * j
reservation = (b + (lambda_u - lambda_e) * c * p) / ///
    (1 + (lambda_u - lambda_e) * c)
upper = p - (p - reservation) * (delta / (delta + lambda_e))^2
unemployment = delta / (delta + lambda_u)

assert(abs(c - .928429825374297) < 5e-15)
assert(abs(reservation - .590224088826639) < 5e-15)
assert(abs(upper - .966548905210338) < 5e-15)
assert(abs(unemployment - .166666666666667) < 5e-15)

quantile = (0, .25, .5, .75, 1)'
wage = p :- (p - reservation) :* ///
    (1 :- lambda_e / (delta + lambda_e) :* quantile):^2
offer_cdf = (delta + lambda_e) / lambda_e :* ///
    (1 :- sqrt((p :- wage) / (p - reservation)))
worker_cdf = delta :* offer_cdf :/ ///
    (delta :+ lambda_e :* (1 :- offer_cdf))
employment = delta * lambda_u * (delta + lambda_e) :/ ///
    ((delta + lambda_u) :* ///
    (delta :+ lambda_e :* (1 :- offer_cdf)):^2)
profit = (p :- wage) :* employment

assert(max(abs(offer_cdf - quantile)) < 2e-15)
assert(max(abs(worker_cdf - ///
    (0, .0869565217391304, .222222222222222, ///
    .461538461538462, 1)')) < 5e-15)
assert(max(abs(employment - ///
    (.238095238095238, .352867044738500, .576131687242798, ///
    1.10453648915187, 2.91666666666667)')) < 5e-14)
assert(max(abs(profit :- profit[1])) < 5e-15)
assert(abs(profit[1] - .0975656931365146) < 5e-15)

surplus = _fesim_test_bm_surplus(
    p, reservation, lambda_e, delta, discount, 100000)
assert(abs(surplus - .380448177653277) < 5e-13)
assert(abs(reservation - b - (lambda_u - lambda_e) * surplus) < 5e-13)

low = b
high = p - 1e-10
assert(_fesim_test_bm_residual(
    low, p, b, lambda_u, lambda_e, delta, discount) < 0)
assert(_fesim_test_bm_residual(
    high, p, b, lambda_u, lambda_e, delta, discount) > 0)
for (iteration = 1; iteration <= 60; iteration++) {
    middle = (low + high) / 2
    if (_fesim_test_bm_residual(
        middle, p, b, lambda_u, lambda_e, delta, discount) > 0) {
        high = middle
    }
    else low = middle
}
numeric_reservation = (low + high) / 2
assert(abs(numeric_reservation - reservation) < 2e-12)

equal_lambda = .5
equal_c = 2 * equal_lambda / (delta + equal_lambda)^2 * ///
    (.5 - discount / equal_lambda + ///
    discount * (discount + delta) / equal_lambda^2 * ///
    ln(1 + equal_lambda / (discount + delta)))
equal_reservation = ///
    (b + (equal_lambda - equal_lambda) * equal_c * p) / ///
    (1 + (equal_lambda - equal_lambda) * equal_c)
assert(equal_reservation == b)

aggregate_ee = delta * (delta + lambda_e) / lambda_e * ///
    ln(1 + lambda_e / delta) - delta
dense_offer_cdf = (0::100000) / 100000
dense_wage = p :- (p - reservation) :* ///
    (1 :- lambda_e / (delta + lambda_e) :* dense_offer_cdf):^2
dense_worker_cdf = delta :* dense_offer_cdf :/ ///
    (delta :+ lambda_e :* (1 :- dense_offer_cdf))
dense_employment = delta * lambda_u * (delta + lambda_e) :/ ///
    ((delta + lambda_u) :* ///
    (delta :+ lambda_e :* (1 :- dense_offer_cdf)):^2)
assert(min(dense_wage[|2 \ 100001|] :- ///
    dense_wage[|1 \ 100000|]) > 0)
assert(min(dense_worker_cdf[|2 \ 100001|] :- ///
    dense_worker_cdf[|1 \ 100000|]) > 0)
numeric_employment = sum((dense_employment[|1 \ 100000|] :+ ///
    dense_employment[|2 \ 100001|]) / 2) / 100000
assert(abs(numeric_employment - (1 - unemployment)) < 2e-10)
dense_tail_mid = 1 :- ///
    (dense_offer_cdf[|1 \ 100000|] :+ ///
    dense_offer_cdf[|2 \ 100001|]) / 2
numeric_ee = lambda_e * sum(dense_tail_mid :* ///
    (dense_worker_cdf[|2 \ 100001|] :- ///
    dense_worker_cdf[|1 \ 100000|]))
assert(abs(numeric_ee - aggregate_ee) < 1e-10)
end

di as result "FESIM BM DERIVATION TESTS PASS"
