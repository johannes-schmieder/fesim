version 19.0
clear all
set more off
set varabbrev off

* Generate a connected, balanced worker panel with row-level truth.
fesim, dgp(akmsimple) workers(500) firms(40) periods(6) ///
    seed(12345) truth(basic) connectivity(largest) clear

matrix simulation_parameters = r(parameters)
matrix simulation_moments = r(moments)
matrix simulation_targets = r(targets)
matrix simulation_network = r(network)

describe workerid time firmid employed lnwage alpha_true psi_true epsilon_true
summarize employed lnwage alpha_true psi_true epsilon_true
matrix list simulation_network

* Built-in AKM-style estimator demonstration; no user-written command required.
* Firm effects are absorbed, while worker and time effects enter as indicators.
quietly areg lnwage i.workerid i.time if employed, absorb(firmid) ///
    vce(cluster workerid)
estimates store akm_demo
di as result "AKM-style estimation sample: " e(N) " employed observations"

* Compare the simulator's declared component targets with realized truth moments.
matrix list simulation_targets

di as result "fesim akmsimple example completed"
