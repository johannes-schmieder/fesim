{smcl}
{* *! version 1.2.0-rc.1 06sep2026}{...}
{.-}
help for {cmd:fesim} {right:(Johannes F. Schmieder)}
{.-}
{vieweralsosee "fesim design" "DESIGN.md"}{...}
{title:Title}

{p 4 8}{cmd:fesim} {hline 2} linked employer-employee panel simulation{p_end}

{title:Syntax available in 1.2.0-rc.1}

{p 8 12}{cmd:fesim version}{p_end}
{p 8 12}{cmd:fesim list}{p_end}
{p 8 12}{cmd:fesim presets} [{it:dgp}]{p_end}
{p 8 12}{cmd:fesim describe} {it:dgp} [{cmd:, preset(}{it:name}{cmd:)}]{p_end}

{title:Simulation syntax}

{p 8 12}{cmd:fesim} [{cmd:, dgp(}{it:name}{cmd:)} {cmd:preset(}{it:name}{cmd:)}
{cmd:workers(}{it:#}{cmd:)} {cmd:firms(}{it:#}{cmd:)} {cmd:periods(}{it:#}{cmd:)}
{cmd:frequency(}{it:year|quarter|month}{cmd:)} {cmd:start(}{it:string}{cmd:)}
{cmd:seed(}{it:#}{cmd:)} {cmd:initial(}{it:name}{cmd:)} {cmd:burnin(}{it:#}{cmd:)}
{cmd:jobrule(}{it:name}{cmd:)} {cmd:truth(}{it:name}{cmd:)}
{cmd:connectivity(}{it:name}{cmd:)} {cmd:network(}{it:name}{cmd:)}
{cmd:parameters(}{it:string}{cmd:)}
{cmd:report} {cmd:noreport} {cmd:clear}]{p_end}

{pstd}
The {cmd:dgp(akm)} presets {cmd:simple}, {cmd:stylized}, and {cmd:germany_chk_2002_2009}, plus the {cmd:dgp(akmpaygap)} presets {cmd:simple} and {cmd:cck2016}, are available. {cmd:dgp(akmsimple)} and {cmd:dgp(akmempirical)} are convenience aliases for the first two AKM designs. Model-specific scalars remain exclusively inside {cmd:parameters()}; named options are common controls only. Canonical {cmd:dgp(bm) preset(simple)} is also available, with alias {cmd:dgp(bmsimple)}. The CPV family adds {cmd:simple} and {cmd:heterogeneous} presets.

{title:Description}

{pstd}
{cmd:fesim} generates worker-period linked employer-employee panels using a common Stata/Mata engine. The package separates the DGP, mobility engine, calibration preset, and observation scheme. The {cmd:akm/simple} defaults are a stylized teaching and testing design. The {cmd:akm/stylized} defaults exercise a monthly empirical-mobility engine but are explicitly uncalibrated; the alias name {cmd:akmempirical} does not imply a paper or country calibration. The distinct {cmd:akm/germany_chk_2002_2009} preset targets selected Card-Heining-Kline 2002--2009 West German AKM wage-dispersion and sorting moments. {cmd:akmpaygap} codes men as group 0 and women as group 1, reports men-minus-women gaps, and separates worker composition, firm sorting, and group premium schedules. Its {cmd:cck2016} preset targets selected Card-Cardoso-Kline group and decomposition moments.

{pstd}
{cmd:fesim list} shows canonical DGP families, presets, aliases, and implementation status. {cmd:fesim presets} lists presets for all families or one requested DGP. {cmd:fesim describe} resolves case-insensitive names to canonical lowercase names. For example, {cmd:akmsimple} resolves to {cmd:dgp(akm) preset(simple)} and reports the same canonical configuration.

{pstd}
Configuration metadata is implemented for all ten public presets. The simple and stylized presets retain their documented defaults. The Germany preset defaults to {cmd:workers(10000)}, {cmd:firms(1000)}, eight annual periods beginning in 2002, {cmd:initial(random)}, and a five-year monthly burn-in. All presets default to {cmd:truth(basic)}, {cmd:connectivity(keep)}, {cmd:network(random)}, and {cmd:report}. Omitting {cmd:seed()} records {cmd:current}; configuration resolution itself never changes the RNG state.

For the simple AKM contract, {cmd:initial(stationary)} uses the exact interval transition matrix over unemployment and firms and initializes job age from the stationary geometric distribution. {cmd:initial(random)} uses employment probability 0.5, attraction-weighted firm assignment, tenure zero, and requires {cmd:burnin()} of at least one period. {cmd:initial(allunemployed)} is a diagnostic start.

{pstd}
The simple model parameters accepted in {cmd:parameters()} are {cmd:mu}, {cmd:sd_worker}, {cmd:sd_firm}, {cmd:sd_error}, {cmd:firm_size_sd}, {cmd:p_eu}, {cmd:p_ee}, {cmd:p_ue}, and {cmd:wage_trend}. Registered defaults are 3, .40, .15, .20, 1, .08, .12, .60, and 0, respectively. Standard deviations are nonnegative; transition probabilities are bounded in [0,1], with {cmd:p_eu} and {cmd:p_ee} strictly below 1 and summing to less than 1. These model parameters do not have separate named options in {cmd:v0.1.0}.

{pstd}
The stylized empirical-mobility preset reuses the wage/size parameters and adds {cmd:rho_z_alpha}, {cmd:rho_q_psi}; annual log-hazard intercepts {cmd:kappa_eu}, {cmd:kappa_ee}, {cmd:kappa_ue}; worker, firm, tenure, and unemployment-duration slopes; and destination coefficients {cmd:theta_sort}, {cmd:theta_quality}, {cmd:theta_up}, and {cmd:theta_down}. Type {cmd:fesim describe akmempirical} for all defaults and bounds. The intercepts anchor zero-covariate intensities to the simple annual probabilities; all remaining coefficients are transparent stress-design choices, not fitted estimates.

{pstd}
The CHK-targeted preset sets {cmd:sd_worker=.357}, {cmd:sd_firm=.230}, and {cmd:sd_error=.135}, and fits only {cmd:theta_sort=2.2} to the employment-weighted worker--establishment covariance target {cmd:.0205}. It returns these four source moments in {cmd:r(targets)}. The other mobility coefficients, including all transition hazards and duration slopes, remain stylized D-026 carryovers and must not be described as German-calibrated. Its classification is {cmd:targeted}; any model-parameter override changes it to {cmd:targeted_modified}.

{pstd}
The pay-gap parameters are {cmd:female_share}, {cmd:mu_m}, {cmd:mu_f}, {cmd:sd_worker_m}, {cmd:sd_worker_f}, {cmd:premium_intercept_m}, {cmd:premium_intercept_f}, {cmd:premium_loading_m}, {cmd:premium_loading_f}, {cmd:premium_deviation_sd_m}, {cmd:premium_deviation_sd_f}, {cmd:sd_error_m}, {cmd:sd_error_f}, {cmd:firm_size_sd}, the six group annual probabilities {cmd:p_eu_*}, {cmd:p_ee_*}, and {cmd:p_ue_*}, the group destination tilts {cmd:group_sort_*}, the worker-type destination tilts {cmd:worker_sort_*}, and {cmd:wage_trend_m}, {cmd:wage_trend_f}. Type {cmd:fesim describe akmpaygap, preset(simple)} or {cmd:preset(cck2016)} for defaults and bounds. Firm premiums equal a group intercept plus a group loading on common standard-normal firm surplus plus a population-mean-zero group deviation.

{pstd}
The pay-gap destination rule combines common firm attraction with {cmd:exp((group_sort_g + worker_sort_g * type) * surplus)}. Five worker types use scores {cmd:(-2,-1,0,1,2)/sqrt(2)}. Group EU/EE/UE probabilities are converted from annual units to the output interval. Only {cmd:network(random)} is registered for this DGP. The CCK-inspired preset is {cmd:targeted}, or {cmd:targeted_modified} after a model-parameter override; it is not a reproduction of CCK's empirical normalization or full estimation procedure.

{title:Network stress designs}

{pstd}
{cmd:network(random)} is the frozen compatibility default. {cmd:network(blocks)} independently assigns workers and firms to balanced communities using a dedicated RNG stream. Origin-free initialization and UE destinations use the worker's permanent home community; EE destinations use the current firm's community. The same-block destination weight is multiplied by {cmd:exp(block_log_bonus)}. The network scalars {cmd:block_count} and {cmd:block_log_bonus} remain inside {cmd:parameters()}; their defaults are 4 and {cmd:ln(9)}. Setting {cmd:block_log_bonus} to zero exactly nests the random destination rule. Network parameters supplied under an irrelevant design are rejected.

{pstd}
{cmd:network(bridges)} uses strict ordinary blocks: initialization and UE stay in the worker's home block, and ordinary EE destinations stay in the current firm's block. It then redirects the destination, but not the occurrence or timing, of an exact set of retained-sample EE events. The minimum plan is 1-2, 2-3, ..., {cmd:block_count-1}-{cmd:block_count}; extra bridges cycle over those adjacent pairs. Distinct bridge workers are selected reproducibly by the isolated network-design priority among eligible workers. {cmd:bridge_count} defaults dynamically to {cmd:block_count-1} and may be raised inside {cmd:parameters()}. At least two firms per block are required. The command fails if eligible retained EE events cannot complete the exact plan. {cmd:block_log_bonus} is inapplicable and is rejected when explicitly supplied.

{pstd}
{cmd:network(ladder)} is a reduced-form EE-destination design. All public AKM presets rank firms by persistent firm effect {cmd:psi_j} using tied percentile midranks. Candidate firms within {cmd:ladder_band} of the origin rank are lateral; lower and higher candidates outside that band are downward and upward. Defaults are {cmd:ladder_down_share=.10}, {cmd:ladder_lateral_share=.20}, {cmd:ladder_up_share=.70}, and {cmd:ladder_band=.10}. Shares are renormalized over directions with positive ordinary destination mass, while the selected DGP's ordinary weights are retained within direction. The current firm remains excluded. Initialization, UE destinations, event timing, and wages are unchanged, and the existing destination uniform is reused. All four controls remain inside {cmd:parameters()}. This is not a structural Burdett-Mortensen or revealed-preference equilibrium.

{title:Time and rate units}

{pstd}
{cmd:frequency()} selects abstract Stata annual, quarterly, or monthly output periods and the corresponding {cmd:%ty}, {cmd:%tq}, or {cmd:%tm} time format. Simple-AKM transition inputs are annual probabilities. The stylized and Germany presets always advance monthly from annual continuous hazards and sample the requested output snapshots. Pay-gap probabilities are annual and jointly converted to the requested output interval; its internal clock is the output period. Quarterly or monthly output never reinterprets annual inputs as per-period values.

{title:Simulation output}

{pstd}
The returned dataset is sorted by {cmd:workerid time} and satisfies {cmd:isid workerid time}. Required variables are {cmd:workerid}, {cmd:time}, {cmd:firmid}, {cmd:employed}, {cmd:lnwage}, {cmd:spellid}, {cmd:tenure}, {cmd:newjob}, {cmd:from_unemp}, {cmd:to_unemp}, {cmd:jobtojob}, and {cmd:ntransitions}. With {cmd:truth(basic)} or {cmd:truth(full)}, the simple preset also generates {cmd:alpha_true}, {cmd:psi_true}, {cmd:time_true}, {cmd:xb_true}, {cmd:match_true}, {cmd:epsilon_true}, and {cmd:lnwage_true}. {cmd:truth(none)} suppresses those columns without changing any economic draw or common output value.

{pstd}
The stylized and Germany presets additionally report {cmd:unemp_duration}; it and {cmd:tenure} use output-period units. {cmd:ntransitions} counts all monthly events since the prior snapshot and may exceed one. {cmd:r(durations)} reports counts, means, sample standard deviations, and p10/p50/p90 in years. Under {cmd:truth(full)}, {cmd:worker_type_true} gives the five-point mobility type and {cmd:firm_quality_true} gives current-firm quality on employed rows. Under {cmd:network(blocks)} or {cmd:network(bridges)}, full truth also adds permanent {cmd:worker_block_true} and current-employer {cmd:firm_block_true}; the latter is missing outside employment. {cmd:network(bridges)} adds {cmd:nbridges_imposed} under every truth mode; it counts design-imposed bridges for that worker and output interval.

{pstd}
{cmd:alpha_true} is the persistent worker effect. {cmd:psi_true} is the persistent current-firm effect and is missing outside employment. {cmd:time_true} is {cmd:wage_trend} times elapsed retained-sample years. {cmd:xb_true} and {cmd:match_true} are zero in the simple preset. {cmd:epsilon_true} is the idiosyncratic wage shock, and {cmd:lnwage_true} equals the observed employed log wage because the simple preset has no measurement error.

{pstd}
Pay-gap output always adds {cmd:group}, labeled 0 Men and 1 Women. Basic truth uses the same common truth names, with {cmd:psi_true} equal to the observed group's premium schedule. Full truth additionally adds {cmd:firm_surplus_true}, {cmd:psi_male_true}, and {cmd:psi_female_true} at the observed firm; these are missing outside employment. The common surplus is population standard normal and is not restandardized in the realized finite firm sample.

{pstd}
Simulation results are returned through {cmd:r()} scalars for dimensions, realized flows, network diagnostics, and stage runtimes; macros for the resolved DGP, preset, timing, RNG, network design, and version; and matrices {cmd:r(parameters)}, {cmd:r(moments)}, {cmd:r(targets)}, {cmd:r(network)}, and {cmd:r(leaveout)}. {cmd:akm/stylized} and {cmd:akm/germany_chk_2002_2009} also return {cmd:r(durations)}. Pay-gap routes additionally return {cmd:r(group_moments)}, {cmd:r(group_targets)}, {cmd:r(decomposition)}, and {cmd:r(decomposition_targets)}. {cmd:network(bridges)} returns {cmd:r(bridges_imposed)} and the exact eight-column {cmd:r(bridges)} ledger: bridge ID, worker ID, output period, internal period, source firm, target firm, source block, and target block. Component moments and applicable targets are computed even under {cmd:truth(none)}. Dataset characteristics record the version, canonical DGP and requested alias, preset and calibration class, command, actual master seed and RNG, frequency and internal clock, employer rule, burn-in, connectivity rule, network design, truth mode, and normalization reference.

{title:Connectivity}

{pstd}
The observed bipartite graph contains ever-employed workers, active firms, and one edge per unique observed worker-firm match. Never-employed workers and inactive firms are excluded. Largest-component observation, worker, and firm shares respectively use employed observations, ever-employed workers, and active firms as denominators. Ties are resolved by employed observations, then workers, then firms, then the lowest component identifier.

The observed firm mobility graph is undirected. A link is an unordered firm pair in an adjacent-output transition with {cmd:jobtojob==1}; its weight is the number of those observed direct moves pooling directions. Active firms incident to no link are counted as firms with no movers. Link-weight p10, p50, p90, and p99 use Stata's default percentile convention. These summaries do not claim leave-out connectedness.

{pstd}
{cmd:connectivity(keep)} leaves the generated panel unchanged. {cmd:connectivity(largest)} retains all periods, including nonemployment, for workers in the selected component, so the returned panel remains balanced. {cmd:r(network)} has {cmd:generated} and {cmd:returned} columns and 21 stable rows: 13 component diagnostics followed by {cmd:firms_no_movers}, {cmd:firm_links}, four edge-weight percentiles, {cmd:articulation_firms}, and {cmd:graph_bridge_links}. An articulation firm or graph-bridge link is one whose deletion increases the component count in the distinct undirected observed firm graph; link weights do not affect these classifications. Mobility rows are recomputed after {cmd:largest}. They are descriptive and are not leave-one-worker, leave-one-match, or KSS diagnostics. Under {cmd:largest}, {cmd:r(N_workers)} is the retained count; the requested worker count remains in {cmd:r(parameters)}. A generated panel without employment rejects {cmd:largest}.

{pstd}
The separate 19-row, one-column {cmd:r(leaveout)} matrix audits the current returned panel's largest unique-match bipartite component without filtering the panel. Worker deletion removes a worker's complete observed history; {cmd:worker_cut_vertices} counts articulation workers in the base component, and the {cmd:worker_set_*} rows describe the deterministic largest component after articulation-worker pruning repeats to a robust fixed point or emptiness. Match deletion removes one complete worker-firm edge while retaining the audited firms; {cmd:vulnerable_matches_largest} and {cmd:vulnerable_matches_worker_set} count deletions that separate firms. An edge that only isolates a stayer-worker is not vulnerable. The final {cmd:worker_out_connected} and {cmd:match_out_connected} flags audit the retained worker set; no separate match-connected sample is constructed.

{title:Safety and RNG behavior}

{pstd}
Discovery and configuration resolution do not alter data or Stata's RNG state. The simulation parser validates recognized options before any possible clear or random draw. If data are loaded and {cmd:clear} is absent, it exits without modifying them. A failing simulation restores the prior dataset and RNG state. With {cmd:seed(#)}, the caller RNG state is unchanged; without it, one integer draw supplies the recorded master seed and advances the caller sequence exactly once. {cmd:connectivity(force)} has no accepted scientific generation rule and fails before replacement or draws.

{title:Registered designs}

{p2colset 9 24 26 2}{...}
{p2col:{cmd:akm}}Presets {cmd:simple}, {cmd:stylized}, and {cmd:germany_chk_2002_2009} are qualified; aliases are {cmd:akmsimple} and {cmd:akmempirical}.{p_end}
{p2col:{cmd:akmpaygap}}Qualified presets {cmd:simple} and {cmd:cck2016}; no convenience alias.{p_end}
{p2col:{cmd:bm}}Preset {cmd:simple}; alias {cmd:bmsimple}; canonical homogeneous wage-posting model with a stylized calibration.{p_end}
{p2colreset}{...}

{title:Stored results}

{pstd}{cmd:fesim version} returns:{p_end}
{synoptset 22 tabbed}{...}
{synopt:{cmd:r(version)}}package version{p_end}
{synopt:{cmd:r(status)}}release status{p_end}
{synopt:{cmd:r(api_level)}}discovery API level{p_end}

{pstd}{cmd:fesim list} returns:{p_end}
{synopt:{cmd:r(dgps)}}canonical DGP names{p_end}
{synopt:{cmd:r(aliases)}}registered aliases{p_end}
{synopt:{cmd:r(qualified)}}qualified DGP/preset names; currently {cmd:akm/simple akm/stylized akm/germany_chk_2002_2009 akmpaygap/simple akmpaygap/cck2016 bm/simple}{p_end}
{synopt:{cmd:r(n_dgps)}}number of canonical registered DGP families{p_end}

{pstd}{cmd:fesim presets} returns {cmd:r(dgps)} when listing all families; with a DGP, it returns {cmd:r(dgp)}, {cmd:r(dgp_alias)}, {cmd:r(presets)}, and {cmd:r(aliases)}.{p_end}

{pstd}{cmd:fesim describe} returns:{p_end}
{synopt:{cmd:r(dgp)}}canonical DGP{p_end}
{synopt:{cmd:r(dgp_alias)}}requested lowercase name{p_end}
{synopt:{cmd:r(preset)}}resolved preset{p_end}
{synopt:{cmd:r(title)}}design title{p_end}
{synopt:{cmd:r(calibration_class)}}calibration classification{p_end}
{synopt:{cmd:r(status)}}implementation status{p_end}
{synopt:{cmd:r(frequencies)}}registered output frequencies{p_end}
{synopt:{cmd:r(jobrules)}}registered observation rules{p_end}
{synopt:{cmd:r(config_schema)}}configuration-schema identifier, when available{p_end}
{synopt:{cmd:r(config)}}stable canonical default serialization, when available{p_end}
{synopt:{cmd:r(config_sources)}}source of each resolved field, when available{p_end}
{synopt:{cmd:r(parameters)}}scalar parameter matrix with value, default, lower, and upper columns{p_end}

{synopt:{cmd:r(observed_variables)}}observed output inventory{p_end}
{synopt:{cmd:r(truth_basic_variables)}}basic truth additions{p_end}
{synopt:{cmd:r(truth_full_variables)}}further full truth additions{p_end}
{synopt:{cmd:r(conditional_variables)}}conditional network fields and inclusion rules{p_end}
{synopt:{cmd:r(initial_modes)}}supported initialization modes{p_end}
{synopt:{cmd:r(networks)}}supported network designs{p_end}
{synopt:{cmd:r(source_note)}}scientific source or stylized provenance{p_end}
{synopt:{cmd:r(target_scope)}}limits of target/calibration claims{p_end}
{synopt:{cmd:r(parameter_units)}}semicolon-delimited name=unit entries{p_end}

{pstd}Numeric common controls also accept the legacy {cmd:parameters()} route.
Prefer named options; supplying the same control through both routes is rejected.
Pay-gap network scalar rows are reserved and do not enable nonrandom designs.
Within v1, existing defaults and output semantics are compatibility commitments;
removal or semantic changes require a major version. Numerical fixes that change
seeded output must be disclosed.{p_end}

{pstd}A successful simulation returns:{p_end}
{synoptset 38 tabbed}{...}
{synopt:{cmd:r(N)}}returned worker-period observations{p_end}
{synopt:{cmd:r(N_workers)}}returned workers; after {cmd:connectivity(largest)}, the retained count{p_end}
{synopt:{cmd:r(N_firms)}}requested firm population{p_end}
{synopt:{cmd:r(N_firms_active)}}firms observed active in the returned panel{p_end}
{synopt:{cmd:r(periods)}}retained periods per returned worker{p_end}
{synopt:{cmd:r(employment_rate)}}returned-sample employment share{p_end}
{synopt:{cmd:r(p_eu_realized)}}observed employment-to-nonemployment rate{p_end}
{synopt:{cmd:r(p_ue_realized)}}observed nonemployment-to-employment rate{p_end}
{synopt:{cmd:r(p_ee_realized)}}observed direct employer-change rate{p_end}
{synopt:{cmd:r(bridges_imposed)}}exact design-imposed bridge count; zero outside {cmd:network(bridges)}{p_end}
{synopt:{cmd:r(components)}}components in the returned observed graph{p_end}
{synopt:{cmd:r(largest_component_obs_share)}}returned graph's largest employed-observation share{p_end}
{synopt:{cmd:r(largest_component_worker_share)}}returned graph's largest ever-employed-worker share{p_end}
{synopt:{cmd:r(largest_component_firm_share)}}returned graph's largest active-firm share{p_end}
{synopt:{cmd:r(runtime_total)}}simulation plus post-simulation diagnostic seconds{p_end}
{synopt:{cmd:r(runtime_solve)}}solve-stage seconds; zero for simple AKM{p_end}
{synopt:{cmd:r(runtime_simulate)}}population, mobility, wage, write, and flow seconds{p_end}
{synopt:{cmd:r(runtime_output)}}graph, retained-truth, and common-moment seconds{p_end}
{synopt:{cmd:r(parameters)}}resolved value/default/bound matrix; requested dimensions remain here{p_end}
{synopt:{cmd:r(moments)}}common realized and truth moment rows{p_end}
{synopt:{cmd:r(targets)}}target, realized, difference, and relative-difference columns{p_end}
{synopt:{cmd:r(network)}}generated and returned graph-diagnostic columns{p_end}
{synopt:{cmd:r(leaveout)}}KSS-aligned worker-set and complete-match vulnerability audit{p_end}
{synopt:{cmd:r(durations)}}year-valued tenure and unemployment-duration distribution; empirical AKM presets{p_end}
{synopt:{cmd:r(bridges)}}exact bridge-event ledger; {cmd:network(bridges)} only{p_end}
{synopt:{cmd:r(group_moments)}}17 by 2 men/women counts, wage/effect moments, surplus moments, and realized flows; pay-gap only{p_end}
{synopt:{cmd:r(group_targets)}}same shape as {cmd:r(group_moments)}; CCK target rows where applicable{p_end}
{synopt:{cmd:r(decomposition)}}nine by three exact total/worker/firm/sorting/schedule/time/residual decomposition{p_end}
{synopt:{cmd:r(decomposition_targets)}}male-, female-, and symmetric-reference target matrix{p_end}
{synopt:{cmd:r(dgp)}, {cmd:r(dgp_alias)}, {cmd:r(preset)}}canonical identity and requested alias{p_end}
{synopt:{cmd:r(seed)}, {cmd:r(rng)}}actual master seed and component-stream RNG{p_end}
{synopt:{cmd:r(network_design)}}resolved random, blocks, bridges, or ladder destination design{p_end}
{synopt:{cmd:r(frequency)}, {cmd:r(internal_clock)}}output and internal timing{p_end}
{synopt:{cmd:r(command)}, {cmd:r(version)}, {cmd:r(reference)}}scientific command and package metadata{p_end}
{synopt:{cmd:r(group_coding)}, {cmd:r(gap_direction)}}pay-gap group and sign conventions{p_end}
{synopt:{cmd:r(surplus_normalization)}}pay-gap common-surplus normalization{p_end}

{title:Canonical Burdett-Mortensen model}

{pstd}
{cmd:dgp(bm)} (alias {cmd:bmsimple}) solves the homogeneous-worker,
common-productivity wage-posting equilibrium. The model is exact; defaults are
stylized and do not claim empirical calibration. The six primitive defaults in
{cmd:parameters()} are {cmd:b .4 p 1 lambda_u 1 lambda_e .5 delta .2 r .05}.
{cmd:b} is the unemployment flow payoff; {cmd:p} is productivity. The four rates
are continuous annual rates, strictly positive and at most 1000. Require
{cmd:p>b} and a positive solved reservation wage. Unresolved numerical support or
residuals fail explicitly. Firm wages use deterministic midpoint offer quantiles;
{cmd:parameters(random_firms 1)} requests random quantiles. This flag is 0 or 1.

{pstd}
Defaults are 10000 workers, 500 firms, 10 annual periods, {cmd:initial(stationary)},
and {cmd:burnin(0)}. BM burn-in is in continuous years and may be fractional;
{cmd:initial(random)} requires positive burn-in. {cmd:initial(allunemployed)} is
also available. Firm offers are uniform; employed workers accept only strictly
higher wages. Use {cmd:network(random)}, {cmd:jobrule(end)}, and
{cmd:connectivity(keep)} or {cmd:connectivity(largest)}. Maximum worker and firm
counts are 10 million and one million. Each horizon is at most 100000 years and
each burn-in/retained stage has a hard 10-million-event budget. Exceeding a guard
restores caller data and RNG. There is no public raw-event output or solve-only
interface. Output blocks preserve random draws and retain no full-population
event ledger.

{pstd}
{cmd:truth(basic)} adds {cmd:lnwage_true}, {cmd:posted_wage_true}, and
{cmd:productivity_true}; they are missing while unemployed. Full truth adds
reservation and worker values, finite and continuum firm quantities, all
interval event/acceptance/rejection counts, and employment/unemployment exposure
in years. Wages in the common panel are logs; posted wages and productivity are
levels. Public tenure and unemployment duration use output-period units. The
first interval's exact counts appear in full truth while common backward flows
remain missing at the first observation. BM has no artificial AKM worker effects.

{pstd}
{cmd:r(solver)} is the 22-row named primitive/equilibrium/residual table.
{cmd:r(bm_flows)} has rows {cmd:unemployment_share ue eu ee} and columns
{cmd:theory event observed observed_per_year}. Theory uses the original finite
economy (the continuum EE hazard is separately in {cmd:r(solver)}). Event rates
divide counts by exact at-risk years; observed rates use adjacent endpoints.
{cmd:observed_per_year} divides probability by interval years; it is not a hazard
estimate. {cmd:r(bm_firms)} gives unweighted mean, minimum, and maximum of each
named firm diagnostic. Firm summaries/theory describe the original economy;
realized rates, common moments, and durations describe the returned worker panel,
including after largest-component filtering. Runtime diagnostics include
{cmd:r(bm_events)}, {cmd:r(bm_peak_block_events)}, {cmd:r(bm_peak_block_rows)}, and
{cmd:r(bm_block_workers)}. Common parameters, moments, network, leaveout, durations,
metadata, and solve/simulate/output timings remain available.

{title:Cahuc-Postel-Vinay-Robin bargaining}

{pstd}
{cmd:dgp(cpv)} has {cmd:preset(simple)} (homogeneous workers) and
{cmd:preset(heterogeneous)} (mean-one lognormal worker ability). Both have
heterogeneous firm productivity and the original CPV sequential bargaining
protocol. These are stylized designs, not an empirical replication.

{pstd}
Defaults inside {cmd:parameters()} are {cmd:b 1 p_min 1.5 p_max 2 lambda_u .5
lambda_e .3 delta .2 r .05 beta .5 sd_worker 0 random_firms 0}.
The heterogeneous preset changes {cmd:sd_worker} to .4. Firm productivity
is uniform over the specified positive support; equal endpoints are allowed.
Quantiles are midpoint values, or sorted independent uniforms with
{cmd:random_firms 1}. Worker ability scales all wages, values and production.
Common rates imply no ability sorting. {cmd:beta} lies in [0,1];
{cmd:lambda_e} may be zero. Other rates and {cmd:b} are positive.
All rates are at most 1000. Every finite-firm surplus and entry wage must
be positive; invalid economies fail transactionally without clipping.

{pstd}
Both presets default to 10000 workers, 500 firms, ten annual periods,
{cmd:initial(stationary)} and {cmd:burnin(0)}. Stationary starts draw the joint
employer, bargaining reference and tenure distribution. Random starts use
half employment, uniform firms, entry contracts and zero ages, and require
positive burn-in in continuous years. All-unemployed starts have zero age.
Only {cmd:network(random)}, {cmd:jobrule(end)}, and
{cmd:connectivity(keep|largest)} are supported. Resource limits are 10 million
workers, 1 million firms, 2147483647 rows, and 100000 years per horizon;
initialization, burn-in and retained simulation each have a 10-million-event guard.

{pstd}
A more productive rival induces a direct move. A lower or equal rival can
raise the incumbent contract; self contacts are null. Raises do not reset
tenure or count as transitions. A direct upward move can cut today's wage.
At {cmd:beta 1}, wages equal match productivity and incumbent raises vanish.
At {cmd:beta 0}, the protocol reduces to sequential auctions.

{pstd}
Basic truth contains {cmd:lnwage_true contract_wage_true worker_ability_true
firm_productivity_true match_productivity_true}. Full truth adds reference
firm/surplus/value, unemployment/employment/full-productivity values, exact
EU/EE/UE, offers, rejected offers, renegotiations, events, transitions and
E/U exposure in years. Reference firm zero denotes unemployment. Worker
ability remains defined while unemployed; job attributes are missing then.
Productivity and contract wages are structural objects, not AKM firm effects.

{pstd}
{cmd:r(solver)} is a 17-row CPV value/residual diagnostic;
{cmd:r(cpv_firms)} gives eight firm objects summarized by mean/min/max.
{cmd:r(cpv_flows)} separates finite theoretical hazards, exact event/exposure
rates, endpoint probabilities and descriptive endpoint probabilities per year.
Its fifth row is renegotiation, with missing endpoint columns. Theory and
{cmd:r(cpv_events)} describe the generated economy; realized diagnostics
are recomputed after largest-component filtering. All diagnostics are
available with {cmd:truth(none)}. Type {cmd:fesim describe cpv} for the exact
variable inventory. The LaTeX manual derives the finite solver and histories.


{title:BLM-style worker and firm types}

{p 4 4 2}
{cmd:dgp(blm)} supports {cmd:preset(static)} (default) and {cmd:preset(dynamic)}.
All workers remain employed. Worker types are permanent; each actual firm has a
permanent class. Firms in the same class are distinct employers. These are
flexible forward simulation designs following BLM restrictions, with illustrative
package parameters; they do not reproduce the Swedish calibration or estimate BLM.

{p 4 4 2}
Defaults are 10,000 workers, 500 firms, six worker types (L), ten firm classes (K),
ten annual snapshots and {cmd:initial(random) burnin(20)}. Random starts draw a
worker type, a uniform actual employer and a cell-normal wage, with zero tenure.
Burn-in is in years aligned to whole months; zero is allowed. No exact joint
stationary initializer is provided, and a 20-year burn-in is not a convergence
guarantee. Only {cmd:network(random)}, {cmd:jobrule(end)} and
{cmd:connectivity(keep|largest)} are supported.

{p 4 4 2}
Scalar recipes inside {cmd:parameters()} are {cmd:worker_types 6 firm_types 10
mu 3 sd_worker .4 sd_firm .15 interaction .1 sd_error .2 lambda_move .25
sorting .5 rho 0 mobility_wage 0 origin_dependence 0} for static. Dynamic changes
{cmd:rho} to .6, {cmd:mobility_wage} to -2 and {cmd:origin_dependence} to .05.
L and K must be integers from 1 to 20 and firms() must be at least K.
Positive worker/class weights default to uniform. Each class gets one firm;
remaining firms use largest remainders with class-index ties.

{p 4 4 2}
Worker scores x and class scores z are normal midquantiles, centered and scaled
using worker probabilities and actual finite class shares. Singleton scores are
zero. Cell earnings location is {cmd:mu + sd_worker*x + sd_firm*z + interaction*x*z}.
The static additive case sets {cmd:interaction 0}. Destination class weights are
actual class firm counts times {cmd:exp(sorting*x*z)}; actual firms are uniform
within class. The current actual firm is excluded and probabilities renormalized.
Within-class moves count as EE moves. A one-firm economy cannot move.

{p 4 4 2}
The internal clock is monthly. From current earnings y and origin cell (l,k),
move probability is {cmd:1-exp(-lambda[l,k]*exp(g[l,k]*(y-mu[l,k]))/12)}.
Choose movement/destination before the next Gaussian shock. With next class h,
new earnings equal {cmd:mu[l,h] + phi[l,h]*(y-mu[l,k]) + moved*C[l,k,h]
+ sd[l,h]*sqrt(1-phi[l,h]^2)*epsilon}, where epsilon is standard normal and
{cmd:phi=rho^(1/12)}. Dynamic default C is .05 times origin minus destination
score. Static requires phi, g and C to be zero. Zeroing the three dynamic
controls reproduces the static paths exactly at the same seed. No extra
measurement-error state is added.

{p 4 4 2}
Optional matrix settings also appear as name/value pairs in {cmd:parameters()}:
the value is an existing Stata matrix name, copied without altering it. Inputs are
{cmd:worker_weights} (1 by L), {cmd:firm_weights} (1 by K), {cmd:mean_matrix},
{cmd:sd_matrix}, {cmd:move_rate_matrix}, {cmd:rho_matrix},
{cmd:mobility_wage_matrix} (each L by K), and {cmd:destination_matrix} and
{cmd:move_shift_matrix} (each L*K by K). For three-index tables, row (l-1)*K+k
is worker type l and origin class k; columns are destination classes.
Destination values are class masses BEFORE excluding the current actual firm.

{p 4 4 2}
All entries must be finite. Worker/class weights must be positive; scales,
intensities and destination weights may be zero; annual rho must lie in [0,1).
Destination rows require positive mass and a moving cell requires an eligible
alternative after self exclusion. Static rejects nonzero dynamic tables.
Explicit matrices conflict with their scalar recipes: mean/mu+sd_worker+sd_firm+
interaction, sd/sd_error, move_rate/lambda_move, destination/sorting, rho/rho,
mobility_wage/mobility_wage, move_shift/origin_dependence.

{p 4 4 2}
Basic truth adds {cmd:worker_type_true firm_type_true wage_location_true
conditional_mean_true epsilon_true lnwage_true}. Log-wage truth is the realized
wage; the conditional mean and innovation refer to the last internal month.
Full truth adds {cmd:lag_lnwage_true lag_firm_type_true persistence_true
move_shift_true innovation_sd_true move_probability_true moved_month_true n_ee_true}.
Those lags and probabilities refer to ONE MONTH before the snapshot, not the
previous annual/quarterly output. {cmd:n_ee_true} counts all interval moves,
including the first interval. Common flow flags retain first/last missing boundaries.
BLM does not fabricate additive worker/firm effects or a population AKM projection.

{p 4 4 2}
Returned tables: {cmd:r(blm_worker_weights)}, {cmd:r(blm_firm_weights)},
{cmd:r(blm_mean)}, {cmd:r(blm_sd)}, {cmd:r(blm_move_rate)}, {cmd:r(blm_rho)},
{cmd:r(blm_mobility_wage)}, {cmd:r(blm_destination)}, {cmd:r(blm_move_shift)},
{cmd:r(blm_firm_counts)}, {cmd:r(blm_worker_scores)}, {cmd:r(blm_firm_scores)},
{cmd:r(blm_monthly_rho)} and {cmd:r(blm_eligible_destination)} describe the
original economy. {cmd:r(blm_cells_generated)} and {cmd:r(blm_cells)} contain
counts, wage/innovation means and SDs, and interval moves by ending cell before
and after sample filtering. {cmd:r(blm_workers)} contains worker probabilities
and generated/returned counts. {cmd:r(parameters)} remains a numeric scalar table.
Full value provenance is {cmd:r(blm_model)} and numbered dataset characteristics
{cmd:_dta[fesim_blm_model_1]}, etc.; {cmd:fesim_blm_model_chunks} gives their count.
The short hash1 fingerprint is a convenience; full values are authoritative.

{p 4 4 2}
Resource guards allow at most 2,147,483,647 observations and one billion total
worker-months including burn-in. Temporary output blocks target 100,000 rows,
unless one worker has more periods. {cmd:r(blm_peak_block_rows)},
{cmd:r(blm_block_workers)} and {cmd:r(blm_worker_months)} report realized scope.
All finite-table checks precede replacement; a later numerical failure restores
caller data/RNG. Type labels are arbitrary, and graph connectivity alone does not
establish BLM mixture identification. See the manual's BLM appendix and
{browse "https://doi.org/10.3982/ECTA15722":Bonhomme, Lamadon and Manresa (2019)}.

{title:Examples}

{pstd}
Each simulation example creates its own synthetic data and wraps the block in
{cmd:preserve}/{cmd:restore}, so it can be copied into a do-file without replacing
the caller's dataset. Every simulation supplies {cmd:seed()}. The clickable link
runs the entire marked block through {cmd:fesim_run}, which also restores the
caller's data.

{space 2}{hline 8} {it:Example 1 - Inspect designs and presets} {hline 24}
{cmd}{...}
          preserve
{* example_start - discovery}{...}
          fesim version
          fesim list
          fesim presets akm
          fesim presets bm
          fesim describe AKMSIMPLE
          fesim describe bm, preset(simple)
          return list
{* example_end}{...}
          restore
{txt}{...}
{space 2}{hline 76}
{space 2}{it:({stata fesim_run discovery using fesim.sthlp:click to run})}

{space 2}{hline 8} {it:Example 2 - Generate and inspect a simple AKM panel} {hline 12}
{cmd}{...}
          preserve
{* example_start - simulate}{...}
          clear
          fesim, dgp(akmsimple) workers(500) firms(30) periods(8) ///
              seed(12345) parameters(sd_worker .45 p_ee .10) ///
              truth(basic) connectivity(keep) noreport clear
          matrix fesim_example_moments = r(moments)
          describe
          summarize lnwage alpha_true psi_true if employed
          matrix list fesim_example_moments
          matrix drop fesim_example_moments
{* example_end}{...}
          restore
{txt}{...}
{space 2}{hline 76}
{space 2}{it:({stata fesim_run simulate using fesim.sthlp:click to run})}

{space 2}{hline 8} {it:Example 3 - Simulate and estimate an AKM model} {hline 15}
{cmd}{...}
          preserve
{* example_start - estimate}{...}
          clear
          fesim, workers(500) firms(30) periods(6) seed(24680) ///
              truth(none) connectivity(largest) noreport clear
          areg lnwage i.workerid i.time if employed, ///
              absorb(firmid) vce(cluster workerid)
{* example_end}{...}
          restore
{txt}{...}
{space 2}{hline 76}
{space 2}{it:({stata fesim_run estimate using fesim.sthlp:click to run})}

{space 2}{hline 8} {it:Example 4 - Run the stylized mobility engine} {hline 17}
{cmd}{...}
          preserve
{* example_start - stylized}{...}
          clear
          fesim, dgp(akmempirical) workers(400) firms(40) periods(6) ///
              seed(314159) truth(full) connectivity(keep) noreport clear
          matrix fesim_example_durations = r(durations)
          summarize employed lnwage tenure unemp_duration
          matrix list fesim_example_durations
          matrix drop fesim_example_durations
{* example_end}{...}
          restore
{txt}{...}
{space 2}{hline 76}
{space 2}{it:({stata fesim_run stylized using fesim.sthlp:click to run})}

{space 2}{hline 8} {it:Example 5 - Inspect the Germany-targeted moments} {hline 13}
{cmd}{...}
          preserve
{* example_start - germany}{...}
          clear
          fesim, dgp(akm) preset(germany_chk_2002_2009) ///
              workers(500) firms(50) periods(8) seed(271828) ///
              truth(full) noreport clear
          matrix list r(targets)
          matrix list r(durations)
{* example_end}{...}
          restore
{txt}{...}
{space 2}{hline 76}
{space 2}{it:({stata fesim_run germany using fesim.sthlp:click to run})}

{space 2}{hline 8} {it:Example 6 - Generate a block-network stress design} {hline 11}
{cmd}{...}
          preserve
{* example_start - blocks}{...}
          clear
          fesim, dgp(akmsimple) network(blocks) workers(300) ///
              firms(24) periods(6) seed(13579) truth(full) ///
              parameters(block_count 4 block_log_bonus 2.1972245773362196) ///
              noreport clear
          tabulate worker_block_true firm_block_true if employed
{* example_end}{...}
          restore
{txt}{...}
{space 2}{hline 76}
{space 2}{it:({stata fesim_run blocks using fesim.sthlp:click to run})}

{space 2}{hline 8} {it:Example 7 - Impose exact bridges across blocks} {hline 17}
{cmd}{...}
          preserve
{* example_start - bridges}{...}
          clear
          fesim, dgp(akm) preset(simple) network(bridges) ///
              workers(400) firms(40) periods(8) seed(246813) ///
              burnin(4) truth(full) connectivity(keep) ///
              parameters(block_count 4 p_eu .02 p_ee .60 p_ue .80) ///
              noreport clear
          list workerid time firmid worker_block_true firm_block_true ///
              if nbridges_imposed, noobs abbreviate(20)
          matrix list r(bridges)
{* example_end}{...}
          restore
{txt}{...}
{space 2}{hline 76}
{space 2}{it:({stata fesim_run bridges using fesim.sthlp:click to run})}

{space 2}{hline 8} {it:Example 8 - Direct employer changes up a firm ladder} {hline 10}
{cmd}{...}
          preserve
{* example_start - ladder}{...}
          clear
          fesim, dgp(akmsimple) network(ladder) workers(500) ///
              firms(50) periods(8) seed(161803) truth(full) ///
              parameters(p_ee .30) noreport clear
          sort workerid time
          by workerid: generate double psi_change = ///
              psi_true - psi_true[_n-1] if jobtojob
          summarize psi_change if jobtojob
{* example_end}{...}
          restore
{txt}{...}
{space 2}{hline 76}
{space 2}{it:({stata fesim_run ladder using fesim.sthlp:click to run})}

{space 2}{hline 8} {it:Example 9 - Inspect a pay-gap decomposition} {hline 17}
{cmd}{...}
          preserve
{* example_start - paygap}{...}
          clear
          fesim, dgp(akmpaygap) preset(cck2016) workers(500) ///
              firms(50) periods(8) burnin(5) seed(97531) ///
              truth(full) noreport clear
          matrix list r(group_moments)
          matrix list r(group_targets)
          matrix list r(decomposition)
          matrix list r(decomposition_targets)
{* example_end}{...}
          restore
{txt}{...}
{space 2}{hline 76}
{space 2}{it:({stata fesim_run paygap using fesim.sthlp:click to run})}

{space 2}{hline 8} {it:Example 10 - Simulate the canonical BM model} {hline 16}
{cmd}{...}
          preserve
{* example_start - bm}{...}
          clear
          fesim, dgp(bm) workers(500) firms(50) periods(5) ///
              seed(12345) truth(full) ///
              parameters(b .4 p 1 lambda_u 1 lambda_e .5 delta .2 r .05) ///
              noreport clear
          matrix list r(solver)
          matrix list r(bm_flows)
          matrix list r(bm_firms)
{* example_end}{...}
          restore
{txt}{...}
{space 2}{hline 76}
{space 2}{it:({stata fesim_run bm using fesim.sthlp:click to run})}

{space 2}{hline 8} {it:Example 11 - Simulate CPV bargaining} {hline 8}
{cmd}{...}
          preserve
{* example_start - cpv}{...}
          clear
          fesim, dgp(cpv) workers(1000) firms(100) periods(5) seed(12345) truth(full) noreport clear
          matrix list r(solver)
          matrix list r(cpv_flows)
          matrix list r(cpv_firms)
{* example_end}{...}
          restore
{txt}{...}
{space 2}{hline 76}
{space 2}{it:({stata fesim_run cpv using fesim.sthlp:click to run})}

{space 2}{hline 8} {it:Example 12 - Add heterogeneous workers} {hline 8}
{cmd}{...}
          preserve
{* example_start - cpv_heterogeneous}{...}
          clear
          fesim, dgp(cpv) preset(heterogeneous) workers(1000) firms(100) periods(5) seed(12345) truth(full) noreport clear
          summarize worker_ability_true firm_productivity_true contract_wage_true
{* example_end}{...}
          restore
{txt}{...}
{space 2}{hline 76}
{space 2}{it:({stata fesim_run cpv_heterogeneous using fesim.sthlp:click to run})}

{space 2}{hline 8} {it:Example 13 - Inspect incumbent raises and wage cuts} {hline 8}
{cmd}{...}
          preserve
{* example_start - cpv_paths}{...}
          fesim, dgp(cpv) workers(1000) firms(100) periods(120) ///
              frequency(month) seed(20260908) truth(full) ///
              parameters(beta .15) noreport clear
          generate double year=(time-tm(2000m1)+1)/12
          by workerid: generate byte cut=jobtojob==1 & n_ee_true==1 & ///
              n_eu_true==0 & n_ue_true==0 & lnwage<lnwage[_n-1]
          by workerid: generate byte raise=_n>1 & employed & ///
              spellid==spellid[_n-1] & lnwage>lnwage[_n-1]+1e-12
          by workerid: egen byte has_cut=max(cut)
          by workerid: egen byte has_raise=max(raise)
          quietly levelsof workerid if has_cut & has_raise, local(candidates)
          local first : word 1 of `candidates'
          local second : word 2 of `candidates'
          assert "`second'"!=""
          generate double wage=cond(employed,contract_wage_true,0)
          local panel=0
          foreach id in `first' `second' {
              local ++panel
              quietly levelsof year if workerid==`id' & newjob==1, local(boundaries)
              twoway (connected wage year if workerid==`id', ///
                  msize(vtiny) lcolor(navy) mcolor(navy)) ///
                  (scatter wage year if workerid==`id' & raise, ///
                  msymbol(T) mcolor(orange)) ///
                  (scatter wage year if workerid==`id' & cut, ///
                  msymbol(D) mcolor(maroon)), ///
                  xline(`boundaries', lcolor(gs12) lpattern(dot)) ///
                  title("Worker `id'") xtitle("Years") ytitle("Contract wage") ///
                  legend(order(1 "Monthly wage" 2 "Within-job raise" ///
                  3 "Wage cut on direct move") cols(1) size(small)) ///
                  name(fesim_cpv_path`panel', replace)
          }
          graph combine fesim_cpv_path1 fesim_cpv_path2, cols(2) ///
              note("Dotted lines mark observed new jobs. Zero denotes unemployment.") ///
              xsize(10) ysize(5) name(fesim_cpv_paths, replace)
{* example_end}{...}
          restore
{txt}{...}
{space 2}{hline 76}
{space 2}{it:({stata fesim_run cpv_paths using fesim.sthlp:click to run})}

{space 2}{hline 8} {it:Example 14 - Plot within-firm wage dispersion} {hline 8}
{cmd}{...}
          preserve
{* example_start - cpv_dispersion}{...}
          fesim, dgp(cpv) preset(heterogeneous) workers(6000) firms(100) ///
              periods(3) seed(20260909) truth(full) noreport clear
          keep if employed & time==2002
          graph box contract_wage_true if mod(firmid,10)==0, ///
              over(firmid, label(labsize(small))) nooutsides ///
              title("A. Wage dispersion within selected firms") ///
              ytitle("Contract wage") name(fesim_cpv_box, replace)
          generate double efficiency_wage=contract_wage_true/worker_ability_true
          twoway scatter efficiency_wage firm_productivity_true, ///
              msymbol(Oh) msize(vtiny) mcolor(navy%25) ///
              title("B. Dispersion after removing worker ability") ///
              xtitle("Firm productivity per efficiency unit") ///
              ytitle("Wage / worker ability") name(fesim_cpv_normalized, replace)
          graph combine fesim_cpv_box fesim_cpv_normalized, cols(2) ///
              xsize(10) ysize(4.5) name(fesim_cpv_dispersion, replace)
{* example_end}{...}
          restore
{txt}{...}
{space 2}{hline 76}
{space 2}{it:({stata fesim_run cpv_dispersion using fesim.sthlp:click to run})}

{space 2}{hline 8} {it:Example 15 - Compare bargaining power} {hline 8}
{cmd}{...}
          preserve
{* example_start - cpv_bargaining}{...}
          tempfile comparisons
          foreach beta in 0 .5 1 {
              fesim, dgp(cpv) workers(4000) firms(100) periods(5) ///
                  seed(20260910) truth(full) parameters(beta `beta') noreport clear
              matrix list r(cpv_flows)
              keep if employed & time==2004
              generate double bargaining=`beta'
              keep bargaining firmid firm_productivity_true contract_wage_true
              if `beta'!=0 append using `comparisons'
              save `comparisons', replace
          }
          twoway (kdensity contract_wage_true if bargaining==0, lcolor(maroon)) ///
              (kdensity contract_wage_true if bargaining==.5, lcolor(navy)) ///
              (kdensity contract_wage_true if bargaining==1, lcolor(teal)), ///
              legend(order(1 "Beta = 0" 2 "Beta = 0.5" 3 "Beta = 1") cols(1)) ///
              title("A. Worker wage distributions") xtitle("Contract wage") ///
              ytitle("Kernel density") name(fesim_cpv_density, replace)
          collapse (mean) contract_wage_true (first) firm_productivity_true, ///
              by(bargaining firmid)
          twoway (line contract_wage_true firm_productivity_true if bargaining==0, ///
              sort lcolor(maroon)) (line contract_wage_true firm_productivity_true ///
              if bargaining==.5, sort lcolor(navy)) ///
              (line contract_wage_true firm_productivity_true if bargaining==1, ///
              sort lcolor(teal)), legend(order(1 "Beta = 0" 2 "Beta = 0.5" ///
              3 "Beta = 1") cols(1)) title("B. Mean wages at each firm") ///
              xtitle("Firm productivity") ytitle("Mean contract wage") ///
              name(fesim_cpv_mean, replace)
          graph combine fesim_cpv_density fesim_cpv_mean, cols(2) ///
              xsize(10) ysize(4.5) name(fesim_cpv_bargaining, replace)
{* example_end}{...}
          restore
{txt}{...}
{space 2}{hline 76}
{space 2}{it:({stata fesim_run cpv_bargaining using fesim.sthlp:click to run})}

{space 2}{hline 8} {it:Example 16 - Fit an AKM-style wage projection} {hline 8}
{cmd}{...}
          preserve
{* example_start - cpv_akm}{...}
          clear
          fesim, dgp(cpv) preset(heterogeneous) workers(1000) firms(50) periods(6) seed(12345) connectivity(largest) truth(full) noreport clear
          areg lnwage i.firmid i.time if employed, absorb(workerid)
{* example_end}{...}
          restore
{txt}{...}
{space 2}{hline 76}
{space 2}{it:({stata fesim_run cpv_akm using fesim.sthlp:click to run})}

{space 2}{hline 8} {it:Example 17 - Plot a descriptive mover event study} {hline 8}
{cmd}{...}
          preserve
{* example_start - cpv_movers}{...}
          fesim, dgp(cpv) preset(heterogeneous) workers(5000) firms(100) ///
              periods(10) seed(20260911) truth(full) noreport clear
          * Official Stata AKM-style projection; not structural productivity recovery.
          areg lnwage i.firmid i.time if employed, absorb(workerid)
          * Select the first observed interval with exactly one direct EE and no EU/UE.
          generate double move_time=time if jobtojob==1 & n_ee_true==1 & ///
              n_eu_true==0 & n_ue_true==0
          by workerid: egen double first_move=min(move_time)
          generate double event_time=time-first_move
          by workerid: egen byte destination=max(cond(event_time==0, ///
              ceil(4*firmid/100),.))
          keep if inrange(event_time,-2,2) & employed
          by workerid: keep if _N==5
          assert _N>0
          collapse (mean) lnwage (count) workers=workerid, by(event_time destination)
          list event_time destination workers, noobs sepby(destination)
          twoway (connected lnwage event_time if destination==1, lcolor(gs7)) ///
              (connected lnwage event_time if destination==2, lcolor(teal)) ///
              (connected lnwage event_time if destination==3, lcolor(navy)) ///
              (connected lnwage event_time if destination==4, lcolor(maroon)), ///
              xline(-.5, lpattern(dash) lcolor(gs10)) xlabel(-2(1)2) ///
              legend(order(1 "Destination Q1" 2 "Destination Q2" ///
              3 "Destination Q3" 4 "Destination Q4") cols(2) size(small)) ///
              xtitle("Years relative to first selected direct move") ///
              ytitle("Mean log wage") ///
              note("Balanced employed windows; descriptive selected-mover averages.") ///
              xsize(9) ysize(5) name(fesim_cpv_movers, replace)
{* example_end}{...}
          restore
{txt}{...}
{space 2}{hline 76}
{space 2}{it:({stata fesim_run cpv_movers using fesim.sthlp:click to run})}


{space 2}{hline 8} {it:Example 18 - Simulate static earnings interactions} {hline 8}
{cmd}{...}
          preserve
{* example_start - blm_static}{...}
          clear
          fesim, dgp(blm) workers(1000) firms(60) periods(5) seed(12345) truth(basic) noreport clear
          matrix list r(blm_mean)
          matrix list r(blm_cells)
          collapse (mean) lnwage, by(worker_type_true firm_type_true)
          twoway contour lnwage worker_type_true firm_type_true, heatmap ///
              title("Static BLM cell means") xtitle("Firm class") ytitle("Worker type")
{* example_end}{...}
          restore
{txt}{...}
{space 2}{hline 76}
{space 2}{it:({stata fesim_run blm_static using fesim.sthlp:click to run})}

{space 2}{hline 8} {it:Example 19 - Simulate persistence and wage-dependent mobility} {hline 8}
{cmd}{...}
          preserve
{* example_start - blm_dynamic}{...}
          clear
          fesim, dgp(blm) preset(dynamic) workers(1000) firms(60) periods(24) ///
              frequency(month) seed(12345) truth(full) noreport clear
          assert abs(lnwage-conditional_mean_true-epsilon_true)<1e-12
          matrix list r(blm_cells)
          summarize lnwage persistence_true move_shift_true move_probability_true
{* example_end}{...}
          restore
{txt}{...}
{space 2}{hline 76}
{space 2}{it:({stata fesim_run blm_dynamic using fesim.sthlp:click to run})}

{space 2}{hline 8} {it:Example 20 - Supply custom type-cell matrices} {hline 8}
{cmd}{...}
          preserve
{* example_start - blm_matrices}{...}
          clear
          tempname M S D
          matrix `M'=(2,3,4\3,3.2,3.5)
          matrix `S'=(.1,.2,.3\.3,.2,.1)
          matrix `D'=(1,2,3\2,1,3\1,1,4\3,2,1\3,1,2\4,1,1)
          fesim, dgp(blm) workers(1000) firms(60) periods(5) seed(54321) truth(full) ///
              parameters(worker_types 2 firm_types 3 mean_matrix `M' sd_matrix `S' ///
              destination_matrix `D') noreport clear
          matrix list r(blm_mean)
          matrix list r(blm_eligible_destination)
{* example_end}{...}
          restore
{txt}{...}
{space 2}{hline 76}
{space 2}{it:({stata fesim_run blm_matrices using fesim.sthlp:click to run})}

{space 2}{hline 8} {it:Example 21 - Fit an additive approximation} {hline 8}
{cmd}{...}
          preserve
{* example_start - blm_akm}{...}
          clear
          fesim, dgp(blm) workers(1200) firms(40) periods(8) seed(12345) ///
              parameters(interaction .25) connectivity(largest) truth(full) noreport clear
          areg lnwage i.firmid i.time, absorb(workerid)
          * This is a descriptive additive projection of nonlinear cell means.
{* example_end}{...}
          restore
{txt}{...}
{space 2}{hline 76}
{space 2}{it:({stata fesim_run blm_akm using fesim.sthlp:click to run})}

{space 2}{hline 8} {it:Example 22 - Plot wages around observed firm changes} {hline 8}
{cmd}{...}
          preserve
{* example_start - blm_movers}{...}
          clear
          fesim, dgp(blm) preset(dynamic) workers(2000) firms(60) periods(8) ///
              seed(63721) truth(full) noreport clear
          by workerid (time): generate long firstmove=time if jobtojob==1
          by workerid: egen long event=min(firstmove)
          generate int event_time=time-event
          keep if inrange(event_time,-2,2)
          collapse (mean) lnwage conditional_mean_true, by(event_time)
          twoway connected lnwage conditional_mean_true event_time, ///
              xline(0) xlabel(-2(1)2) xtitle("Years from first observed move") ///
              ytitle("Mean log earnings") title("Descriptive mover window") ///
              legend(order(1 "Realized wages" 2 "Conditional mean"))
{* example_end}{...}
          restore
{txt}{...}
{space 2}{hline 76}
{space 2}{it:({stata fesim_run blm_movers using fesim.sthlp:click to run})}

{title:Limitations}

{pstd}
Version 1.2.0-rc.1 exposes all ten registered presets. The Germany preset targets wage-component dispersions and sorting only; its hazards and durations are not German-calibrated. The CCK-inspired preset targets selected group moments and the male-reference firm decomposition under the package's standard-normal surplus normalization; it does not reproduce CCK's empirical normalization or full estimation. The BM preset implements the homogeneous-worker, common-productivity equilibrium with stylized primitives; worker heterogeneity and heterogeneous firm productivity are outside its scope. {cmd:connectivity(force)} has no accepted scientific design.

{pstd}
The supported minimum is Stata 19. Current 1.2.0-rc.1 exact-source qualification covers Stata/MP 19 on macOS Apple Silicon. The released v0.1.0 was additionally qualified on Windows x86-64. No cross-version or cross-platform bitwise claim is made.

{pstd}
CPV does not implement minimum wages, free entry, amenities, shocks, endogenous
ability sorting, empirical skill/sector calibration, or a population AKM
projection API.

{title:Reference}

{pstd}
The worker--firm terminology and additive effects model follow Abowd, John M.,
Francis Kramarz, and David N. Margolis. 1999. "High Wage Workers and High Wage
Firms." {it:Econometrica} 67(2): 251-333.
{browse "https://doi.org/10.1111/1468-0262.00020":doi:10.1111/1468-0262.00020}.
The current {cmd:akm/simple} parameter values are a package-defined stylized
teaching and testing design, not an empirical or paper calibration.
The current {cmd:akm/stylized} values are likewise package-defined stress-design
defaults, not estimates from the cited paper or any country data.
The {cmd:akm/germany_chk_2002_2009} wage-component and covariance targets follow
Card, David, Joerg Heining, and Patrick Kline. 2013. "Workplace Heterogeneity and
the Rise of West German Wage Inequality." {it:Quarterly Journal of Economics}
128(3): 967--1015. Its remaining mobility coefficients are stylized carryovers.
{browse "https://doi.org/10.1093/qje/qjt006":doi:10.1093/qje/qjt006}.
The {cmd:akmpaygap/cck2016} group and decomposition targets follow Card, David,
Ana Rute Cardoso, and Patrick Kline. 2016. "Bargaining, Sorting, and the Gender
Wage Gap: Quantifying the Impact of Firms on the Relative Pay of Women."
{it:Quarterly Journal of Economics} 131(2): 633--686. The preset is a targeted
reduced-form mapping under a different normalization, not a replication.
{browse "https://doi.org/10.1093/qje/qjv038":doi:10.1093/qje/qjv038}.


{pstd}
Cahuc, Pierre, Fabien Postel-Vinay, and Jean-Marc Robin. 2006.
"Wage Bargaining with On-the-Job Search: Theory and Evidence."
{it:Econometrica} 74(2): 323-364.
{browse "https://doi.org/10.1111/j.1468-0262.2006.00665.x":doi:10.1111/j.1468-0262.2006.00665.x}.

{title:License}

{pstd}
{cmd:fesim} is released under the MIT License. Type {cmd:help fesim_license} for the full license text.

{title:Also see}

{p 0 21}
Online: {help areg}, {help xtreg}, {help regress}, {help simulate}
{p_end}

{title:Author}

{pstd}Johannes F. Schmieder, Boston University, USA

{pstd}
Website: {browse "https://johannes-schmieder.com/":johannes-schmieder.com}
{break}GitHub: {browse "https://github.com/johannes-schmieder":johannes-schmieder}
{break}Email: {browse "mailto:johannes@bu.edu":johannes@bu.edu}

{pstd}Comments and suggestions are welcome.
