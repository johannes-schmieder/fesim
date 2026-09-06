# CPV finite-firm derivation and source audit

Cahuc, Postel-Vinay and Robin (2006), *Wage Bargaining with On-the-Job Search:
Theory and Evidence*, Econometrica 74(2), 323–364,
[DOI](https://doi.org/10.1111/j.1468-0262.2006.00665.x).
Author revision: November 2005, linked by Jean-Marc Robin's publications page;
[PDF](https://www.dropbox.com/scl/fi/flr1livxn9k9pb4buolb6/WBWOJS.pdf?dl=1&rlkey=y3fqkdvjysfe3cxxfubknsiju).
Retrieved 2026-09-06; 858157 bytes; SHA256
`f7e51c74dbd349143abb30a464ac29ac37475a42aca94a0eeb8076ea28aab91d`.
This audit uses the author revision, not a verified publisher PDF.

Rendered PDF pages 9–11 (printed 7–9) verify equation (2), the three offer
cases, wage cuts on upward moves, equation (3), beta limits, and equations
(4)–(5). Equation (4) visibly prints p_inf as its first term, inconsistent
with its own equality to equation (3). We do not copy that apparent typo:
entry wages are inverted from the Bellman equation and checked independently.
Claims about the published version retain a needs-published-check qualification.

## Finite values

There are J sorted firms, equal contact weights a=1/J, positive productivity
p_j, destruction delta, discount r, offer rates lambda_u and lambda_e, and
worker bargaining share beta. Quantiles are midpoint grid points or sorted
independent uniform draws. Equal productivity is grouped, never broken into
an artificial productivity ranking. Let B=rU and S_j=M_j-U per efficiency unit.

    B = b + lambda_u beta mean(S)
    (r+delta+beta lambda_e A_tail_j) S_j
      = p_j-B+beta lambda_e sum_{p_k>p_j} a S_k.

Backward recursion expresses S_j=A_j-B C_j; substituting their means into the
first equation gives one scalar linear solution for B. Prefix sums then make
wages constant-time queries. Storage and arithmetic after sorting are O(J).
Scaled Bellman residuals must not exceed 1e-9; independent tiny-economy fixtures
use 1e-12. All S_j and all entry wages must be positive, without clipping.

## Contracts and wages

A job stores employer j and reference q, with q=0 denoting unemployment and
S_0=0. Its promised surplus is C=beta S_j+(1-beta)S_q. An offer from k=j is
null. If p_k>p_j, the worker moves to (k,j). Otherwise, if S_k>S_q and beta<1,
the worker stays and obtains reference k. All other offers leave the contract
unchanged. Equal-productivity distinct firms may produce C=S_j.

    w(q,j) = B + (r+delta) C - lambda_e mean_k(C_after(k)-C).

Self contacts enter with zero gain. Higher offers and retained-firm raises
are summed separately using productivity-group endpoints and surplus prefix
sums. The full-surplus wage is exactly p_j. The minimum wage at each firm is
its unemployment-entry contract. Ability epsilon scales all levels and values;
comparisons stay in per-unit values, so ability dispersion cannot alter paths.

## Finite stationary allocation and raises

Unemployment is u=delta/(delta+lambda_u). Conditional employment CDF at an
entire productivity group with cumulative offer mass F is
G=delta F/[delta+lambda_e(1-F)]. Divide each group increment equally among its
firms. Let m_j denote unconditional firm mass. The EE rate per employment year
is lambda_e sum_j m_j A_tail_j/(1-u).

For an offered productivity group starting at index l, the stationary mass at
any incumbent with productivity at least that offer and reference strictly
below it is

    H_l = [u lambda_u + lambda_e sum_{p_h<p_l} m_h]
          / [J delta + lambda_e (J-l)].

There are J-l potential incumbent rivals per offered firm, excluding self.
Thus the raise rate is lambda_e/J times the sum of group_size (J-l) H_l,
divided by employment, when beta<1; it is zero at beta=1. A tiny independent
CTMC over all (employer,reference) states verifies both masses and raise rates.

## Exact stationary histories

Conditional employment, time since the last UE is exponential(delta). Start
at that backward age with a uniform entry employer and q=0; replay employed
offers until time zero, conditioning on no destruction. This is the stationary
regenerative history, jointly generating employer, reference and job tenure.
Conditional unemployment, backward duration is exponential(lambda_u). Only the
initial-state RNG stream is used. Retained and burn-in paths use the existing
mobility-event and destination streams. Primitive offers include null contacts.

## Numerical range guard

Finite current wages do not guarantee representable lifetime values when r is
extremely small. The solver rejects nonfinite U and full-productivity values;
the handler additionally checks the maximum ability-scaled productivity/value
bound under every truth mode. Fixed tiny-discount regression cases verify
transactional data/RNG rollback, including after worker draws.
