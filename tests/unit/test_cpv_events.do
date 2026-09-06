version 16
clear all
set more off
quietly _fesim_load
mata:
s=fesim_cpv_solve((1.5\1.7\2),1,ln(2),ln(2)-.3,.3,.05,0)
rng=fesim_rng_init(77,1)
d=fesim_cpv_draws_init();d.index=(1,1,1)
d.values[,2]=J(4096,1,.999999)
d.values[1..12,2]=(.5\.99\.5\.99\.5\0\.5\.5\.99\.5\.99\.999999)
d.values[1..5,3]=(2.5\1.5\2.5\.5\2.5)/3
state=(2,2,1,-2,0);events=0
panel=fesim_cpv_path(s,state,1,1,3,2,1,rng,d,events,10000000)
assert(events==6)
assert(panel[,3]==J(3,1,3))
assert(panel[,6]==(2\3\3))
assert(panel[,25..27]==(0,1,0\1,0,1\0,0,0))
assert(panel[,30]==(1\0\1))
assert(panel[,33]==(0\0\1))
assert(panel[,31]==J(3,1,2))
assert(panel[,32]==(1\2\0))
assert(panel[,34]+panel[,35]==J(3,1,2))
assert(panel[1,15]<fesim_cpv_wage(s,2,2))
assert(panel[3,15]>panel[2,15])
assert(panel[2,7]==0)
flows=fesim_finalize_flows(panel[,(1,2,3,4,5,6,7,13)],3)
assert(flows[2,1]==1 & flows[2,4]==0 & flows[2,5]==2)
assert(flows[3,1]==0 & flows[3,4]==0 & flows[3,5]==0)
/* Independent continuum equation (3), away from entry-support typo. */
for(beta=0;beta<=1;beta=beta+.5) {
    previous=.
    for(n=500;n<=5000;n=n*10) {
        p=1.5:+.5*((1::n):-.5)/n
        s=fesim_cpv_solve(p,1,.5,.3,.2,.05,beta)
        q=n/4;j=3*n/4;x=p[q];y=p[j];a=.25
        if(beta==0) integral=y-x+.3/(a*.5)*(2*(y-x)-(y^2-x^2)/2)
        else integral=(y-x)/beta+a*(1-1/beta)*.5/(beta*.3)*
            ln((a+beta*.3*(2-x)/.5)/(a+beta*.3*(2-y)/.5))
        theoretical=y-(1-beta)*integral
        error=abs(fesim_cpv_wage(s,j,q)-theoretical)
        assert(error<.002)
        if(n==5000) assert(error<.0002 & error<=previous+1e-12)
        previous=error
    }
}
end
display "CPV FROZEN EVENTS, BOUNDARIES, AND CONTINUUM CONVERGENCE PASS"
