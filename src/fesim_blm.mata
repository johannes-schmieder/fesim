version 16.0
mata:
/* D-044: finite-type BLM-style forward model, schema 1. No RNG or data
   mutation in table construction. All tables are copied from caller inputs. */
struct fesim_blm_model {
    real scalar L, K, firms
    real rowvector worker_weights, firm_weights, counts, first_firm, x, z
    real matrix mu, sd, rate, rho, phi, slope, destination, shift, eligible, cdf
}
real scalar fesim_blm_schema_version()
{
    return(1)
}
string rowvector fesim_blm_table_keys()
{
    return(tokens("worker_weights firm_weights mean_matrix sd_matrix move_rate_matrix rho_matrix mobility_wage_matrix destination_matrix move_shift_matrix"))
}
string rowvector fesim_blm_result_keys()
{
    return(tokens("blm_worker_weights blm_firm_weights blm_mean blm_sd blm_move_rate blm_rho blm_mobility_wage blm_destination blm_move_shift blm_firm_counts blm_worker_scores blm_firm_scores blm_monthly_rho blm_eligible_destination"))
}
real matrix fesim_blm_input(string scalar name, real scalar nr, real scalar nc,
    real matrix fallback, string scalar key)
{
    real matrix a
    if(name=="-") return(fallback)
    a=st_matrix(name)
    if(rows(a)!=nr | cols(a)!=nc | any(missing(a)))
        _error(198,"BLM "+key+" has invalid dimensions or nonfinite entries")
    return(a)
}
real rowvector fesim_blm_weights(real rowvector a, string scalar key)
{
    if(any(missing(a)) | min(a)<=0) _error(198,"BLM "+key+" must be strictly positive and finite")
    a=a/max(a);a=a/sum(a)
    if(min(a)<=0) _error(198,"BLM "+key+" cannot be normalized within numerical range")
    return(a)
}
real rowvector fesim_blm_scores(real rowvector w)
{
    real rowvector z
    real scalar s
    if(cols(w)==1) return(0)
    z=invnormal(((1..cols(w)):-.5)/cols(w));z=z:-sum(w:*z)
    s=sqrt(sum(w:*z:^2))
    if(s<=0 | missing(s)) _error(198,"BLM score normalization is numerically unresolved")
    z=z/s
    if(any(missing(z))) _error(198,"BLM scores exceed numerical range")
    return(z)
}
struct fesim_blm_model scalar fesim_blm_build(real scalar firms,
    real rowvector p, string rowvector inputs, string scalar preset)
{
    struct fesim_blm_model scalar s
    real scalar l,k,h,row,remaining,i,total
    real rowvector a,quota,priority
    real colvector order
    real matrix v
    /* p: L K mu sd_worker sd_firm interaction sd_error lambda_move sorting
          rho mobility_wage origin_dependence */
    if(cols(p)!=12 | any(missing(p)) | cols(inputs)!=9 |
        !anyof(("static","dynamic"),preset)) _error(198,"Invalid BLM primitives")
    s.L=p[1];s.K=p[2];s.firms=firms
    if(min(p[1..2])<1 | max(p[1..2])>20 | any(p[1..2]:!=floor(p[1..2])) |
        missing(firms) | firms<s.K | firms!=floor(firms)) _error(198,"BLM requires 1..20 types and firms >= firm_types")
    s.worker_weights=fesim_blm_weights(fesim_blm_input(inputs[1],1,s.L,J(1,s.L,1),"worker_weights"),"worker_weights")
    s.firm_weights=fesim_blm_weights(fesim_blm_input(inputs[2],1,s.K,J(1,s.K,1),"firm_weights"),"firm_weights")
    quota=(firms-s.K)*s.firm_weights
    s.counts=1:+floor(quota)
    remaining=firms-sum(s.counts)
    order=order((-(quota-floor(quota))',(1::s.K)),(1,2))
    for(i=1;i<=remaining;i++) s.counts[order[i]]=s.counts[order[i]]+1
    s.first_firm=J(1,s.K,1)
    for(i=2;i<=s.K;i++) s.first_firm[i]=s.first_firm[i-1]+s.counts[i-1]
    s.x=fesim_blm_scores(s.worker_weights)
    s.z=fesim_blm_scores(s.counts/firms)
    v=p[3]:+p[4]*(s.x'*J(1,s.K,1)):+p[5]*(J(s.L,1,1)*s.z):+p[6]*(s.x'*s.z)
    s.mu=fesim_blm_input(inputs[3],s.L,s.K,v,"mean_matrix")
    s.sd=fesim_blm_input(inputs[4],s.L,s.K,J(s.L,s.K,p[7]),"sd_matrix")
    s.rate=fesim_blm_input(inputs[5],s.L,s.K,J(s.L,s.K,p[8]),"move_rate_matrix")
    s.rho=fesim_blm_input(inputs[6],s.L,s.K,J(s.L,s.K,p[10]),"rho_matrix")
    s.slope=fesim_blm_input(inputs[7],s.L,s.K,J(s.L,s.K,p[11]),"mobility_wage_matrix")
    v=J(s.L*s.K,s.K,.)
    for(l=1;l<=s.L;l++) {
        a=p[9]*s.x[l]*s.z
        if(any(missing(a))) _error(198,"BLM destination utilities exceed numerical range")
        a=exp(a:-max(a)):*s.counts
        for(k=1;k<=s.K;k++) v[(l-1)*s.K+k,]=a
    }
    s.destination=fesim_blm_input(inputs[8],s.L*s.K,s.K,v,"destination_matrix")
    for(l=1;l<=s.L;l++) for(k=1;k<=s.K;k++) v[(l-1)*s.K+k,]=p[12]*(s.z[k]:-s.z)
    s.shift=fesim_blm_input(inputs[9],s.L*s.K,s.K,v,"move_shift_matrix")
    if(any(missing((s.mu,s.sd,s.rate,s.rho,s.slope))) | any(missing(s.shift)) |
        min(s.sd)<0 | min(s.rate)<0 | min(s.rho)<0 | max(s.rho)>=1 |
        min(s.destination)<0) _error(198,"BLM scales/rates/weights must be nonnegative, rho in [0,1), and tables finite")
    if(preset=="static" & (any(s.rho:!=0) | any(s.slope:!=0) | any(s.shift:!=0)))
        _error(198,"BLM static requires zero persistence, wage-dependent mobility and move shifts")
    s.phi=s.rho:^(1/12)
    if(max(s.phi)>=1) _error(198,"BLM rho is too close to one to resolve monthly innovation variance")
    s.eligible=s.cdf=J(s.L*s.K,s.K,0)
    for(l=1;l<=s.L;l++) for(k=1;k<=s.K;k++) {
        row=(l-1)*s.K+k
        a=s.destination[row,]
        if(max(a)<=0) _error(198,"BLM destination rows must have positive mass")
        a=a/max(a);a=a/sum(a)
        s.destination[row,]=a
        /* Multiplication avoids subtracting almost equal cumulative masses. */
        a[k]=a[k]*(s.counts[k]-1)/s.counts[k]
        total=sum(a)
        if(total==0 & s.rate[l,k]>0 & firms>1)
            _error(198,"BLM moving cell has no eligible destination after self exclusion")
        if(total>0) a=a/total
        s.eligible[row,]=a
        s.cdf[row,]=runningsum(a)
        if(total>0) s.cdf[row,s.K]=1
    }
    return(s)
}
/* Conditional destination class and actual firm from ONE supplied uniform.
   Returns (actual firm,class); within-class moves exclude the current firm. */
real rowvector fesim_blm_destination(struct fesim_blm_model scalar s,
    real scalar l,real scalar k,real scalar current,real scalar u)
{
    real scalar row,h,left,m,offset,j
    row=(l-1)*s.K+k
    h=1
    while(h<s.K & u>=s.cdf[row,h]) h++
    left=h==1 ? 0 : s.cdf[row,h-1]
    m=s.counts[h]-(h==k)
    if(m<1 | s.eligible[row,h]<=0) _error(430,"BLM destination mass is numerically unresolved")
    offset=min((m-1,floor(m*(u-left)/s.eligible[row,h])))
    j=s.first_firm[h]+offset
    if(h==k & j>=current) j++
    return((j,h))
}
/* Stable complementary log-log probability; no arbitrary coefficient clipping. */
real scalar fesim_blm_move_probability(real scalar y,real scalar mu,
    real scalar rate,real scalar slope)
{
    real scalar logh,diff,term,h
    if(rate==0) return(0)
    diff=y-mu
    if(missing(diff)) _error(430,"BLM earnings deviation exceeds numerical range")
    term=slope*diff
    if(missing(term)) {
        if(slope==0 | diff==0) term=0
        else return(sign(slope)==sign(diff) ? 1 : 0)
    }
    logh=ln(rate)-ln(12)+term
    if(logh>ln(40)) return(1) /* exp(-40) rounds below one ULP at one. */
    if(logh < -745) return(0) /* below double subnormal resolution */
    h=exp(logh)
    if(h<1e-5) return(h*(1-h/2+h*h/6-h*h*h/24))
    return(1-exp(-h))
}
/* Deterministic one-month innovation map for independent numerical fixtures. */
real rowvector fesim_blm_earnings(struct fesim_blm_model scalar s,
    real scalar l,real scalar k,real scalar h,real scalar moved,
    real scalar y,real scalar epsilon)
{
    real scalar persistence,shift,scale,mean,innovation,next
    persistence=s.phi[l,h]*(y-s.mu[l,k])
    shift=moved*s.shift[(l-1)*s.K+k,h]
    scale=s.sd[l,h]*sqrt((1-s.phi[l,h])*(1+s.phi[l,h]))
    mean=s.mu[l,h]+persistence+shift
    innovation=scale*epsilon;next=mean+innovation
    if(any(missing((persistence,shift,scale,mean,innovation,next))))
        _error(430,"BLM earnings exceed the finite numerical range")
    return((next,mean,innovation,persistence,shift,scale))
}
real matrix fesim_blm_table(struct fesim_blm_model scalar s,real scalar i)
{
    if(i==1) return(s.worker_weights)
    if(i==2) return(s.firm_weights)
    if(i==3) return(s.mu)
    if(i==4) return(s.sd)
    if(i==5) return(s.rate)
    if(i==6) return(s.rho)
    if(i==7) return(s.slope)
    if(i==8) return(s.destination)
    if(i==9) return(s.shift)
    if(i==10) return(s.counts)
    if(i==11) return(s.x)
    if(i==12) return(s.z)
    if(i==13) return(s.phi)
    return(s.eligible)
}
string scalar fesim_blm_serialize(struct fesim_blm_model scalar s)
{
    real scalar i,j,k
    real matrix a
    string scalar out
    string rowvector keys
    keys=fesim_blm_result_keys();out="blm_v1;"
    for(i=1;i<=cols(keys);i++) {
        a=fesim_blm_table(s,i)
        out=out+keys[i]+":"+strofreal(rows(a))+"x"+strofreal(cols(a))+"="
        for(j=1;j<=rows(a);j++) for(k=1;k<=cols(a);k++) out=out+strtrim(sprintf("%24.17g",a[j,k]))+","
        out=out+";"
    }
    return(out)
}
void fesim_blm_tables_to_stata(struct fesim_blm_model scalar s,string rowvector names)
{
    real scalar i,j,k
    real matrix a
    string colvector rn,cn
    for(i=1;i<=cols(names);i++) {
        a=fesim_blm_table(s,i)
        rn=J(rows(a),1,"");cn=J(cols(a),1,"")
        for(j=1;j<=rows(a);j++) {
            if(rows(a)==s.L*s.K & (i==8 | i==9 | i==14))
                rn[j]="l"+strofreal(ceil(j/s.K))+"_k"+strofreal(mod(j-1,s.K)+1)
            else rn[j]="l"+strofreal(j)
        }
        for(k=1;k<=cols(a);k++) cn[k]=(i==1 | i==11 ? "l" : "k")+strofreal(k)
        if(rows(a)==1) rn[1]="value"
        st_matrix(names[i],a)
        st_matrixrowstripe(names[i],(J(rows(a),1,""),rn))
        st_matrixcolstripe(names[i],(J(cols(a),1,""),cn))
    }
}
struct fesim_blm_model scalar fesim_blm_load_resolved(real scalar firms,string rowvector names)
{
    struct fesim_blm_model scalar s
    real scalar i
    s.firms=firms
    s.worker_weights=st_matrix(names[1]);s.L=cols(s.worker_weights)
    s.firm_weights=st_matrix(names[2]);s.K=cols(s.firm_weights)
    s.mu=st_matrix(names[3]);s.sd=st_matrix(names[4]);s.rate=st_matrix(names[5])
    s.rho=st_matrix(names[6]);s.slope=st_matrix(names[7]);s.destination=st_matrix(names[8])
    s.shift=st_matrix(names[9]);s.counts=st_matrix(names[10]);s.x=st_matrix(names[11])
    s.z=st_matrix(names[12]);s.phi=st_matrix(names[13]);s.eligible=st_matrix(names[14])
    s.first_firm=J(1,s.K,1)
    for(i=2;i<=s.K;i++) s.first_firm[i]=s.first_firm[i-1]+s.counts[i-1]
    s.cdf=s.eligible
    for(i=1;i<=rows(s.cdf);i++) {
        s.cdf[i,]=runningsum(s.eligible[i,])
        if(sum(s.eligible[i,])>0) s.cdf[i,s.K]=1
    }
    return(s)
}
void fesim_blm_resolve_to_stata(real scalar firms, real rowvector p,
    string rowvector inputs,string scalar preset,string rowvector outputs)
{
    struct fesim_blm_model scalar s
    string scalar payload
    s=fesim_blm_build(firms,p,inputs,preset)
    fesim_blm_tables_to_stata(s,outputs)
    payload=fesim_blm_serialize(s)
    st_local("blm_model",payload)
    st_local("blm_fingerprint",strtrim(sprintf("%12.0f",hash1(payload))))
}
void fesim_blm_metadata(string scalar payload)
{
    real scalar i,n
    n=ceil(strlen(payload)/30000)
    for(i=1;i<=n;i++) st_global("_dta[fesim_blm_model_"+strofreal(i)+"]",substr(payload,(i-1)*30000+1,30000))
    st_global("_dta[fesim_blm_model_chunks]",strofreal(n))
    st_global("_dta[fesim_blm_schema]","1")
    st_global("_dta[fesim_blm_fingerprint]",strtrim(sprintf("%12.0f",hash1(payload))))
}
end
