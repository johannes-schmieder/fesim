version 16
clear all
set more off
quietly fesim__load
mata:
void cpv_joint_stationarity(real scalar seed)
{
    struct fesim_cpv_solution scalar s
    struct fesim_rng_state scalar rng
    struct fesim_cpv_draws scalar draws
    real matrix states,Q,Z,initial,R,E,term
    real colvector pi,rhs,ix,empirical,aged
    real rowvector dest,age_theory
    real scalar n,j,k,q,h,idx,rate,N,a,power
    s=fesim_cpv_solve((1.5\1.7\2),1,.5,.3,.2,.05,.5)
    n=3;states=(0,0)
    for(j=1;j<=n;j++) for(q=0;q<=j;q++) states=states\(j,q)
    Q=J(rows(states),rows(states),0)
    for(h=1;h<=rows(states);h++) {
        j=states[h,1];q=states[h,2]
        if(j>0) Q[h,1]=.2
        for(k=1;k<=n;k++) {
            if(j==0) {
                dest=(k,0);rate=.5/n
            }
            else {
                rate=.3/n;dest=(j,q)
                if(k>j) dest=(k,j)
                else if(k!=j & k>q) dest=(j,k)
            }
            idx=selectindex((states[,1]:==dest[1]):&(states[,2]:==dest[2]))[1]
            if(idx!=h) Q[h,idx]=Q[h,idx]+rate
        }
        Q[h,h]=-sum(Q[h,])
    }
    Z=Q';Z[rows(Z),]=J(1,cols(Z),1)
    rhs=J(rows(Z),1,0);rhs[rows(Z)]=1;pi=lusolve(Z,rhs)
    rng=fesim_rng_init(seed,1);draws=fesim_cpv_draws_init()
    N=100000;initial=fesim_cpv_initialize(s,N,"stationary",rng,draws)
    empirical=aged=J(rows(states),1,0)
    for(h=1;h<=rows(states);h++) {
        ix=selectindex((initial[,1]:==states[h,1]):&(initial[,2]:==states[h,2]))
        empirical[h]=length(ix)/N
        if(length(ix)) aged[h]=sum(initial[ix,4]:<=-2)/N
    }
    /* Predeclared absolute Monte Carlo bounds, two disjoint fixed seeds. */
    assert(max(abs(empirical-pi))<.005)
    for(j=1;j<=n;j++) {
        ix=selectindex(states[,1]:==j);R=Q[ix,ix]
        /* Uniformization of the within-employer substochastic generator.
           pi_j exp(2 R_j) is joint mass with job tenure exceeding two years. */
        E=term=I(rows(R))
        for(power=1;power<=45;power++) {
            term=term*(I(rows(R))+R)*2/power
            E=E+term
        }
        age_theory=pi[ix]'*E*exp(-2)
        assert(max(abs(aged[ix]'-age_theory))<.004)
    }
}
cpv_joint_stationarity(81001)
cpv_joint_stationarity(81002)
end
quietly fesim, dgp(cpv) preset(heterogeneous) workers(20000) firms(30) periods(10) seed(82001) truth(full) clear noreport
matrix f=r(cpv_flows)
assert abs(f[1,1]-f[1,2])<.012
forvalues row=2/5 {
    assert abs(f[`row',1]-f[`row',2])<.015
}
quietly summarize worker_ability_true
assert abs(r(mean)-1)<.02
quietly correlate worker_ability_true firm_productivity_true
assert abs(r(rho))<.035
quietly fesim, dgp(cpv) workers(12000) firms(30) periods(5) initial(allunemployed) burnin(60) seed(82002) truth(full) clear noreport
matrix f=r(cpv_flows)
assert abs(f[1,1]-f[1,2])<.02
forvalues row=2/5 {
    assert abs(f[`row',1]-f[`row',2])<.025
}
display "CPV JOINT STATIONARY CONTRACT-TENURE AND FLOW CHECKS PASS"
