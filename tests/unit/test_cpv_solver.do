version 16.0
args root
quietly fesim__load
mata:
/* Independent dense linear Bellman oracle, deliberately not tail recursion. */
void cpv_oracle(real colvector p, real scalar le, real scalar beta)
{
    struct fesim_cpv_solution scalar s
    real scalar n,j,k,q,h,a,c,g,w,res,ren,idx,nstates
    real matrix L, states, Q, Z
    real colvector rhs,x,pi,m
    real rowvector dest
    n=rows(p)
    s=fesim_cpv_solve(p,1,.5,le,.2,.05,beta)
    L=I(n+1); rhs=1\p
    L[1,2..n+1]=J(1,n,-.5*beta/n)
    for (j=1;j<=n;j++) {
        L[j+1,1]=1
        L[j+1,j+1]=.25
        for (k=1;k<=n;k++) {
            if (p[k]>p[j]) {
                L[j+1,j+1]=L[j+1,j+1]+beta*le/n
                L[j+1,k+1]=L[j+1,k+1]-beta*le/n
            }
        }
    }
    x=lusolve(L,rhs)
    assert(mreldif(x,s.B\s.S)<1e-12)
    for (j=1;j<=n;j++) {
        for (q=0;q<=n;q++) {
            if (q>0) {
                if (p[q]>p[j]) continue
            }
            c=fesim_cpv_contract_surplus(s,j,q); g=0
            for (k=1;k<=n;k++) {
                dest=fesim_cpv_offer(s,j,q,k)
                g=g+(fesim_cpv_contract_surplus(s,dest[1],dest[2])-c)/n
            }
            w=s.B+.25*c-le*g
            assert(abs(w-fesim_cpv_wage(s,j,q))<1e-12)
            assert(w>=s.entry_wage[j]-1e-12 & w<=p[j]+1e-12)
        }
    }
    /* Finite state CTMC includes U and every admissible (employer,reference).
       Generator and stationary distribution use dense, tiny-economy algebra. */
    states=(0,0)
    for(j=1;j<=n;j++) for(q=0;q<=n;q++) {
        if(q==0) states=states\(j,q)
        else if(p[q]<=p[j]) states=states\(j,q)
    }
    nstates=rows(states); Q=J(nstates,nstates,0)
    for(h=1;h<=nstates;h++) {
        j=states[h,1];q=states[h,2]
        if(j>0) Q[h,1]=.2
        for(k=1;k<=n;k++) {
            if(j==0) {
                dest=(k,0,1);a=.5/n
            }
            else {
                dest=fesim_cpv_offer(s,j,q,k);a=le/n
            }
            idx=selectindex((states[,1]:==dest[1]):&(states[,2]:==dest[2]))[1]
            if(idx!=h) Q[h,idx]=Q[h,idx]+a
        }
        Q[h,h]=-sum(Q[h,])
    }
    Z=Q'; Z[nstates,]=J(1,nstates,1)
    rhs=J(nstates,1,0);rhs[nstates]=1
    pi=lusolve(Z,rhs)
    assert(max(abs(Q'*pi))<1e-12 & min(pi)>-1e-12)
    assert(abs(pi[1]-s.unemployment_rate)<1e-12)
    m=J(n,1,0);ren=0
    for(h=2;h<=nstates;h++) {
        j=states[h,1];q=states[h,2];m[j]=m[j]+pi[h]
        for(k=1;k<=n;k++) {
            dest=fesim_cpv_offer(s,j,q,k)
            if(dest[3]==2) ren=ren+pi[h]*le/n/(1-pi[1])
        }
    }
    assert(mreldif(m,s.mass)<1e-12)
    assert(abs(ren-s.renegotiation_rate)<1e-12)
}
for (beta=0;beta<=1;beta=beta+.5) {
    cpv_oracle((1.5\1.7\2),.3,beta)
    cpv_oracle((1.5\1.5\2\2),.3,beta)
    cpv_oracle((1.5\1.7\2),0,beta)
    cpv_oracle(1.7,.3,beta)
}
/* A lower offer below the current promised surplus still raises wages. */
s=fesim_cpv_solve((1.5\1.7\2),1,.5,.3,.2,.05,.8)
assert(s.S[1]<fesim_cpv_contract_surplus(s,3,0))
assert(fesim_cpv_offer(s,3,0,1)==(3,1,2))
assert(fesim_cpv_offer(s,3,0,3)==(3,0,0))
/* A fully competed contract can lose current wage when moving up. */
s=fesim_cpv_solve((1.5\1.7\2),1,.5,.3,.2,.05,0)
assert(fesim_cpv_wage(s,3,2)<fesim_cpv_wage(s,2,2))
end
display "CPV independent Bellman, CTMC, and bargaining checks passed"
