# fesim

**Simulate linked worker–firm panels in Stata, with known model parameters and truth.**

`fesim` generates synthetic employment histories and wages for teaching,
Monte Carlo experiments, and testing methods for matched employer–employee data.
Choose an economic model, set its parameters, and receive a panel with worker
and firm identifiers, wages, mobility indicators, and optional latent truth.
The same interface covers additive AKM wages, two-group pay gaps, wage posting,
sequential bargaining, and finite worker and firm types.

The runtime uses only **official Stata and Mata**. No plugin, compiler, Python,
R, or user-written Stata command is needed.

The current source version is **1.2.0-rc.1**, a development candidate requiring
**Stata 19 or later**. It has been tested with Stata/MP 19 on Apple Silicon Macs.
Linux, Windows, Stata/SE, and older Stata versions have not been qualified for
this candidate. The older `v0.1.0` tag contains only simple AKM simulation and
was also tested on Windows x86-64. See [compatibility](docs/compatibility.md).

## Install

In Stata, install the current source and open the help:

```stata
net install fesim, from("https://raw.githubusercontent.com/johannes-schmieder/fesim/main") replace
fesim version
help fesim
```

If upgrading from an installation with `_fesim_*` helper files, first run
`ado uninstall fesim`, then use the install command above. Stata's `replace`
updates the package but leaves files removed from the manifest on disk; the
uninstall step removes the old helpers before the renamed files are installed.

`main` can change. For reproducible research, replace `main` in the URL with
an exact Git commit and record that commit, your Stata version, and the command.
The immutable simple-AKM version is available by using `v0.1.0` instead.
There is no SSC distribution or tagged 1.2 release yet.

For an offline installation, download or clone the repository and run:

```stata
net install fesim, from("/path/to/fesim") replace
```

All Mata source is included; it loads in Stata without a separate build step.
For development directly from a checkout, use `adopath ++ "/path/to/fesim"`.

## Generate your first panel

The following creates 500 workers, 30 firms, and eight annual observations per
worker. It saves the known worker and firm wage effects alongside observed
wages, then fits an AKM-style regression with Stata's built-in `areg`.

```stata
preserve
fesim, dgp(akm) preset(simple) workers(500) firms(30) periods(8) ///
    seed(12345) truth(basic) connectivity(largest) clear

* Save simulation results before another command replaces r().
matrix simulation_moments = r(moments)
matrix simulation_network = r(network)

isid workerid time
summarize lnwage alpha_true psi_true if employed
matrix list simulation_moments
matrix list simulation_network
areg lnwage i.firmid i.time if employed, absorb(workerid)
restore
```

`connectivity(largest)` keeps complete histories for workers in the largest
observed worker–firm component, so the returned worker count may be below 500.
Use `connectivity(keep)`, the default, to keep everyone. Nonemployment rows have
`employed==0` and missing `firmid` and `lnwage`.

The help has **22 clickable, self-contained examples**, including graphs and
mover profiles. To run the basic simulation example while restoring your data:

```stata
fesim_run simulate using fesim.sthlp
```

An ordinary successful simulation with `clear` replaces the current dataset.
Use `preserve`/`restore` as above when you want to keep your data. With a supplied
`seed()`, simulation leaves the caller's RNG state unchanged.

## Choose a model

A **DGP** defines the model; a **preset** supplies its parameterization.

| DGP and preset | Useful for | Interpretation |
| --- | --- | --- |
| `akm`, `simple` | Additive worker/firm wages and exogenous mobility | Stylized teaching and testing baseline |
| `akm`, `stylized` | Duration dependence, worker heterogeneity and sorting | Monthly mobility with uncalibrated parameters |
| `akm`, `germany_chk_2002_2009` | Wage dispersion and sorting resembling selected CHK moments | Targets selected West German wage moments; hazards remain stylized |
| `akmpaygap`, `simple` | Separating composition, firm sorting and premium schedules | Stylized two-group design |
| `akmpaygap`, `cck2016` | Selected group moments and pay-gap decomposition | CCK-inspired targets under a different normalization |
| `bm`, `simple` | Wage posting and upward job-to-job moves | Homogeneous-worker, common-productivity Burdett–Mortensen equilibrium |
| `cpv`, `simple` | Outside-offer bargaining and incumbent raises | Finite-firm Cahuc–Postel-Vinay–Robin model |
| `cpv`, `heterogeneous` | Bargaining with worker ability differences | Same protocol with multiplicative ability |
| `blm`, `static` | Nonadditive worker-type/firm-class earnings | Employed-only Gaussian finite-type forward process |
| `blm`, `dynamic` | Persistence and earnings-dependent mobility | Monthly forward process following BLM restrictions |

All BM, CPV, and BLM preset parameters are illustrative. These routes simulate
models; they do not estimate them or reproduce their empirical applications.
BLM provides finite-type long panels rather than a general replica of the
authors' conditional short-panel simulator.

Discover defaults, bounds, units, truth variables, and source scope in Stata:

```stata
fesim list
fesim presets blm
fesim describe blm, preset(dynamic)
```

Omitting `dgp()` selects `akm/simple`. The aliases `akmsimple`, `akmempirical`,
and `bmsimple` select `akm/simple`, `akm/stylized`, and `bm/simple` respectively;
`akmempirical` does not mean an empirical calibration.

## Customize an experiment

### Additive wages and mobility

Common options control the panel. Model-specific name/value pairs belong in
`parameters()`:

```stata
fesim, dgp(akm) workers(2000) firms(100) periods(24) frequency(month) ///
    start(2000m1) seed(9876) truth(full) ///
    parameters(sd_worker .45 sd_firm .18 p_ee .10) clear
```

`periods(24) frequency(month)` means 24 monthly observations, not 24 years.
Transition inputs keep their documented annual units. AKM also supports
`network(blocks)`, `network(bridges)`, and `network(ladder)` for mobility stress
experiments. These designs do not guarantee leave-out connectedness; see
[network definitions](docs/network.md).

### Two-group pay gaps

```stata
fesim, dgp(akmpaygap) preset(cck2016) workers(5000) firms(500) ///
    periods(8) burnin(5) seed(13579) truth(full) clear
matrix list r(group_moments)
matrix list r(decomposition)
```

`group=0` denotes men and `group=1` women; gaps are men minus women. The
returned decomposition includes male-reference, female-reference, and symmetric
columns. The [calibration guide](docs/calibration.md) explains the selected
targets and normalization.

### Sequential bargaining

```stata
fesim, dgp(cpv) preset(heterogeneous) workers(2000) firms(100) ///
    periods(8) seed(12345) truth(full) parameters(beta .5) clear
matrix list r(solver)
matrix list r(cpv_flows)
summarize contract_wage_true worker_ability_true if employed
```

A better outside offer can raise pay at the incumbent firm or lead to a move
with a wage cut. Structural wages and productivity are distinct from AKM firm
effects. The [manual](docs/fesim_manual.pdf) explains the bargaining mechanism.

### Nonlinear earnings and persistence

```stata
fesim, dgp(blm) preset(dynamic) workers(2000) firms(100) ///
    periods(24) frequency(month) seed(12345) truth(full) clear
matrix list r(blm_mean)
matrix list r(blm_cells)
summarize lnwage persistence_true move_probability_true
```

Worker types and firm classes determine earnings and mobility. Optional Stata
matrices let you set cell means, scales, move rates, persistence, and destination
weights. BLM keeps all workers employed and does not supply additive AKM truth.
See [the BLM note](docs/blm.md) and its help examples for matrix dimensions.

## Read the output

Each row is one worker at one output date, sorted by `workerid time`. The main
variables are `workerid`, `time`, `firmid`, `employed`, and `lnwage`, with spell,
tenure, and observed mobility indicators. `jobtojob` compares adjacent retained
snapshots; `ntransitions` counts latent transitions in the interval and can
exceed one. More frequent output can reveal moves hidden by annual snapshots.

`truth(none)` suppresses latent columns, `truth(basic)` is the default, and
`truth(full)` adds model-specific details. Changing truth mode leaves the
common simulated data unchanged. BM and CPV also distinguish theoretical
hazards, simulated event rates, and observed endpoint transitions.

Immediately after simulation, inspect `return list`. Common matrices include
`r(parameters)`, `r(moments)`, `r(targets)`, `r(network)`, and `r(leaveout)`;
additional results depend on the model. Save matrices before running commands
that overwrite `r()`. Configuration and seed metadata also stay in the dataset's
`fesim_*` characteristics. Graph and leave-out results are diagnostics; they do
not silently select a leave-out sample or certify BLM mixture identification.

## Documentation and support

- [Stata help](fesim.sthlp): options, 22 examples, and stored results; best viewed with `help fesim`.
- [Illustrated manual](docs/fesim_manual.pdf): user guide, model equations, fourteen figures, and technical appendices.
- [Standalone examples](examples/README.md) and [manual figure scripts](docs/manual_examples/README.md).
- [Calibration and source scope](docs/calibration.md), [compatibility](docs/compatibility.md), and [performance](docs/performance.md).
- [Contributing](CONTRIBUTING.md): source structure, tests, CI, and qualification.

For a bug report, include the command, `fesim version`, Stata version, error
message, and a small example using synthetic or shareable data.

## Citation and references

Cite the software as **Schmieder, Johannes F. _fesim: Linked employer–employee
panel simulation_. Version 1.2.0-rc.1**, with the [repository URL](https://github.com/johannes-schmieder/fesim)
and exact commit used. [CITATION.cff](CITATION.cff) supplies software metadata.
Also cite the papers relevant to your chosen model or targets:

- Abowd, John M., Francis Kramarz, and David N. Margolis (1999).
  “High Wage Workers and High Wage Firms.” *Econometrica* 67(2), 251–333.
  [doi:10.1111/1468-0262.00020](https://doi.org/10.1111/1468-0262.00020).
- Card, David, Jörg Heining, and Patrick Kline (2013).
  “Workplace Heterogeneity and the Rise of West German Wage Inequality.”
  *Quarterly Journal of Economics* 128(3), 967–1015.
  [doi:10.1093/qje/qjt006](https://doi.org/10.1093/qje/qjt006).
- Card, David, Ana Rute Cardoso, and Patrick Kline (2016).
  “Bargaining, Sorting, and the Gender Wage Gap: Quantifying the Impact of
  Firms on the Relative Pay of Women.” *Quarterly Journal of Economics*
  131(2), 633–686. [doi:10.1093/qje/qjv038](https://doi.org/10.1093/qje/qjv038).
- Burdett, Kenneth, and Dale T. Mortensen (1998).
  “Wage Differentials, Employer Size, and Unemployment.”
  *International Economic Review* 39(2), 257–273.
  [doi:10.2307/2527292](https://doi.org/10.2307/2527292).
- Cahuc, Pierre, Fabien Postel-Vinay, and Jean-Marc Robin (2006).
  “Wage Bargaining with On-the-Job Search: Theory and Evidence.”
  *Econometrica* 74(2), 323–364.
  [doi:10.1111/j.1468-0262.2006.00665.x](https://doi.org/10.1111/j.1468-0262.2006.00665.x).
- Bonhomme, Stéphane, Thibaut Lamadon, and Elena Manresa (2019).
  “A Distributional Framework for Matched Employer Employee Data.”
  *Econometrica* 87(3), 699–739.
  [doi:10.3982/ECTA15722](https://doi.org/10.3982/ECTA15722).
- Kline, Patrick, Raffaele Saggio, and Mikkel Sølvsten (2020).
  “Leave-Out Estimation of Variance Components.” *Econometrica* 88(5), 1859–1898.
  [doi:10.3982/ECTA16410](https://doi.org/10.3982/ECTA16410).

Author: Johannes F. Schmieder, Boston University.
Released under the [MIT License](LICENSE).
