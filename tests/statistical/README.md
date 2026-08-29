# Statistical tests

`akm_moments.do` qualifies primitive effect and residual moments, conditional
EU/UE/EE rates, stationary initial employment, uniform initial firm
assignment, and fixed-seed convergence. `akm_exogeneity.do` checks zero
worker-firm sorting and independence of wage shocks from mobility events.

Every tolerance uses a declared effective sample size and an analytically
justified conservative standard-error bound. Exact formulas, estimands, and
the false-failure policy are documented in `docs/statistical_tests.md`.
