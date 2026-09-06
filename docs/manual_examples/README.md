# Manual examples

These ten self-contained Stata 19 do-files generate their own fixed-seed data,
retain named graphs, and restore the caller's dataset. Put the current
development version of `fesim` on the adopath before running an individual file.

From the repository root, run all examples and export the ten vector figures:

```stata
do docs/manual_figures.do
```

The driver also accepts an explicit repository path as its first argument.
It uses official Stata commands only. No external dataset is needed.

| File | Illustration | Seed(s) |
|---|---|---|
| `01_akm.do` | Simple-AKM wage dispersion and realized sorting | 20260901 |
| `02_mobility.do` | Stylized mobility and Germany-targeted sorting | 20260902, 20260903 |
| `03_paygap.do` | CCK-inspired wage gaps and both firm premium schedules | 20260904 |
| `04_bm.do` | Offer/worker CDFs and finite stationary firm sizes | 20260905 |
| `05_bm_paths.do` | Four workers' monthly BM histories | 20260906 |
| `06_bm_flows.do` | Exact BM event rates versus annual/monthly endpoint flags | 20260907 |

The manual reads these files directly with `\lstinputlisting`, so executable
and printed code share one source. The BM examples assert that all 100 firms
are represented in the illustrated snapshot and that exact event rates agree
across nested observation frequencies, respectively.

Compile the manual from a shell at the repository root:

```sh
bash docs/build_manual.sh
```

This requires `latexmk`, `pdflatex`, and a standard LaTeX installation. It uses
the committed figures, writes auxiliary files under ignored `build/manual/`,
and places the final PDF at `docs/fesim_manual.pdf`. Regenerating figures
requires Stata; compiling the existing document does not. These documentation
dependencies are separate from the Stata/Mata-only installed runtime.

CPV examples: `07_cpv_paths.do` shows selected worker histories with raises and
wage cuts (seed 20260908); `08_cpv_dispersion.do` shows within-firm dispersion
before/after ability scaling (20260909); `09_cpv_bargaining.do` compares beta
0/.5/1 with common employment paths (20260910); `10_cpv_movers.do` runs official
`areg` and plots balanced mover windows (20260911). All are self-contained.
