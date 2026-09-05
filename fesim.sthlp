{smcl}
{* *! version 0.4.0-dev 31aug2026}{...}
{.-}
help for {cmd:fesim} {right:(Johannes F. Schmieder)}
{.-}
{vieweralsosee "fesim design" "DESIGN.md"}{...}
{title:Title}

{p 4 8}{cmd:fesim} {hline 2} linked employer-employee panel simulation{p_end}

{title:Syntax available in 0.4.0-dev}

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
The {cmd:dgp(akm)} presets {cmd:simple}, {cmd:stylized}, and {cmd:germany_chk_2002_2009}, plus the {cmd:dgp(akmpaygap)} presets {cmd:simple} and {cmd:cck2016}, are available. {cmd:dgp(akmsimple)} and {cmd:dgp(akmempirical)} are convenience aliases for the first two AKM designs. Model-specific scalars remain exclusively inside {cmd:parameters()}; named options are common controls only. Canonical {cmd:dgp(bm) preset(simple)} is also available, with alias {cmd:dgp(bmsimple)}.

{title:Description}

{pstd}
{cmd:fesim} generates worker-period linked employer-employee panels using a common Stata/Mata engine. The package separates the DGP, mobility engine, calibration preset, and observation scheme. The {cmd:akm/simple} defaults are a stylized teaching and testing design. The {cmd:akm/stylized} defaults exercise a monthly empirical-mobility engine but are explicitly uncalibrated; the alias name {cmd:akmempirical} does not imply a paper or country calibration. The distinct {cmd:akm/germany_chk_2002_2009} preset targets selected Card-Heining-Kline 2002--2009 West German AKM wage-dispersion and sorting moments. {cmd:akmpaygap} codes men as group 0 and women as group 1, reports men-minus-women gaps, and separates worker composition, firm sorting, and group premium schedules. Its {cmd:cck2016} preset targets selected Card-Cardoso-Kline group and decomposition moments.

{pstd}
{cmd:fesim list} shows canonical DGP families, presets, aliases, and implementation status. {cmd:fesim presets} lists presets for all families or one requested DGP. {cmd:fesim describe} resolves case-insensitive names to canonical lowercase names. For example, {cmd:akmsimple} resolves to {cmd:dgp(akm) preset(simple)} and reports the same canonical configuration.

{pstd}
Configuration metadata is implemented for all six public presets. The simple and stylized presets retain their documented defaults. The Germany preset defaults to {cmd:workers(10000)}, {cmd:firms(1000)}, eight annual periods beginning in 2002, {cmd:initial(random)}, and a five-year monthly burn-in. All presets default to {cmd:truth(basic)}, {cmd:connectivity(keep)}, {cmd:network(random)}, and {cmd:report}. Omitting {cmd:seed()} records {cmd:current}; configuration resolution itself never changes the RNG state.

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
{synopt:{cmd:r(qualified)}}qualified DGP/preset names; currently {cmd:akm/simple akm/stylized akm/germany_chk_2002_2009 akmpaygap/simple akmpaygap/cck2016}{p_end}
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

{title:Examples}

{pstd}
Each block is self-contained. The visible {cmd:preserve}/{cmd:restore} lines
make it safe to copy into a do-file. The clickable link runs the marked inner
block through {cmd:fesim_run}, which also restores the caller's data.

{space 4}{hline 10} {it:Example 1 - Inspect designs and presets} {hline 22}
{cmd}{...}
          preserve
{* example_start - discovery}{...}
          fesim version
          fesim list
          fesim presets akm
          fesim describe AKMSIMPLE
          fesim describe akm, preset(simple)
          return list
{* example_end}{...}
          restore
{txt}{...}
{space 4}{hline 78}
{space 4}{it:({stata fesim_run discovery using fesim.sthlp:click to run})}

{space 4}{hline 10} {it:Example 2 - Generate and inspect a panel} {hline 20}
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
{space 4}{hline 78}
{space 4}{it:({stata fesim_run simulate using fesim.sthlp:click to run})}

{space 4}{hline 10} {it:Example 3 - Simulate and estimate an AKM model} {hline 13}
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
{space 4}{hline 78}
{space 4}{it:({stata fesim_run estimate using fesim.sthlp:click to run})}

{space 4}{hline 10} {it:Example 4 - Generate a block-network stress design} {hline 10}
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
{space 4}{hline 78}
{space 4}{it:({stata fesim_run blocks using fesim.sthlp:click to run})}

{space 4}{hline 10} {it:Example 5 - Inspect a pay-gap decomposition} {hline 14}
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
{space 4}{hline 78}
{space 4}{it:({stata fesim_run paygap using fesim.sthlp:click to run})}

{title:Limitations}

{pstd}
Version 0.4.0-dev exposes three AKM presets and both pay-gap presets. The Germany preset targets wage-component dispersions and sorting only; its hazards and durations are not German-calibrated. The CCK-inspired preset targets selected group moments and the male-reference firm decomposition under the package's standard-normal surplus normalization; it does not reproduce CCK's empirical normalization or full estimation. {cmd:connectivity(force)} has no accepted scientific design. The D-036 BM derivation and internal continuum solver are implemented, but the BM family remains discovery-only until finite firms and the simulation route are qualified.

{pstd}
The supported minimum for {cmd:v0.1.0} is Stata 19. Exact-source qualification covers Stata/MP 19 on macOS Apple Silicon and Windows x86-64; no cross-version or cross-platform bitwise claim is made.

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

{title:License}

{pstd}
{cmd:fesim} is released under the MIT License. Type {cmd:help fesim_license} for the full license text.

{title:Also see}

{p 0 21}
Online: {help areg}, {help xtreg}, {help regress}, {help simulate}
{p_end}

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

{pstd}{stata "fesim_run bm using fesim.sthlp":Run BM example}{p_end}
{cmd}{...}
{* example_start - bm}{...}
          fesim, dgp(bm) workers(2000) firms(100) periods(5) ///
              seed(12345) truth(full) clear
          matrix list r(solver)
          matrix list r(bm_flows)
          matrix list r(bm_firms)
{* example_end}{...}
{txt}{...}

{title:Author}

{pstd}Johannes F. Schmieder, Boston University, USA

{pstd}
Website: {browse "https://johannes-schmieder.com/":johannes-schmieder.com}
{break}GitHub: {browse "https://github.com/johannes-schmieder":johannes-schmieder}
{break}Email: {browse "mailto:johannes@bu.edu":johannes@bu.edu}

{pstd}Comments and suggestions are welcome.
