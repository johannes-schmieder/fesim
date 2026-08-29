# Regression tests

`akm_tiny.do` freezes exact annual, quarterly, and monthly public simple-AKM
panels by Stata data signature and selected returned results. It checks
same-session repetition, cleared-state reruns, two clean-process executions,
and canonical/alias equality.

The fixtures are tied to the package source and qualified Stata/RNG/platform
scope recorded in `docs/regression.md` and `PLAN.md`; they are not a claim of
cross-version or cross-platform bitwise identity.
