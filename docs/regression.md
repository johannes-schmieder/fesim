# Deterministic regression fixtures

`tests/regression/akm_tiny.do` freezes complete 24-observation public panels for annual, quarterly, and monthly output. Every fixture uses six workers, three firms, four retained periods, stationary initialization, seed 314159, basic truth, and `connectivity(keep)`. Frequency-appropriate start values and time formats are asserted.

Each panel is protected by a Stata `datasignature`, full-variable `cf` comparisons, selected exact moment and network values, and exact equality of the complete moment, target, and network matrices across repeated calls. The test then clears Stata data, programs, and Mata state, reruns the canonical invocation, and compares it with the frozen signature and panel. Finally it proves the `akmsimple` alias generates the same economic data.

The fixture values are intentionally tied to the current exact-source qualification ledger in `PLAN.md`. They are not cross-version golden files: the package promises deterministic repetition only within a qualified Stata/RNG/platform scope. A scientifically intended change to RNG consumption, timing, mobility, wages, output types, or truth columns must update the fixtures and explain the change in `DESIGN.md` and `PLAN.md`; tests must not be loosened merely to accept new output.

Reporting invariance, truth suppression on common columns, and failure rollback remain covered by `tests/integration/test_akm_public.do`. Together these tests close the deterministic P2.10 contract without committing generated `.dta` files.
