# Changelog

## Unreleased source maintenance — 2026-09-30

- Reorganize the README and Stata help around installation, model choice,
  runnable examples, interpretation, and troubleshooting.
- Bring compatibility, architecture, references, and preset inventories into
  agreement with the ten-preset 1.2.0-rc.1 source.
- Replace obsolete planning/checkpoint/review documents with maintained
  interface, validation, and contribution guides. Retain scientific derivations,
  calibration provenance, independent tests, the illustrated manual, and examples.
- Keep GitHub CI on hosted static checks and document local licensed testing.
  Runtime, model defaults, public/Mata APIs, and seeded algorithms are unchanged.

## 1.2.0-rc.1 — development candidate, untagged

- Add static and dynamic BLM-style finite-type long panels with nonlinear
  cell earnings, worker sorting, persistence, and wage-dependent monthly mobility.
- Add nine optional Stata matrix inputs, complete resolved-model serialization,
  employed-only type/cell truth, monthly lags, and generated/returned summaries.
- Add independent probability/Gaussian fixtures, statistical checks, matrix and
  caller-state tests, five clickable examples, and four manual figure scripts.
- Preserve all earlier economic algorithms/defaults and matched deterministic
  controls. Public API remains 1; Mata API is 37.
- Current qualification is macOS Apple Silicon Stata/MP 19. BLM parameters are
  illustrative; no Swedish calibration, estimator, or broader-platform claim.

## 1.1.0-rc.1 — earlier development candidate, untagged

- Add finite-firm CPV sequential bargaining, incumbent raises, wage-cutting moves,
  and optional multiplicative worker ability.
- Add exact joint stationary contract/tenure starts, continuous events and burn-in,
  structural truth, finite firm diagnostics, and theoretical/event/observed flows.
- Add independent Bellman and CTMC checks, stationarity, numerical range/rollback,
  beta/tie limits, caller-state and block/frequency invariance tests, and examples.
- Public API remains 1; Mata API advanced to 36. Qualification was macOS MP 19.

## 1.0.0-rc.1 — earlier development candidate, untagged

- Complete discovery output inventories, parameter units/bounds, initialization
  and network support, source/target scope, calibration and compatibility guides.
- Add cross-model truth/frequency/state/override tests, source archive qualification,
  receipt inventory verification, matched performance controls, and the user manual.
- Preserve economic defaults and algorithms; qualification was macOS MP 19.

## Earlier 0.2–0.4 development

- Add monthly AKM mobility with correlated latent indices, duration-dependent
  hazards, destination sorting, year-valued duration diagnostics, and an explicitly
  uncalibrated stylized preset.
- Add a CHK-targeted preset for selected West German wage-component dispersion
  and worker–firm covariance, with disjoint calibration and validation seeds.
- Add block, exact imposed-bridge, and reduced-form ladder network experiments;
  distinguish descriptive firm graphs from bipartite leave-out diagnostics.
- Add conservative fixed-point worker-history pruning and complete-match firm
  disconnection audits without silently filtering the public panel.
- Add two-group pay-gap simulation, group schedules/sorting, exact decompositions
  under male/female/symmetric references, and selected CCK targets.
- Add homogeneous BM wage posting with endogenous reservation wage, distinct
  offer rates, finite firms, stationary starts, continuous events, structural
  truth, and separate finite/continuum/event/observed quantities.
- Improve block output, destination sampling, graph memory, transactional timer
  handling, reporting invariance, and deterministic/statistical test coverage.

## 0.1.0 — 2026-08-29

- Release pure Stata/Mata simple AKM simulation with annual, quarterly, and monthly
  panels, persistent worker/firm effects, exogenous mobility, spell/duration state,
  initialization/burn-in, optional truth, and largest-component worker filtering.
- Add discovery/configuration, isolated component RNG, caller-data/RNG protection,
  moments/targets/metadata, built-in Stata regression examples, and source installation.
- Qualify Stata/MP 19 on macOS Apple Silicon and Windows x86-64. Broader platforms
  and later model families are separate from this immutable release tag.
