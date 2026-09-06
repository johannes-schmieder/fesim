version 16.0
mata:

/* CPV 2006 bargaining protocol, finite uniform-contact economy.
   Values and wages are per efficiency unit. See docs/cpv-derivation.md. */
struct fesim_cpv_solution {
    real scalar schema_version
    real scalar b, lambda_u, lambda_e, delta, discount, beta, B
    real scalar residual, unemployment_rate, ee_rate, renegotiation_rate
    real colvector p, S, prefix, group_first, group_last, mass, entry_wage
    real scalar validated
}

real scalar fesim_cpv_schema_version() return(1)

real scalar fesim_cpv_contract_surplus(
    struct fesim_cpv_solution scalar s, real scalar j, real scalar q)
{
    real scalar sq
    sq = 0
    if (q > 0) sq = s.S[q]
    return(s.beta*s.S[j] + (1-s.beta)*sq)
}

real scalar fesim_cpv_wage(
    struct fesim_cpv_solution scalar s, real scalar j, real scalar q)
{
    real scalar n, hi, lo, sq, c, gain, own
    n = rows(s.p)
    hi = s.group_last[j]
    lo = 0
    sq = 0
    if (q > 0) {
        lo = s.group_last[q]
        sq = s.S[q]
    }
    c = s.beta*s.S[j] + (1-s.beta)*sq
    own = j > lo
    gain = (1-s.beta)*(s.prefix[hi+1]-s.prefix[lo+1] -
        own*s.S[j] - (hi-lo-own)*sq)
    gain = gain + s.beta*(s.prefix[n+1]-s.prefix[hi+1]) +
        (n-hi)*((1-s.beta)*s.S[j]-c)
    return(s.B + (s.discount+s.delta)*c - s.lambda_e*gain/n)
}

/* Return (new employer, new reference, kind): 0 null, 1 EE, 2 raise.
   Equal-productivity distinct rivals can raise a contract, never cause EE. */
real rowvector fesim_cpv_offer(
    struct fesim_cpv_solution scalar s, real scalar j,
    real scalar q, real scalar k)
{
    real scalar sq
    if (k == j) return((j,q,0))
    if (s.p[k] > s.p[j]) return((k,j,1))
    sq = 0
    if (q > 0) sq = s.S[q]
    if (s.beta < 1 & s.S[k] > sq) return((j,k,2))
    return((j,q,0))
}

struct fesim_cpv_solution scalar fesim_cpv_solve(
    real colvector p, real scalar b, real scalar lu, real scalar le,
    real scalar delta, real scalar discount, real scalar beta)
{
    struct fesim_cpv_solution scalar s
    real scalar n, lo, hi, j, den, ta, tc, A, C, tailS, eq, cum, G
    real scalar below, rename_mass, employment, scale
    real colvector av, cv
    n = rows(p)
    if (n < 1 | cols(p) != 1 | any(missing(p)) | any(p :<= 0) |
        missing((b,lu,le,delta,discount,beta)) | b <= 0 | lu <= 0 |
        le < 0 | delta <= 0 | discount <= 0 | beta < 0 | beta > 1) {
        _error(3300, "CPV primitives are invalid")
    }
    if (n > 1) {
        if (any(p[2..n] :< p[1..n-1])) _error(3300, "CPV firms must be sorted")
    }
    s.schema_version = 1
    s.validated = 0
    s.p=p; s.b=b; s.lambda_u=lu; s.lambda_e=le
    s.delta=delta; s.discount=discount; s.beta=beta
    av=cv=s.group_first=s.group_last=J(n,1,.)
    ta=tc=0
    hi=n
    while (hi >= 1) {
        lo=hi
        while (lo > 1) {
            if (p[lo-1] != p[hi]) break
            lo--
        }
        den=discount+delta+beta*le*(n-hi)/n
        A=(p[hi]+beta*le*ta/n)/den
        C=(1+beta*le*tc/n)/den
        for (j=lo; j<=hi; j++) {
            av[j]=A; cv[j]=C; s.group_first[j]=lo; s.group_last[j]=hi
        }
        ta=ta+(hi-lo+1)*A; tc=tc+(hi-lo+1)*C
        hi=lo-1
    }
    s.B=(b+lu*beta*mean(av))/(1+lu*beta*mean(cv))
    s.S=av-s.B*cv
    if (any(missing(s.S)) | min(s.S) <= 0 | missing(s.B)) {
        _error(430, "CPV requires positive surplus at every firm; revise primitives")
    }
    if (missing(s.B/discount) | missing(s.B/discount+max(s.S))) {
        _error(430, "CPV lifetime values exceed the numerical range; revise discounting")
    }
    s.prefix=0\runningsum(s.S)
    s.residual=abs(s.B-b-lu*beta*mean(s.S))/max((1,abs(s.B)))
    s.entry_wage=s.mass=J(n,1,.)
    s.unemployment_rate=delta/(delta+lu)
    employment=1-s.unemployment_rate
    s.ee_rate=s.renegotiation_rate=0
    cum=0
    lo=1
    while (lo <= n) {
        hi=s.group_last[lo]
        G=delta*(hi/n)/(delta+le*(1-hi/n))
        for (j=lo; j<=hi; j++) s.mass[j]=employment*(G-cum)/(hi-lo+1)
        below=employment*cum
        rename_mass=(s.unemployment_rate*lu+le*below)/(n*delta+le*(n-lo))
        if (beta < 1) s.renegotiation_rate=s.renegotiation_rate+
            le/n*(hi-lo+1)*(n-lo)*rename_mass/employment
        cum=G
        lo=hi+1
    }
    for (j=1; j<=n; j++) {
        hi=s.group_last[j]
        tailS=s.prefix[n+1]-s.prefix[hi+1]
        eq=(discount+delta+beta*le*(n-hi)/n)*s.S[j] -
            (p[j]-s.B+beta*le*tailS/n)
        scale=max((1,abs(p[j]),abs(s.B)))
        s.residual=max((s.residual,abs(eq)/scale))
        s.entry_wage[j]=fesim_cpv_wage(s,j,0)
        s.ee_rate=s.ee_rate+s.mass[j]*le*(n-hi)/n/employment
        s.residual=max((s.residual,abs(fesim_cpv_wage(s,j,j)-p[j])/scale))
    }
    if (any(missing(s.entry_wage)) | min(s.entry_wage) <= 0) {
        _error(430, "CPV entry wages must be positive at every firm; revise primitives")
    }
    if (s.residual > 1e-9) _error(430, "CPV Bellman residual exceeds tolerance")
    s.validated=1
    return(s)
}
end
