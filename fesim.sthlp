{smcl}
{* *! version 0.2.0-dev 29aug2026}{...}
{.-}
help for {cmd:fesim} {right:(Johannes F. Schmieder)}
{.-}
{vieweralsosee "fesim design" "DESIGN.md"}{...}
{title:Title}

{p 4 8}{cmd:fesim} {hline 2} linked employer-employee panel simulation{p_end}

{title:Syntax available in 0.2.0-dev}

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
The {cmd:dgp(akm) preset(simple)} and {cmd:dgp(akm) preset(stylized)} designs are available; {cmd:dgp(akmsimple)} and {cmd:dgp(akmempirical)} are their convenience aliases. Model-specific scalars remain exclusively inside {cmd:parameters()}; named options are common controls only. Other registered designs remain discovery metadata and exit without changing data or random state.

{title:Description}

{pstd}
{cmd:fesim} generates worker-period linked employer-employee panels using a common Stata/Mata engine. The package separates the DGP, mobility engine, calibration preset, and observation scheme. The {cmd:akm/simple} defaults are a stylized teaching and testing design. The {cmd:akm/stylized} defaults exercise a monthly empirical-mobility engine but are explicitly uncalibrated; the alias name {cmd:akmempirical} does not imply a paper or country calibration.

{pstd}
{cmd:fesim list} shows canonical DGP families, presets, aliases, and implementation status. {cmd:fesim presets} lists presets for all families or one requested DGP. {cmd:fesim describe} resolves case-insensitive names to canonical lowercase names. For example, {cmd:akmsimple} resolves to {cmd:dgp(akm) preset(simple)} and reports the same canonical configuration.

{pstd}
Configuration metadata is implemented for both public presets. Common defaults are {cmd:workers(10000)}, {cmd:firms(500)}, {cmd:periods(10)}, {cmd:frequency(year)}, {cmd:start(2000)}, {cmd:jobrule(end)}, {cmd:truth(basic)}, {cmd:connectivity(keep)}, {cmd:network(random)}, and {cmd:report}. The simple preset uses {cmd:initial(stationary)} and {cmd:burnin(0)}. The stylized empirical-mobility preset uses {cmd:initial(random)} and a five-year monthly burn-in. Omitting {cmd:seed()} records {cmd:current}; configuration resolution itself never changes the RNG state.

For the simple AKM contract, {cmd:initial(stationary)} uses the exact interval transition matrix over unemployment and firms and initializes job age from the stationary geometric distribution. {cmd:initial(random)} uses employment probability 0.5, attraction-weighted firm assignment, tenure zero, and requires {cmd:burnin()} of at least one period. {cmd:initial(allunemployed)} is a diagnostic start.

{pstd}
The simple model parameters accepted in {cmd:parameters()} are {cmd:mu}, {cmd:sd_worker}, {cmd:sd_firm}, {cmd:sd_error}, {cmd:firm_size_sd}, {cmd:p_eu}, {cmd:p_ee}, {cmd:p_ue}, and {cmd:wage_trend}. Registered defaults are 3, .40, .15, .20, 1, .08, .12, .60, and 0, respectively. Standard deviations are nonnegative; transition probabilities are bounded in [0,1], with {cmd:p_eu} and {cmd:p_ee} strictly below 1 and summing to less than 1. These model parameters do not have separate named options in {cmd:v0.1.0}.

{pstd}
The stylized empirical-mobility preset reuses the wage/size parameters and adds {cmd:rho_z_alpha}, {cmd:rho_q_psi}; annual log-hazard intercepts {cmd:kappa_eu}, {cmd:kappa_ee}, {cmd:kappa_ue}; worker, firm, tenure, and unemployment-duration slopes; and destination coefficients {cmd:theta_sort}, {cmd:theta_quality}, {cmd:theta_up}, and {cmd:theta_down}. Type {cmd:fesim describe akmempirical} for all defaults and bounds. The intercepts anchor zero-covariate intensities to the simple annual probabilities; all remaining coefficients are transparent stress-design choices, not fitted estimates.

{title:Network stress designs}

{pstd}
{cmd:network(random)} is the frozen compatibility default. {cmd:network(blocks)} independently assigns workers and firms to balanced communities using a dedicated RNG stream. Origin-free initialization and UE destinations use the worker's permanent home community; EE destinations use the current firm's community. The same-block destination weight is multiplied by {cmd:exp(block_log_bonus)}. The network scalars {cmd:block_count} and {cmd:block_log_bonus} remain inside {cmd:parameters()}; their defaults are 4 and {cmd:ln(9)}. Setting {cmd:block_log_bonus} to zero exactly nests the random destination rule. Network parameters supplied under an irrelevant design are rejected.

{pstd}
{cmd:network(bridges)} uses strict ordinary blocks: initialization and UE stay in the worker's home block, and ordinary EE destinations stay in the current firm's block. It then redirects the destination, but not the occurrence or timing, of an exact set of retained-sample EE events. The minimum plan is 1-2, 2-3, ..., {cmd:block_count-1}-{cmd:block_count}; extra bridges cycle over those adjacent pairs. Distinct bridge workers are selected reproducibly by the isolated network-design priority among eligible workers. {cmd:bridge_count} defaults dynamically to {cmd:block_count-1} and may be raised inside {cmd:parameters()}. At least two firms per block are required. The command fails if eligible retained EE events cannot complete the exact plan. {cmd:block_log_bonus} is inapplicable and is rejected when explicitly supplied.

{title:Time and rate units}

{pstd}
{cmd:frequency()} selects abstract Stata annual, quarterly, or monthly output periods and the corresponding {cmd:%ty}, {cmd:%tq}, or {cmd:%tm} time format. Simple-preset transition inputs are annual probabilities. The stylized preset always advances monthly from annual continuous hazards and samples the requested output snapshots. Quarterly or monthly output never reinterprets annual inputs as per-period values.

{title:Simulation output}

{pstd}
The returned dataset is sorted by {cmd:workerid time} and satisfies {cmd:isid workerid time}. Required variables are {cmd:workerid}, {cmd:time}, {cmd:firmid}, {cmd:employed}, {cmd:lnwage}, {cmd:spellid}, {cmd:tenure}, {cmd:newjob}, {cmd:from_unemp}, {cmd:to_unemp}, {cmd:jobtojob}, and {cmd:ntransitions}. With {cmd:truth(basic)} or {cmd:truth(full)}, the simple preset also generates {cmd:alpha_true}, {cmd:psi_true}, {cmd:time_true}, {cmd:xb_true}, {cmd:match_true}, {cmd:epsilon_true}, and {cmd:lnwage_true}. {cmd:truth(none)} suppresses those columns without changing any economic draw or common output value.

{pstd}
The stylized preset additionally reports {cmd:unemp_duration}; it and {cmd:tenure} use output-period units. {cmd:ntransitions} counts all monthly events since the prior snapshot and may exceed one. {cmd:r(durations)} reports counts, means, sample standard deviations, and p10/p50/p90 in years. Under {cmd:truth(full)}, {cmd:worker_type_true} gives the five-point mobility type and {cmd:firm_quality_true} gives current-firm quality on employed rows. Under a nonrandom network design, full truth also adds permanent {cmd:worker_block_true} and current-employer {cmd:firm_block_true}; the latter is missing outside employment. {cmd:network(bridges)} adds {cmd:nbridges_imposed} under every truth mode; it counts design-imposed bridges for that worker and output interval.

{pstd}
{cmd:alpha_true} is the persistent worker effect. {cmd:psi_true} is the persistent current-firm effect and is missing outside employment. {cmd:time_true} is {cmd:wage_trend} times elapsed retained-sample years. {cmd:xb_true} and {cmd:match_true} are zero in the simple preset. {cmd:epsilon_true} is the idiosyncratic wage shock, and {cmd:lnwage_true} equals the observed employed log wage because the simple preset has no measurement error.

{pstd}
Simulation results are returned through {cmd:r()} scalars for dimensions, realized flows, network diagnostics, and stage runtimes; macros for the resolved DGP, preset, timing, RNG, network design, and version; and matrices {cmd:r(parameters)}, {cmd:r(moments)}, {cmd:r(targets)}, and {cmd:r(network)}. {cmd:akm/stylized} also returns {cmd:r(durations)}. {cmd:network(bridges)} returns {cmd:r(bridges_imposed)} and the exact eight-column {cmd:r(bridges)} ledger: bridge ID, worker ID, output period, internal period, source firm, target firm, source block, and target block. Component moments and applicable targets are computed even under {cmd:truth(none)}. Dataset characteristics record the version, canonical DGP and requested alias, preset and calibration class, command, actual master seed and RNG, frequency and internal clock, employer rule, burn-in, connectivity rule, network design, truth mode, and normalization reference.

{title:Connectivity}

{pstd}
The observed bipartite graph contains ever-employed workers, active firms, and one edge per unique observed worker-firm match. Never-employed workers and inactive firms are excluded. Largest-component observation, worker, and firm shares respectively use employed observations, ever-employed workers, and active firms as denominators. Ties are resolved by employed observations, then workers, then firms, then the lowest component identifier.

The observed firm mobility graph is undirected. A link is an unordered firm pair in an adjacent-output transition with {cmd:jobtojob==1}; its weight is the number of those observed direct moves pooling directions. Active firms incident to no link are counted as firms with no movers. Link-weight p10, p50, p90, and p99 use Stata's default percentile convention. These summaries do not claim leave-out connectedness.

{pstd}
{cmd:connectivity(keep)} leaves the generated panel unchanged. {cmd:connectivity(largest)} retains all periods, including nonemployment, for workers in the selected component, so the returned panel remains balanced. {cmd:r(network)} has {cmd:generated} and {cmd:returned} columns and 19 stable rows: 13 component diagnostics followed by {cmd:firms_no_movers}, {cmd:firm_links}, {cmd:edge_weight_p10}, {cmd:edge_weight_p50}, {cmd:edge_weight_p90}, and {cmd:edge_weight_p99}. Mobility rows are recomputed after {cmd:largest}. Under that mode, {cmd:r(N_workers)} is the retained count; the requested worker count remains in {cmd:r(parameters)}. A generated panel without employment rejects {cmd:largest}.

{title:Safety and RNG behavior}

{pstd}
Discovery and configuration resolution do not alter data or Stata's RNG state. The simulation parser validates recognized options before any possible clear or random draw. If data are loaded and {cmd:clear} is absent, it exits without modifying them. A failing simulation restores the prior dataset and RNG state. With {cmd:seed(#)}, the caller RNG state is unchanged; without it, one integer draw supplies the recorded master seed and advances the caller sequence exactly once. {cmd:connectivity(force)} has no accepted scientific generation rule and fails before replacement or draws.

{title:Registered designs}

{p2colset 9 24 26 2}{...}
{p2col:{cmd:akm}}Presets {cmd:simple} and {cmd:stylized} are qualified; aliases are {cmd:akmsimple} and {cmd:akmempirical}.{p_end}
{p2col:{cmd:akmpaygap}}Presets {cmd:simple} and planned, unaudited {cmd:cck2016}; planned.{p_end}
{p2col:{cmd:bm}}Preset {cmd:simple}; alias {cmd:bmsimple}; planned pending an accepted equilibrium derivation.{p_end}
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
{synopt:{cmd:r(qualified)}}qualified DGP/preset names; currently {cmd:akm/simple akm/stylized}{p_end}
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
{synopt:{cmd:r(durations)}}year-valued tenure and unemployment-duration distribution; {cmd:akm/stylized}{p_end}
{synopt:{cmd:r(bridges)}}exact bridge-event ledger; {cmd:network(bridges)} only{p_end}
{synopt:{cmd:r(dgp)}, {cmd:r(dgp_alias)}, {cmd:r(preset)}}canonical identity and requested alias{p_end}
{synopt:{cmd:r(seed)}, {cmd:r(rng)}}actual master seed and component-stream RNG{p_end}
{synopt:{cmd:r(network_design)}}resolved random, block, or bridge destination design{p_end}
{synopt:{cmd:r(frequency)}, {cmd:r(internal_clock)}}output and internal timing{p_end}
{synopt:{cmd:r(command)}, {cmd:r(version)}, {cmd:r(reference)}}scientific command and package metadata{p_end}

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

{title:Limitations}

{pstd}
Version 0.2.0-dev exposes the released {cmd:akm/simple} panel and the uncalibrated {cmd:akm/stylized} empirical-mobility engine. It does not estimate a model or provide a paper or German calibration. {cmd:connectivity(force)} has no accepted scientific design. Other registered families remain discovery-only.

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
