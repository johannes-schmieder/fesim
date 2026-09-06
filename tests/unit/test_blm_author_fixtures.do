version 19.0
clear all
set more off
quietly _fesim_load
/* Compatible submodels of author m2/m4 conditional sample simulators.
   Source: tlamadon/blm-replicate 8d65ada76c15c2b8ae2cbfa291813fa8bc6d0393,
   R/m2-mixt.r and R/m4-mixt.R. No empirical data or fitted parameters used.
   These fixtures condition on given types/links. They do not assert that the
   author's arbitrary two/four-period parameters define a forward long panel. */
mata:
p=(2,2,3,.4,.15,.1,.2,.25,.5,0,0,0)
s=fesim_blm_build(8,p,J(1,9,"-"),"static")
A=(2,3\4,5);SD=(.1,.2\.3,.4);s.mu=A;s.sd=SD
/* m2: draw Y1=A(origin,type)+S(origin,type)*e1 independently of Y2.
   Author orientation firm x worker is transposed to package worker x firm. */
for(l=1;l<=2;l++) for(k=1;k<=2;k++) for(h=1;h<=2;h++) {
    y1=A[l,k]+SD[l,k]*(-.75)
    y2=A[l,h]+SD[l,h]*(1.25)
    simulated=fesim_blm_earnings(s,l,k,h,k!=h,y1,1.25)
    assert(abs(simulated[1]-y2)<1e-14)
}
/* m4: one class, stationary Gaussian AR(1) with no mover shifts.
   A2ma=A3ma=A12=A43=mu; B12=B32m=B43=phi; S12=S3m=S43=sigma*sqrt(1-phi^2),
   S2m=sigma, A2mb=A3mb=0. The paper draws Y1 backward from Y2.
   Forward and backward Gaussian constructions have the same joint mean and
   covariance; equality of these fully specifies their four-normal law. */
phi=.7;sigma=.3;mu=3
B=J(4,4,0)
B[2,2]=sigma
B[1,1]=sigma*sqrt(1-phi^2);B[1,2]=phi*sigma
B[3,2]=phi*sigma;B[3,3]=sigma*sqrt(1-phi^2)
B[4,2]=phi^2*sigma;B[4,3]=phi*sigma*sqrt(1-phi^2);B[4,4]=sigma*sqrt(1-phi^2)
forward=J(4,4,.)
for(i=1;i<=4;i++) for(j=1;j<=4;j++) forward[i,j]=sigma^2*phi^abs(i-j)
assert(max(abs(B*B'-forward))<1e-15)
/* With fixed innovations, the package forward update gives the stated law. */
p=(1,1,mu,0,0,0,sigma,0,0,phi^12,0,0)
s=fesim_blm_build(1,p,J(1,9,"-"),"dynamic")
e=(.2,-.7,1.1,.4);y=mu+sigma*e[1]
for(i=2;i<=4;i++) {
    expected=mu+phi*(y-mu)+sigma*sqrt(1-phi^2)*e[i]
    actual=fesim_blm_earnings(s,1,1,1,0,y,e[i])
    assert(abs(actual[1]-expected)<1e-14)
    y=actual[1]
}
end
display "FESIM BLM AUTHOR-MODEL FIXTURES PASS"
