version 16.0
clear all
set more off

* Exact canonical homogeneous BM model, with a stylized calibration.
* All four rates are annual continuous-time rates; b and p are levels.
fesim, dgp(bm) workers(2000) firms(100) periods(5) seed(12345) ///
    truth(full) parameters(b .4 p 1 lambda_u 1 lambda_e .5 delta .2 r .05) clear
matrix list r(solver)
matrix list r(bm_flows)
matrix list r(bm_firms)

* Event hazards and observed endpoint probabilities are different objects.
* For monthly snapshots over the same five-year horizon, use
* frequency(month) periods(60). Keep the same seed for the same history.
* Stationary masses are exact for the finite firms; continuum errors are
* reported separately. Basic truth contains wages and productivity, no AKM effects.
