version 16.0
mata:
struct fesim_blm_draws {
    real matrix values
    real scalar index
}
struct fesim_blm_draws scalar fesim_blm_draws_init()
{
    struct fesim_blm_draws scalar d
    d.values=J(4096,3,.)
    d.index=4097
    return(d)
}
real rowvector fesim_blm_draw(struct fesim_rng_state scalar rng,
    struct fesim_blm_draws scalar d)
{
    if(d.index>4096) {
        d.values[,1]=fesim_rng_runiform(rng,"mobility_events",4096,1)
        d.values[,2]=fesim_rng_runiform(rng,"destination_draws",4096,1)
        d.values[,3]=fesim_rng_rnormal(rng,"wage_shocks",4096,1,0,1)
        d.index=1
    }
    return(d.values[d.index++,])
}
string rowvector fesim_blm_observed_names()
{
    return(tokens("workerid time firmid employed lnwage spellid tenure unemp_duration newjob from_unemp to_unemp jobtojob ntransitions"))
}
string rowvector fesim_blm_basic_names()
{
    return(tokens("worker_type_true firm_type_true wage_location_true conditional_mean_true epsilon_true lnwage_true"))
}
string rowvector fesim_blm_full_names()
{
    return(tokens("lag_lnwage_true lag_firm_type_true persistence_true move_shift_true innovation_sd_true move_probability_true moved_month_true n_ee_true"))
}
/* Worker-major monthly history, including burn-in. No period-dependent draws.
   State: worker type, actual firm, class, earnings. All workers remain employed.
   Retained snapshot m includes the move at m; tenure is zero after that move. */
real matrix fesim_blm_path(struct fesim_blm_model scalar s,
    real rowvector initial,real scalar worker,real scalar periods,
    real scalar months_per_period,real scalar burnmonths,
    struct fesim_rng_state scalar rng,struct fesim_blm_draws scalar draws)
{
    real matrix out
    real rowvector u,destination,wage
    real scalar l,k,j,y,lagy,lagk,spell,tenure,m,steps,period,counts,prob,moved
    out=J(periods,27,.)
    l=initial[1];j=initial[2];k=initial[3];y=initial[4]
    spell=1;tenure=0;counts=0;period=0
    steps=burnmonths+periods*months_per_period
    for(m=1;m<=steps;m++) {
        u=fesim_blm_draw(rng,draws)
        lagy=y;lagk=k
        prob=s.firms==1 ? 0 : fesim_blm_move_probability(y,s.mu[l,k],s.rate[l,k],s.slope[l,k])
        moved=u[1]<prob
        if(moved) {
            destination=fesim_blm_destination(s,l,k,j,u[2])
            j=destination[1];k=destination[2];spell++;tenure=0
        }
        else tenure++
        wage=fesim_blm_earnings(s,l,lagk,k,moved,lagy,u[3]);y=wage[1]
        if(m<=burnmonths) continue
        counts=counts+moved
        if(mod(m-burnmonths,months_per_period)==0) {
            period++
            out[period,1..8]=(worker,period,j,1,y,spell,tenure/months_per_period,.)
            out[period,13]=counts
            out[period,14..19]=(l,k,s.mu[l,k],wage[2],wage[3],y)
            out[period,20..27]=(lagy,lagk,wage[4],wage[5],wage[6],prob,moved,counts)
            counts=0
        }
    }
    return(out)
}
real scalar fesim_blm_simulate_to_stata(real scalar workers,real scalar firms,
    real scalar periods,real scalar start_value,string scalar time_format,
    string scalar frequency,real scalar seed,real scalar requested_seed,
    real scalar burnin,string scalar truth,real rowvector primitives,
    string rowvector inputs,string scalar preset,string scalar timing_name,
    real rowvector timers,|real scalar block_workers)
{
    struct fesim_blm_model scalar s
    struct fesim_rng_state scalar rng
    struct fesim_blm_draws scalar draws
    real matrix initial,out,flow
    real colvector worker_u,firm_u,normal_z,rows_out
    real rowvector cum,indices
    real scalar N,dt,mp,burnmonths,buildtime,simtime,i,k,l,j,first,last,row,ncols,peak,moves
    string rowvector names,types,hidden
    if(args()<16) block_workers=min((10000,max((1,floor(100000/periods)))))
    if(missing(block_workers) | block_workers<1 | block_workers!=floor(block_workers) |
        !anyof(("none","basic","full"),truth)) _error(198,"BLM writer controls invalid")
    N=fesim_output_checked_rows(workers,periods)
    dt=fesim_time_delta_years(frequency);mp=round(12*dt);burnmonths=round(12*burnin)
    if(burnin<0 | abs(12*burnin-burnmonths)>1e-8 |
        workers*(burnmonths+periods*mp)>1000000000) _error(198,"BLM monthly horizon invalid")
    if(st_nobs()!=0 | st_nvar()!=0) _error(198,"BLM writer requires empty data")
    fesim_runtime_start(timers[2])
    if(cols(inputs)==14) s=fesim_blm_load_resolved(firms,inputs)
    else s=fesim_blm_build(firms,primitives,inputs,preset)
    buildtime=fesim_runtime_stop(timers[2])
    fesim_runtime_start(timers[3])
    rng=fesim_rng_init(seed,requested_seed)
    worker_u=fesim_rng_runiform(rng,"worker_primitives",workers,1)
    firm_u=fesim_rng_runiform(rng,"initial_states",workers,1)
    normal_z=fesim_rng_rnormal(rng,"initial_states",workers,1,0,1)
    initial=J(workers,4,.)
    cum=runningsum(s.worker_weights);cum[s.L]=1
    for(i=1;i<=workers;i++) {
        l=1;while(l<s.L & worker_u[i]>=cum[l]) l++
        j=1+floor(firms*firm_u[i])
        k=1
        while(k<s.K) {
            if(j<s.first_firm[k+1]) break
            k++
        }
        initial[i,]=(l,j,k,s.mu[l,k]+s.sd[l,k]*normal_z[i])
    }
    if(any(missing(initial))) _error(430,"BLM initial earnings exceed numerical range")
    draws=fesim_blm_draws_init()
    simtime=fesim_runtime_stop(timers[3])
    names=fesim_blm_observed_names()
    types=("long","long","long","byte","double","long","double","double","byte","byte","byte","byte","long")
    if(truth!="none") {
        names=names,fesim_blm_basic_names();types=types,("byte","byte",J(1,4,"double"))
    }
    if(truth=="full") {
        names=names,fesim_blm_full_names();types=types,("double","byte",J(1,4,"double"),"byte","long")
    }
    ncols=cols(names);hidden=tokens("_blm_l _blm_k _blm_epsilon _blm_moves")
    st_addobs(N);indices=st_addvar(types,names)
    indices=st_addvar(("byte","byte","double","long"),hidden)
    last=peak=moves=0
    for(first=1;first<=workers;first=last+1) {
        last=min((workers,first+block_workers-1))
        out=J((last-first+1)*periods,27,.)
        fesim_runtime_start(timers[3])
        for(i=first;i<=last;i++) {
            row=(i-first)*periods
            out[|row+1,1\row+periods,27|]=fesim_blm_path(s,initial[i,],i,periods,mp,burnmonths,rng,draws)
        }
        simtime=simtime+fesim_runtime_stop(timers[3])
        moves=moves+sum(out[,27])
        flow=fesim_finalize_flows(out[,(1,2,3,4,5,6,7,13)],periods)
        out[,9..13]=flow
        out[,2]=out[,2]:+start_value:-1
        rows_out=((first-1)*periods+1)::(last*periods)
        st_store(rows_out,names,out[,1..ncols]);st_store(rows_out,hidden,out[,(14,15,18,27)])
        peak=max((peak,rows(out)))
    }
    st_varformat("time",time_format)
    for(i=1;i<=cols(names);i++) st_varlabel(names[i],subinstr(names[i],"_"," "))
    st_varlabel("tenure","Tenure in output-period units")
    st_varlabel("unemp_duration","Unemployment duration (always missing in employed-only BLM)")
    if(truth!="none") {
        st_varlabel("wage_location_true","Current worker-type/firm-class earnings location")
        st_varlabel("conditional_mean_true","Earnings conditional mean for last internal month")
        st_varlabel("epsilon_true","Scaled Gaussian innovation in last internal month")
        st_varlabel("lnwage_true","Realized log earnings (no additional observation error)")
    }
    if(truth=="full") {
        st_varlabel("lag_lnwage_true","Earnings one internal month before this snapshot")
        st_varlabel("lag_firm_type_true","Firm class one internal month before this snapshot")
        st_varlabel("move_probability_true","Move probability in last internal month, evaluated before shock")
        st_varlabel("moved_month_true","Actual firm move in last internal month")
        st_varlabel("n_ee_true","All actual firm moves in this output interval, including first")
    }
    fesim_blm_metadata(fesim_blm_serialize(s))
    st_matrix(timing_name,(buildtime,simtime,moves,peak,block_workers,workers*(burnmonths+periods*mp)))
    stata("sort workerid time",1);stata("isid workerid time",1)
    return(rng.master_seed)
}
/* Welford updates avoid squared-level cancellation. Rows are type/class cells;
   interval move counts are attributed to the cell at the ending snapshot. */
void fesim_blm_cells_to_stata(real scalar L,real scalar K,real scalar periods,
    string scalar cells_name,string scalar workers_name)
{
    real matrix a,c,w
    real scalar first,last,i,j,l,k,n,dy,de,N
    string colvector rn
    N=st_nobs();c=J(L*K,6,0);w=J(L,1,0);rn=J(L*K,1,"");last=0
    for(first=1;first<=N;first=last+1) {
        last=min((N,first+99999))
        a=st_data(first::last,("_blm_l","_blm_k","lnwage","_blm_epsilon","_blm_moves"))
        for(i=1;i<=rows(a);i++) {
            l=a[i,1];k=a[i,2];j=(l-1)*K+k
            c[j,1]=c[j,1]+1;n=c[j,1]
            dy=a[i,3]-c[j,2];de=a[i,4]-c[j,4]
            c[j,2]=c[j,2]+dy/n;c[j,4]=c[j,4]+de/n
            c[j,3]=c[j,3]+dy*(a[i,3]-c[j,2]);c[j,5]=c[j,5]+de*(a[i,4]-c[j,4])
            c[j,6]=c[j,6]+a[i,5]
            if(mod(first+i-2,periods)==0) w[l]=w[l]+1
        }
    }
    if(any(missing(c))) _error(430,"BLM cell moments exceed numerical range")
    for(l=1;l<=L;l++) for(k=1;k<=K;k++) {
        j=(l-1)*K+k;rn[j]="l"+strofreal(l)+"_k"+strofreal(k)
        if(c[j,1]>1) c[j,(3,5)]=sqrt(c[j,(3,5)]/(c[j,1]-1))
        else c[j,(3,5)]=J(1,2,.)
        if(c[j,1]==0) c[j,(2,4)]=J(1,2,.)
    }
    st_matrix(cells_name,c);st_matrix(workers_name,w)
    st_matrixrowstripe(cells_name,(J(L*K,1,""),rn))
    st_matrixcolstripe(cells_name,(J(6,1,""),("observations"\"lnwage_mean"\"lnwage_sd"\"innovation_mean"\"innovation_sd"\"interval_moves")))
}
end
