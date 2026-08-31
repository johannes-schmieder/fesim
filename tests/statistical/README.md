# Statistical tests

`akm_moments.do` qualifies primitive effect and residual moments, conditional
EU/UE/EE rates, stationary initial employment, uniform initial firm
assignment, and fixed-seed convergence. `akm_exogeneity.do` checks zero
worker-firm sorting and independence of wage shocks from mobility events.
`akm_stylized_mobility.do` checks the sign and material size of public sorting,
latent primitive correlations, and duration dependence while holding competing
mechanisms fixed.

`paygap_limits.do` checks the public all-equal limiting case and convergence of
group-specific transition rates. `paygap_cck_moments.do` validates the
CCK-inspired preset's group and male-reference decomposition targets in a
fixed 100,000-worker simulation using predeclared finite-sample tolerances.

The simple-AKM stochastic tolerances use declared effective sample sizes and
conservative analytical bounds. The stylized-route thresholds are documented
fixed-seed mechanism contrasts rather than sampling-theory or calibration
bounds. Exact estimands and the false-failure policy are in
`docs/statistical_tests.md`.
