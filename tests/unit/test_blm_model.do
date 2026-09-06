version 19.0
clear all
set more off
quietly _fesim_load
mata:
p=(2,3,3,.4,.15,.1,.2,.25,.5,0,0,0)
s=fesim_blm_build(8,p,J(1,9,"-"),"static")
assert(s.counts==(3,3,2))
assert(abs(sum(s.worker_weights:*s.x))<1e-14)
assert(abs(sum(s.counts/8:*s.z))<1e-14)
assert(abs(sum(s.counts/8:*s.z:^2)-1)<1e-14)
assert(s.phi==J(2,3,0))
/* Independent finite-firm transition calculation, including self exclusion.
   An equally spaced grid checks inverse-CDF probabilities deterministically. */
for(l=1;l<=2;l++) for(k=1;k<=3;k++) {
    origin=s.first_firm[k]
    expected=J(1,8,0)
    for(h=1;h<=3;h++) for(j=s.first_firm[h];j<s.first_firm[h]+s.counts[h];j++) {
        if(j!=origin) expected[j]=exp(.5*s.x[l]*s.z[h])
    }
    expected=expected/sum(expected)
    found=J(1,8,0)
    for(j=1;j<=20000;j++) {
        d=fesim_blm_destination(s,l,k,origin,(j-.5)/20000)
        assert(d[1]!=origin)
        found[d[1]]=found[d[1]]+1
    }
    assert(max(abs(found/20000-expected))<1/20000+1e-14)
    pm=fesim_blm_move_probability(9,s.mu[l,k],.25,0)
    assert(abs(pm-(1-exp(-.25/12)))<1e-15)
    assert(abs(sum(pm*expected)+(1-pm)-1)<1e-14)
}
/* Additive limit: every two-by-two cross difference vanishes. */
p[6]=0;add=fesim_blm_build(8,p,J(1,9,"-"),"static")
assert(abs(add.mu[1,1]-add.mu[1,3]-add.mu[2,1]+add.mu[2,3])<1e-14)
assert(abs(s.mu[1,1]-s.mu[1,3]-s.mu[2,1]+s.mu[2,3])>.1)
/* Fixed innovations independently evaluated from the published forward
   conditional-mean restriction. Firm-origin effect is allowed on moves. */
p[10..12]=(.6,-2,.05)
s=fesim_blm_build(8,p,J(1,9,"-"),"dynamic")
y=3.4;l=2;k=1
for(h=1;h<=3;h++) for(move=0;move<=1;move++) {
    e=-1.25
    w=fesim_blm_earnings(s,l,k,h,move,y,e)
    phi=exp(ln(.6)/12)
    mean=s.mu[l,h]+phi*(y-s.mu[l,k])+move*.05*(s.z[k]-s.z[h])
    variance=.2^2*(1-exp(ln(.6)/6))
    assert(abs(w[1]-(mean+sqrt(variance)*e))<1e-14)
    assert(abs(w[2]-mean)<1e-14)
    assert(abs(w[6]^2-variance)<1e-15)
}
assert(fesim_blm_move_probability(s.mu[1,1]-.3,s.mu[1,1],.25,-2)>
       fesim_blm_move_probability(s.mu[1,1]+.3,s.mu[1,1],.25,-2))
assert(fesim_blm_move_probability(1e200,0,1e200,1e200)==1)
assert(fesim_blm_move_probability(1e200,0,1e200,-1e200)==0)
assert(fesim_blm_move_probability(3,3,1e-20,0)>0)
assert(fesim_blm_move_probability(3,3,0,-2)==0)
/* Singleton and within-class moves. */
p=(1,1,3,.4,.15,0,.2,.25,0,0,0,0)
s=fesim_blm_build(2,p,J(1,9,"-"),"static")
assert(s.x==0 & s.z==0 & s.mu==3)
assert(fesim_blm_destination(s,1,1,1,0)==(2,1))
assert(fesim_blm_destination(s,1,1,2,.999999)==(1,1))
end
display "FESIM BLM MODEL PASS"
