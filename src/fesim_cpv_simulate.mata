version 16.0
mata:
struct fesim_cpv_draws {
    real matrix values
    real rowvector index
}
real scalar fesim_cpv_draw(struct fesim_rng_state scalar rng,
    struct fesim_cpv_draws scalar draws, real scalar component)
{
    real scalar idx
    string rowvector names
    names=("initial_states","mobility_events","destination_draws")
    idx=draws.index[component]
    if(idx>rows(draws.values)) {
        draws.values[,component]=fesim_rng_runiform(rng,names[component],4096,1)
        idx=1
    }
    draws.index[component]=idx+1
    return(draws.values[idx,component])
}
struct fesim_cpv_draws scalar fesim_cpv_draws_init()
{
    struct fesim_cpv_draws scalar d
    d.values=J(4096,3,.)
    d.index=J(1,3,4097)
    return(d)
}
real scalar fesim_cpv_wait(real scalar u, real scalar rate)
{
    return(fesim_bm_exponential_wait(u,rate))
}
/* Exact regenerative stationary initialization, including contract and tenure.
   State columns: firm, reference, spell counter, job start, unemployment start. */
real matrix fesim_cpv_initialize(struct fesim_cpv_solution scalar s,
    real scalar workers, string scalar initial,
    struct fesim_rng_state scalar rng, struct fesim_cpv_draws scalar draws)
{
    real matrix state
    real scalar i,j,q,t,age,k,events,n,u
    real rowvector offer
    n=rows(s.p); events=0
    state=J(workers,5,0)
    if(initial=="allunemployed") return(state)
    for(i=1;i<=workers;i++) {
        u=fesim_cpv_draw(rng,draws,1)
        if(u < (initial=="stationary" ? s.unemployment_rate : .5)) {
            if(initial=="stationary") state[i,5]=-
                fesim_cpv_wait(fesim_cpv_draw(rng,draws,1),s.lambda_u)
            continue
        }
        j=1+floor(n*fesim_cpv_draw(rng,draws,1)); q=0
        state[i,3]=1
        if(initial=="random") {
            state[i,1]=j
            continue
        }
        age=fesim_cpv_wait(fesim_cpv_draw(rng,draws,1),s.delta)
        t=-age;state[i,4]=t
        if(s.lambda_e>0) {
            t=t+fesim_cpv_wait(fesim_cpv_draw(rng,draws,1),s.lambda_e)
            while(t<=0) {
                events++
                if(events>10000000) _error(430,"CPV stationary initialization exceeded event budget")
                k=1+floor(n*fesim_cpv_draw(rng,draws,1))
                offer=fesim_cpv_offer(s,j,q,k)
                j=offer[1];q=offer[2]
                if(offer[3]==1) state[i,4]=t
                t=t+fesim_cpv_wait(fesim_cpv_draw(rng,draws,1),s.lambda_e)
            }
        }
        state[i,1]=j;state[i,2]=q
    }
    return(state)
}

/* One worker's exact continuous-time path. Waiting times are carried across
   output boundaries, so frequency and block size cannot change the path.
   Output: common 13, basic 5, full 17; final hidden six columns copied by writer. */
real matrix fesim_cpv_path(struct fesim_cpv_solution scalar s,
    real rowvector state, real scalar worker, real scalar ability,
    real scalar periods, real scalar dt, real scalar record,
    struct fesim_rng_state scalar rng, struct fesim_cpv_draws scalar draws,
    real scalar total_events, real scalar max_events)
{
    real matrix out
    real scalar period,t,next,endpoint,rate,j,q,spell,jobstart,ustart
    real scalar k,kind,segment,w,c,oldtime
    real rowvector counts,offer
    out=J(record ? periods : 0,35,.)
    j=state[1];q=state[2];spell=state[3];jobstart=state[4];ustart=state[5]
    t=0
    rate=j>0 ? s.delta+s.lambda_e : s.lambda_u
    next=fesim_cpv_wait(fesim_cpv_draw(rng,draws,2),rate)
    for(period=1;period<=periods;period++) {
        endpoint=period*dt
        /* EU EE UE Uoffers Eoffers rejected events transitions raises E U */
        counts=J(1,11,0)
        while(next<=endpoint) {
            segment=next-t
            counts[10+(j==0)]=counts[10+(j==0)]+segment
            t=next;total_events++
            if(total_events>max_events) _error(430,"CPV simulation exceeded event budget")
            counts[7]=counts[7]+1
            if(j==0) kind=1
            else kind=fesim_cpv_draw(rng,draws,2)<s.delta/(s.delta+s.lambda_e) ? 3 : 2
            if(kind==3) {
                counts[1]=counts[1]+1;counts[8]=counts[8]+1
                j=q=0;ustart=t
            }
            else {
                k=1+floor(rows(s.p)*fesim_cpv_draw(rng,draws,3))
                if(kind==1) {
                    counts[3]=counts[3]+1;counts[4]=counts[4]+1;counts[8]=counts[8]+1
                    j=k;q=0;spell++;jobstart=t
                }
                else {
                    counts[5]=counts[5]+1
                    offer=fesim_cpv_offer(s,j,q,k)
                    j=offer[1];q=offer[2]
                    if(offer[3]==1) {
                        counts[2]=counts[2]+1;counts[8]=counts[8]+1;spell++;jobstart=t
                    }
                    else if(offer[3]==2) counts[9]=counts[9]+1
                    else counts[6]=counts[6]+1
                }
            }
            rate=j>0 ? s.delta+s.lambda_e : s.lambda_u
            oldtime=next
            next=t+fesim_cpv_wait(fesim_cpv_draw(rng,draws,2),rate)
            if(next<=oldtime | missing(next)) _error(430,"CPV event clock lost precision")
        }
        counts[10+(j==0)]=counts[10+(j==0)]+endpoint-t
        t=endpoint
        if(record) {
            out[period,1..4]=(worker,period,(j>0 ? j : .),j>0)
            out[period,8]=j==0 ? (t-ustart)/dt : .
            out[period,13]=counts[8]
            out[period,16]=ability
            out[period,20]=ability*s.B/s.discount
            if(j>0) {
                w=ability*fesim_cpv_wage(s,j,q)
                c=ability*fesim_cpv_contract_surplus(s,j,q)
                if(w<=0 | missing(w) | missing(c)) _error(430,"CPV scaled contract is invalid")
                out[period,5..7]=(ln(w),spell,(t-jobstart)/dt)
                out[period,14..15]=(ln(w),w)
                out[period,17..19]=(s.p[j],ability*s.p[j],q)
                out[period,21..23]=(ability*s.B/s.discount+c,
                    ability*(s.B/s.discount+s.S[j]),(q>0 ? ability*s.S[max((1,q))] : 0))
                out[period,24]=ability*s.B/s.discount+out[period,23]
            }
            out[period,25..35]=counts
        }
    }
    state=(j,q,spell,jobstart-t,ustart-t)
    return(out)
}

string rowvector fesim_cpv_observed_names()
{
    return(("workerid","time","firmid","employed","lnwage","spellid",
        "tenure","unemp_duration","newjob","from_unemp","to_unemp",
        "jobtojob","ntransitions"))
}
string rowvector fesim_cpv_basic_names()
{
    return(("lnwage_true","contract_wage_true","worker_ability_true",
        "firm_productivity_true","match_productivity_true"))
}
string rowvector fesim_cpv_full_names()
{
    return(("bargaining_firm_true","unemployment_value_true",
        "employment_value_true","full_match_value_true","reference_surplus_true",
        "reference_value_true","n_eu_true","n_ee_true","n_ue_true",
        "n_unemployment_offers_true","n_employed_offers_true",
        "n_rejected_offers_true","n_events_true","ntransitions_true",
        "n_renegotiations_true","employment_exposure_true","unemployment_exposure_true"))
}
real scalar fesim_cpv_simulate_to_stata(
    real scalar workers, real scalar firms, real scalar periods,
    real scalar start_value, string scalar time_format,
    string scalar frequency, real scalar seed, real scalar requested_seed,
    string scalar initial, real scalar burnin, string scalar truth,
    real rowvector primitives, real scalar random_firms,
    string scalar solver_name, string scalar firms_name,
    string scalar timing_name, real rowvector timers,
    | real scalar block_workers, real scalar max_events)
{
    struct fesim_cpv_solution scalar s
    struct fesim_rng_state scalar rng
    struct fesim_cpv_draws scalar draws
    real matrix state,out,discarded,flows,table
    real colvector ability,p,quantile,rows_out
    real rowvector one,indices
    real scalar i,first,last,N,dt,events,burn_events,solve_time,sim_time,peak_rows
    real scalar ncols,row
    string rowvector names,hidden,types,solver_names,firm_names
    if(args()<18) block_workers=min((10000,max((1,floor(100000/periods)))))
    if(args()<19) max_events=10000000
    if(cols(primitives)!=10 | block_workers<1 | block_workers!=floor(block_workers) |
        max_events<1 | max_events>10000000 | max_events!=floor(max_events) |
        !anyof(("stationary","random","allunemployed"),initial) |
        !anyof(("none","basic","full"),truth) | burnin<0) _error(3300,"CPV handler controls are invalid")
    N=fesim_output_checked_rows(workers,periods)
    dt=fesim_time_delta_years(frequency)
    rng=fesim_rng_init(seed,requested_seed)
    fesim_runtime_start(timers[2])
    quantile=((1::firms):-.5)/firms
    if(random_firms) quantile=sort(fesim_rng_runiform(rng,"firm_primitives",firms,1),1)
    p=primitives[2]:+(primitives[3]-primitives[2])*quantile
    s=fesim_cpv_solve(p,primitives[1],primitives[4],primitives[5],primitives[6],primitives[7],primitives[8])
    solve_time=fesim_runtime_stop(timers[2])
    fesim_runtime_start(timers[3])
    ability=J(workers,1,1)
    if(primitives[9]>0) ability=exp(fesim_rng_rnormal(rng,"worker_primitives",workers,1,0,primitives[9]):-primitives[9]^2/2)
    if(any(missing(ability)) | min(ability)<=0) _error(430,"CPV ability draws are not positive finite values")
    draws=fesim_cpv_draws_init()
    state=fesim_cpv_initialize(s,workers,initial,rng,draws)
    burn_events=0
    if(burnin>0) for(i=1;i<=workers;i++) {
        one=state[i,]
        discarded=fesim_cpv_path(s,one,i,ability[i],1,burnin,0,rng,draws,burn_events,max_events)
        state[i,]=one
    }
    /* Keep component buffers across all workers and blocks. */
    sim_time=fesim_runtime_stop(timers[3])
    names=fesim_cpv_observed_names()
    types=("long","long","long","byte","double","long","double","double",
        "byte","byte","byte","byte","long")
    if(truth!="none") {
        names=names,fesim_cpv_basic_names();types=types,J(1,5,"double")
    }
    if(truth=="full") {
        names=names,fesim_cpv_full_names();types=types,J(1,17,"double")
    }
    ncols=cols(names)
    hidden=("_cpv_eu","_cpv_ee","_cpv_ue","_cpv_e","_cpv_u","_cpv_reneg")
    st_addobs(N)
    indices=st_addvar(types,names)
    indices=st_addvar(J(1,6,"double"),hidden)
    events=peak_rows=0;last=0
    for(first=1;first<=workers;first=last+1) {
        last=min((workers,first+block_workers-1))
        out=J((last-first+1)*periods,35,.)
        fesim_runtime_start(timers[3])
        for(i=first;i<=last;i++) {
            one=state[i,];row=(i-first)*periods
            out[|row+1,1\row+periods,35|]=fesim_cpv_path(s,one,i,ability[i],periods,dt,1,rng,draws,events,max_events)
        }
        sim_time=sim_time+fesim_runtime_stop(timers[3])
        flows=fesim_finalize_flows(out[,(1,2,3,4,5,6,7,13)],periods)
        out[,9..13]=flows
        out[,2]=out[,2]:+start_value:-1
        rows_out=((first-1)*periods+1)::(last*periods)
        st_store(rows_out,names,out[,1..ncols])
        st_store(rows_out,hidden,out[,(25,26,27,34,35,33)])
        peak_rows=max((peak_rows,rows(out)))
    }
    st_varformat("time",time_format)
    st_varlabel("lnwage","Observed log contract wage")
    st_varlabel("tenure","Tenure in output-period units")
    st_varlabel("unemp_duration","Unemployment duration in output-period units")
    for(i=1;i<=cols(names);i++) {
        if(st_varlabel(names[i])=="") st_varlabel(names[i],subinstr(names[i],"_"," "))
    }
    solver_names=("b","p_min","p_max","lambda_u","lambda_e","delta","discount",
        "beta","unemployment_value","unemployment_rate","employment_rate",
        "finite_job_to_job_rate","finite_renegotiation_rate","bellman_scaled_residual",
        "minimum_surplus","minimum_entry_wage","firm_count")
    st_matrix(solver_name,(s.b\min(s.p)\max(s.p)\s.lambda_u\s.lambda_e\s.delta\s.discount\s.beta\s.B/s.discount\s.unemployment_rate\1-s.unemployment_rate\s.ee_rate\s.renegotiation_rate\s.residual\min(s.S)\min(s.entry_wage)\firms))
    st_matrixrowstripe(solver_name,(J(cols(solver_names),1,""),solver_names'))
    st_matrixcolstripe(solver_name,("","value"))
    table=((1::firms),quantile,s.p,s.S,s.entry_wage,s.mass,workers*s.mass,s.mass/(1-s.unemployment_rate))
    firm_names=("firm_id","offer_quantile","productivity","full_surplus","entry_wage","expected_mass","expected_workers","expected_share")
    st_matrix(firms_name,(mean(table)',colmin(table)',colmax(table)'))
    st_matrixrowstripe(firms_name,(J(8,1,""),firm_names'))
    st_matrixcolstripe(firms_name,(J(3,1,""),("mean"\"min"\"max")))
    st_matrix(timing_name,(solve_time,sim_time,events,0,peak_rows,block_workers))
    st_global("_dta[fesim_cpv_schema]","1")
    st_global("_dta[fesim_cpv_firm_mode]",random_firms ? "random" : "quantile")
    stata("sort workerid time",1)
    stata("isid workerid time",1)
    return(rng.master_seed)
}

void fesim_cpv_results_to_stata(string scalar solver_name,string scalar flow_name,
    real scalar dt,real scalar ue,real scalar eu,real scalar ee)
{
    real rowvector counts
    real matrix report
    real scalar first,last,N,unemployed
    last=0;N=st_nobs();counts=J(1,6,0);unemployed=0
    for(first=1;first<=N;first=last+1) {
        last=min((N,first+99999))
        counts=counts+colsum(st_data(first::last,("_cpv_eu","_cpv_ee","_cpv_ue","_cpv_e","_cpv_u","_cpv_reneg")))
        unemployed=unemployed+sum(st_data(first::last,"employed"):==0)
    }
    report=J(5,4,.)
    report[,1]=st_matrix(solver_name)[(10\4\6\12\13),1]
    report[1,2]=counts[5]/(counts[4]+counts[5]);report[1,3]=unemployed/N
    if(counts[5]>0) report[2,2]=counts[3]/counts[5]
    if(counts[4]>0) report[(3\4\5),2]=counts[(1,2,6)]'/counts[4]
    report[2..4,3]=(ue\eu\ee);report[2..4,4]=report[2..4,3]/dt
    st_matrix(flow_name,report)
    st_matrixrowstripe(flow_name,(J(5,1,""),("unemployment_share"\"ue"\"eu"\"ee"\"renegotiation")))
    st_matrixcolstripe(flow_name,(J(4,1,""),("theory"\"event"\"observed"\"observed_per_year")))
}
end
