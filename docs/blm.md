# BLM-style finite-type simulation

This note and the [public interface contract](interface.md) specify the model
and its source interpretation. The LaTeX manual provides runnable examples.

`fesim, dgp(blm) preset(static)` generates an employed-only monthly process with
permanent worker types and firm classes. Static earnings are conditionally
independent normal draws given the current type/class. `preset(dynamic)` permits
first-order persistence, mobility depending on current earnings, and origin-
class move shifts. Both are flexible forward long-panel specifications. They do
not implement the BLM estimator or reproduce a Swedish empirical calibration.

See the installed help for every scalar and matrix input, full truth, returned
tables, provenance and numerical limits. Annual rho converts to monthly
rho^(1/12). The random initializer and finite burn-in are not claimed stationary.

## Version-specific source audit

The published reference is Bonhomme, Stéphane, Thibaut Lamadon and Elena Manresa
(2019), “A Distributional Framework for Matched Employer Employee Data”,
Econometrica 87(3), 699–739, [doi:10.3982/ECTA15722](https://doi.org/10.3982/ECTA15722).
The current audit uses the [IFAU 2017 working paper](https://www.ifau.se/globalassets/pdf/se/2017/wp2017-24-a-distributional-framework-for-matched-employer-employee-data.pdf),
the [author supplement](https://lamadon.com/paper/blm_supp.pdf), and author code
at [blm-replicate commit 8d65ada](https://github.com/tlamadon/blm-replicate/tree/8d65ada76c15c2b8ae2cbfa291813fa8bc6d0393).
The published main PDF has not been verified; source-version equivalence is not
assumed. The author-page main-PDF link was unavailable during the bounded audit.

The working paper's Assumption 2 (PDF pages 10–11, printed pages 8–9) allows
next mobility to depend on current earnings, permanent worker type and current
firm class, and next earnings to depend on the current earnings/type and the
origin/destination classes and move indicator. The implemented model imposes those forward
restrictions on every internal month. The static specialization removes serial
persistence and earnings-dependent mobility. Gaussian cell distributions, the
scalar score recipes, monthly event probabilities and the 20-year burn-in are
package choices. They are not reported empirical estimates from BLM.

Author files R/m2-mixt.r and R/m4-mixt.R generate conditional two- and four-period
stayer/mover samples. Their worker-type probabilities may depend on an observed
origin/destination pair. In this package the primitive worker distribution and
forward transition process jointly imply such conditional mixtures. The full
parameter space of those conditional sample simulators is not asserted to define
an arbitrary-length forward model. Registered tests check independent static
normal endpoints and a compatible stationary Gaussian four-period AR(1) law,
including the reverse construction of the first wage from the second in m4.

Mixture identification requires conditions on type distributions, informative
mobility, independence/Markov restrictions and suitable rank/support. Distinct
class IDs in simulated truth do not guarantee distinguishable distributions:
identical rows/columns or zero mobility may fail empirical identification.
The existing graph and leave-out diagnostics concern observed AKM-style graphs;
they do not certify BLM mixture identification.


## Acquisition and claim map (2026-09-06)

Sources are cached outside the installed package in ignored
`literature/downloads/blm/`. PDF page renders were checked against the extracted
text. No Swedish data, fitted parameters or author runtime code is packaged.

| Cached source | SHA-256 |
| --- | --- |
| IFAU 2017:24, 113 PDF pages | `4a1e79555e9470a720cf3895d50a641b4e425146843d2fbd8853364b9dddefb5` |
| Author supplement, 28 PDF pages | `beb9c18b02a86e8752d6e23b83819c0d99b38244dd1470e9ec1f1be8a9a18d03` |
| Pinned `R/m2-mixt.r` | `e6bb74f2bcc65d6676984ec270ea1cb477b06edd15f7ef0c5c02f508f57c2c30` |
| Pinned `R/m4-mixt.R` | `5b6e30edb26a93ba1c9fc18cc558d08638328a84c40b8277cd5763484e62ff4a` |

| Claim | Exact evidence | Package interpretation |
| --- | --- | --- |
| Static restrictions | IFAU PDF p.10 / printed p.8, Assumption 1 and Eq. (1) | Mobility ignores wage history conditional on type/class. Our independent monthly Gaussian draws also impose stayer independence, a stronger restriction. |
| Dynamic restrictions | IFAU PDF pp.10–11 / printed pp.8–9, Assumption 2(i)–(ii), Eq. (2) | First-order monthly state: lagged earnings/type/origin class determine moves; next earnings also use destination and actual move. |
| Conditional bootstrap differs from a forward economy | Supplement PDF/printed pp.3–4, S1.3 | Author simulation conditions on class assignments and mobility links; fesim generates links endogenously. |
| Dynamic backward first wage | Supplement PDF/printed p.3, S1.2; m4 lines 332–386 | Full author mover map includes origin and destination shifts. The first wage is generated backward from the second. |
| Static author fixture | m2 lines 52–87, 93–127 | Independent Gaussian endpoints conditional on type/link; transpose firm-by-worker arrays to fesim worker-by-class tables. |
| Compatible dynamic fixture | m4 lines 332–386 | Choose constant location/scale, no cross-class shifts and common AR coefficient; covariance is sigma^2 phi^abs(t-u). This is a compatible submodel, not full parameter-space equivalence. |
| Graphs and identification differ | Supplement PDF/printed p.2, Graph connectedness | Source uses type-specific class graphs and informative linking cycles; generic observed AKM firm-graph diagnostics are not a mixture-identification certificate. |

Pinned source links:
[m2 lines 52–127](https://github.com/tlamadon/blm-replicate/blob/8d65ada76c15c2b8ae2cbfa291813fa8bc6d0393/R/m2-mixt.r#L52-L127),
[m4 lines 332–386](https://github.com/tlamadon/blm-replicate/blob/8d65ada76c15c2b8ae2cbfa291813fa8bc6d0393/R/m4-mixt.R#L332-L386).
In m4, the backward Y1 residual is centered at A2ma alone, and Y4 at A3ma
alone; the respective A2mb/A3mb terms are not subtracted there. The compatible
fixture sets those terms to zero and checks the full four-normal covariance law.

## Implementation map

- `_fesim_blm_registry.ado`: scalar defaults, typed matrix keys and bounds.
- `_fesim_blm_config.ado`: dimensions, explicit recipe conflicts, preflight and provenance.
- `src/fesim_blm.mata`: actual-firm allocation, normalized scores, resolved
  matrices, eligible destinations, stable move probability, deterministic wage map.
- `src/fesim_blm_simulate.mata`: fixed-stream worker-major monthly histories,
  bounded output blocks, cell moments and complete serialized characteristics.
- `_fesim_blm.ado`: transactional public run, common graphs/durations/moments,
  generated-versus-returned summaries and caller-state rollback.
- `tests/unit/test_blm_model.do` and `test_blm_author_fixtures.do`: independent
  probability grids, deterministic earnings and compatible author-model laws.
- `tests/statistical/test_blm_moments.do`: heterogeneous innovation moments,
  endogenous move-probability calibration, signed sorting and static exogeneity.
- `tests/integration/test_blm_public.do` and `test_blm_invariance.do`: full
  matrix surface, numerical/input rollback, truth/frequency/block nesting and
  full-value metadata across the 20-by-20 maximum grid.

The LaTeX appendix gives the full equations, timing, normalization, initialization,
resource guards and truth/result conventions. The scalar presets are stylized;
identical latent cell distributions and zero mobility remain valid simulations
but may fail empirical identification.
