# Canonical Burdett–Mortensen equilibrium

## Status and scope

This note freezes owner-approved decision D-036 for `dgp(bm) preset(simple)`.
It is the homogeneous-worker, homogeneous-firm case of the
Burdett–Mortensen wage-posting model. Firms share one productivity level and
mix continuously over permanent posted wages. Workers search while unemployed
and employed. The unemployed and employed offer-arrival rates are distinct
primitives; the equal-arrival model is an exact nested special case.

This is an exact model with a stylized calibration. It is not the later
heterogeneous-productivity BM extension. The continuum equilibrium is solved
before a finite firm universe is constructed. D-037 fixes deterministic
midpoint quantiles as the finite-firm default and retains isolated-stream
random quantiles as an opt-in mode.

## Environment and primitives

Normalize the masses of workers and firms to one in the continuum economy.
Workers and firms are homogeneous. A firm employs any mass of labor under a
linear technology with common flow productivity `p` per worker. A firm posts
one permanent wage and does not bargain, counter an outside offer, or change
the wage during a match.

The model primitives are:

| Parameter | Meaning | Unit and required interior condition |
|---|---|---|
| `b` | worker flow payoff in unemployment | wage-flow level |
| `p` | common worker productivity | wage-flow level; `p>b` |
| `lambda_u` | offer-arrival rate while unemployed | annual continuous-time rate; positive |
| `lambda_e` | offer-arrival rate while employed | annual continuous-time rate; positive |
| `delta` | exogenous job-destruction rate | annual continuous-time rate; positive |
| `r` | worker discount rate | annual continuous-time rate; positive |

The equilibrium must also have a strictly positive reservation wage because
the common output contract stores log wages. Boundary values such as
`lambda_e -> 0`, `delta -> 0`, or `r -> 0` are limiting-case tests rather than
public interior configurations.

Let `F(w)` be the cross-firm CDF of posted wages, with support
`[R, wbar]`. Unemployed workers accept offers weakly above `R`. Employed
workers accept only strictly higher wages. The continuum distribution has no
atoms, so ties have probability zero. A later finite-firm implementation must
apply the strict rule literally when discrete wages tie.

All firms are sampled uniformly by the offer process. There is no separate
firm-attraction primitive in the canonical model.

## Worker values and reservation wage

Let `U` be the value of unemployment and `W(w)` the value of a job paying
`w`. The worker Bellman equations are

\[
rU=b+\lambda_u\int_R^{\bar w}[W(x)-U],dF(x),
\]

\[
rW(w)=w+\delta[U-W(w)]
+\lambda_e\int_w^{\bar w}[W(x)-W(w)],dF(x).
\]

The reservation condition is `W(R)=U`. Differentiating the employment value
and integrating the surplus gives

\[
W'(w)=\frac{1}{r+\delta+\lambda_e[1-F(w)]},
\]

\[
R=b+(\lambda_u-\lambda_e)
\int_R^{\bar w}
\frac{1-F(x)}{r+\delta+\lambda_e[1-F(x)]},dx.
\tag{1}
\]

Equation (1) is essential when `lambda_u != lambda_e`. Imposing `R=b` while
retaining distinct arrival rates generally violates the worker value
equations. If `lambda_u=lambda_e`, equation (1) yields `R=b` exactly and `r`
does not affect the allocation.

Once `R` and `F` are known, the values themselves are

\[
U=\frac{b+\lambda_u S}{r},\qquad
S=\int_R^{\bar w}[W(x)-U],dF(x),
\]

\[
W(w)=U+\int_R^w
\frac{dx}{r+\delta+\lambda_e[1-F(x)]}.
\]

## Stationary worker distribution

Every equilibrium offer is acceptable from unemployment. Stationary
unemployment and employment are therefore

\[
u=\frac{\delta}{\delta+\lambda_u},\qquad
e=\frac{\lambda_u}{\delta+\lambda_u}.
\tag{2}
\]

Let `G(w)` be the CDF of wages among employed workers. Flow balance below
`w` gives

\[
G(w)=\frac{\delta F(w)}
{\delta+\lambda_e[1-F(w)]}.
\tag{3}
\]

Conditional on wage `w`, destruction occurs at rate `delta` and accepted
job-to-job offers occur at rate `lambda_e * [1-F(w)]`. The aggregate employed
job-to-job rate is

\[
\lambda_e\int_R^{\bar w}[1-F(w)],dG(w)
=\frac{\delta(\delta+\lambda_e)}{\lambda_e}
\log\left(1+\frac{\lambda_e}{\delta}\right)-\delta.
\tag{4}
\]

## Firm labor supply

A firm paying `w` recruits unemployed workers and employed workers currently
earning less than `w`. Its workers leave through destruction or a strictly
better offer. Up to the common worker-to-firm mass scale, steady-state
employment is

\[
\ell(w;F)=
\frac{\delta\lambda_u(\delta+\lambda_e)}
{(\delta+\lambda_u)
 [\delta+\lambda_e(1-F(w))]^2}.
\tag{5}
\]

The firm chooses its permanent posted wage to maximize steady-state flow
profit

\[
\pi(w)=(p-w)\ell(w;F).
\tag{6}
\]

Expected present-value profit with endogenous wage revision is a different
game and is not part of `bm/simple`.

## Equal-profit equilibrium

Equal profit on the connected support and `F(R)=0` imply

\[
F(w)=\frac{\delta+\lambda_e}{\lambda_e}
\left[1-\sqrt{\frac{p-w}{p-R}}\right],
\qquad R\leq w\leq\bar w,
\tag{7}
\]

with upper support

\[
\bar w=p-(p-R)
\left(\frac{\delta}{\delta+\lambda_e}\right)^2.
\tag{8}
\]

The inverse offer CDF is particularly convenient for validation and finite
firm construction:

\[
F^{-1}(q)=p-(p-R)
\left[1-\frac{\lambda_e}{\delta+\lambda_e}q\right]^2,
\qquad 0\leq q\leq1.
\tag{9}
\]

Substituting (7) into (5) yields

\[
\ell(w)=
\frac{\delta\lambda_u}
{(\delta+\lambda_u)(\delta+\lambda_e)}
\frac{p-R}{p-w},
\tag{10}
\]

so every on-support wage produces the same profit

\[
\bar\pi=
\frac{\delta\lambda_u}
{(\delta+\lambda_u)(\delta+\lambda_e)}(p-R).
\tag{11}
\]

A wage below `R` attracts no workers. A wage above `wbar` has the same
recruiting and retention advantage as `wbar` but costs more. Hence neither is
a profitable deviation.

## Closed-form reservation wage

Under (7), the surplus integral in (1) is `C * (p-R)`, where

\[
C=\frac{2\lambda_e}{(\delta+\lambda_e)^2}
\left[
\frac12-\frac{r}{\lambda_e}
+\frac{r(r+\delta)}{\lambda_e^2}
\log\left(1+\frac{\lambda_e}{r+\delta}\right)
\right].
\tag{12}
\]

Therefore

\[
R=\frac{b+(\lambda_u-\lambda_e)Cp}
{1+(\lambda_u-\lambda_e)C}.
\tag{13}
\]

The implementation should evaluate (12) with `log1p`-style numerical care
and use an independent quadrature/root residual as a validation path. The
analytical formula, not a stochastic or grid search, is the primary solver.

## Wage units and public output

The structural objects `b`, `p`, `R`, `w`, and `wbar` are wage-flow levels.
They cannot be reinterpreted as log wages because the firm's surplus is
`p-w`. The public panel follows the established package contract:

- `posted_wage_true` is the accepted posted wage in levels;
- `productivity_true` is `p` in levels while employed;
- `lnwage_true = log(posted_wage_true)`;
- `lnwage = lnwage_true` in the canonical model;
- wages and job-specific truth are missing in nonemployment;
- canonical observation error is zero.

This requires the solved support to be strictly positive. A configuration
with `R<=0` is invalid for the public log-wage panel.

## Existence, uniqueness, and limits

For the public interior model, `p>b`, all four rates are positive, and the
solution of (13) satisfies `0<R<wbar<p`. Under these conditions the
homogeneous model has the unique continuous nondegenerate symmetric wage-offer
equilibrium described above.

Required limiting checks are:

- `lambda_u=lambda_e` gives `R=b` exactly;
- `lambda_e -> 0` collapses the wage support to `R`;
- `lambda_e -> infinity` moves the upper support toward `p` and employment
  weight toward the top;
- increasing `lambda_e/delta` widens the offer support and steepens the
  firm-size ladder;
- `G` first-order stochastically dominates `F` because higher-wage firms are
  larger;
- all on-support profits are equal and off-support deviations are weakly
  worse.

## Numerical hand check

For

```text
p=1, b=.4, lambda_u=1, lambda_e=.5, delta=.2, r=.05
```

equations (2), (8), and (12)–(13) give

```text
C                 .928429825374297
R                 .590224088826639
wbar              .966548905210338
u                 .166666666666667
reservation S     .380448177653277
profit            .097565693137
```

Selected offer quantiles are:

| `q=F(w)` | `w` | `G(w)` | `ell(w)` | profit |
|---:|---:|---:|---:|---:|
| 0 | .590224088827 | 0 | .238095238095 | .097565693137 |
| .25 | .723505794629 | .086956521739 | .352867044739 | .097565693137 |
| .50 | .830653832627 | .222222222222 | .576131687243 | .097565693137 |
| .75 | .911668202821 | .461538461538 | 1.104536489152 | .097565693137 |
| 1 | .966548905210 | 1 | 2.916666666667 | .097565693137 |

`tests/unit/test_bm_derivation.do` reproduces these values, compares the
closed-form reservation wage with Simpson quadrature plus bisection, verifies
the offer and worker CDFs, and checks equal profit and the equal-arrival case.

## Solver and finite-firm construction

Checkpoint 40 implements the internal continuum solver in
`src/fesim_bm.mata`. `fesim_bm_solve()`:

1. evaluates equations (7)–(13) analytically;
2. uses series expansions for small rate ratios to avoid cancellation in the
   surplus coefficient, `log(1+x)`, and aggregate job-to-job rate;
3. independently evaluates equation (1) by Simpson quadrature through
   `fesim_bm_reservation_residual()` without using the closed-form coefficient;
4. evaluates a linear wage-support grid and checks support endpoints, CDF
   bounds and monotonicity, firm employment, and equal profit;
5. returns a versioned Mata solution object with `converged_analytic` status,
   theoretical moments, arrays, and scaled residual diagnostics; and
6. rejects invalid primitives or nonpositive log-wage support with error 3300
   and analytical/numerical validation failures with error 430.

The solver and checker consume no random numbers and do not inspect or alter
Stata data. They are internal infrastructure: `r(solver)` will be exposed only
when the later public handler is qualified.

D-037 selects both finite-firm modes and makes midpoint quantiles the default.
For `J` firms,

\[
q_j=(j-1/2)/J,\qquad w_j=F^{-1}(q_j).
\]

Each firm receives offer probability `1/J`. This rule is deterministic,
avoids exact support endpoints, and has offer-CDF Kolmogorov error `1/(2J)`.
The opt-in random mode draws independent `q_j` from the uniform distribution
using only the `firm_primitives` RNG stream. Both modes sort quantiles and
wages before assigning stable rank IDs. The random-mode secondary sort key is
the original draw position, so even a floating-point tie has deterministic
identity.

The finite wages remain a discretization of the continuum mixed strategy, not
a solution to a finite wage-posting game. The package separately solves the
exact stationary worker allocation for the discrete offer distribution. If
`L_j` is firm `j`'s worker-mass share, then

\[
\left[\delta+\lambda_e\frac{\#\{k:w_k>w_j\}}{J}\right]L_j
=\frac{\lambda_u u}{J}
+\frac{\lambda_e}{J}\sum_{k:w_k<w_j}L_k. \tag{14}
\]

The recursion uses strictly lower and higher wages. Equal-wage firms have
equal mass, and offers at tied wages do not create job-to-job moves. It sums
to the continuum employment mass `1-u` up to floating-point error. Expected
headcount is `N*L_j`; `J*L_j` is the finite employment scale directly
comparable to continuum `ell(w_j)`.

Checkpoint 41 exact-qualifies API 28 and finite-firm schema 1, which implement
the inverse CDF, both constructions,
the exact recursion, strict-tie handling, finite job-to-job rate, and separate
offer-CDF, worker-CDF, employment-quadrature, and stationary-flow diagnostics.
The default construction consumes no random numbers. Random construction is
repeatable under `seed()` and does not advance worker, mobility, destination,
or other component streams. Theoretical, finite-firm, event-sample, and
observed-panel moments remain distinct.

## Continuous-time worker events

D-038 implements exact continuous-time worker histories after the firm
universe is fixed. While unemployed, the next event time is exponential with
rate `lambda_u` and the event is a uniformly sampled firm offer. While
employed, the next event time is exponential with rate `lambda_e+delta`; a
second uniform selects destruction below
`delta/(lambda_e+delta)` and an offer otherwise. This combined-clock
construction is distributionally identical to racing independent offer and
destruction clocks. The exact threshold is assigned to an offer, and endpoint
uniforms are moved to the nearest package-defined open-unit boundary so
waiting times are positive.

An unemployed worker accepts every offer because all finite wages lie weakly
above `R`. An employed worker accepts only

\[
w_{offer}>w_{current}.
\]

Thus contacts with the current firm, lower wages, or tied wages are recorded
as rejected employed offers and do not alter tenure or spell ID. Accepted UE
and EE offers increment the worker-local spell count and reset tenure;
destruction starts unemployment duration at zero. All durations are measured
in continuous years.

Timing/type draws use `mobility_events`; contacted-firm draws use
`destination_draws`. Fixed-size internal draw buffers amortize Stata RNG-state
switching but do not mix component streams. The optional private ledger has
11 columns: worker, time, kind, acceptance, origin, offered firm, destination,
post-event spell, post-event tenure, post-event unemployment duration, and
waiting time. Its rows are worker-major and strictly ordered within worker.
Recording it does not change economic draws or final states. Events exactly at
the horizon are included. Checkpoint 42 exact-qualifies API 29/BM-history
schema 1, which remains internal until
initialization, aggregation, and the public handler are qualified.

## Sources

- Burdett, Kenneth, and Dale T. Mortensen. 1998. “Wage Differentials,
  Employer Size, and Unemployment.” *International Economic Review* 39(2):
  257–273. The package implements their identical-worker/identical-employer
  case.
- Hornstein, Andreas, Per Krusell, and Giovanni L. Violante. 2011.
  “Frictional Wage Dispersion in Search Models: A Quantitative Assessment.”
  *American Economic Review* 101(7): 2873–2908. Section VII, especially
  equations (18)–(20), gives the distinct-arrival worker values, reservation
  condition, and employed-wage distribution used here.
- Lanot, Gauthier, and George R. Neumann. 1996. “Measuring Productivity
  Differences in Equilibrium Search Models.” Working Paper 96-12, Centre for
  Labour Market and Social Research. Equations (2)–(4) record the homogeneous
  firm labor supply, offer distribution, and worker distribution.
