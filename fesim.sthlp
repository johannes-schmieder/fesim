{smcl}
{* *! version 0.2.0-dev 29aug2026}{...}
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
{cmd:connectivity(}{it:name}{cmd:)} {cmd:parameters(}{it:string}{cmd:)}
{cmd:report} {cmd:noreport} {cmd:clear}]{p_end}

{pstd}
The {cmd:dgp(akm) preset(simple)} design is available; {cmd:dgp(akmsimple)} is its convenience alias. The frozen {cmd:v0.1.0} contract keeps model-specific scalars exclusively inside {cmd:parameters()}; named options are common controls only. Other registered designs remain discovery metadata and exit without changing data or random state.

{title:Description}

{pstd}
{cmd:fesim} will generate worker-period linked employer-employee panels using a common Stata/Mata engine. The package separates the DGP, mobility engine, calibration preset, and observation scheme. The {cmd:akm/simple} defaults are frozen as a stylized teaching and testing design; they are not an empirical calibration. Other registered presets remain development metadata only.

{pstd}
{cmd:fesim list} shows canonical DGP families, presets, aliases, and implementation status. {cmd:fesim presets} lists presets for all families or one requested DGP. {cmd:fesim describe} resolves case-insensitive names to canonical lowercase names. For example, {cmd:akmsimple} resolves to {cmd:dgp(akm) preset(simple)} and reports the same canonical configuration.

{pstd}
Configuration metadata is implemented for {cmd:dgp(akm) preset(simple)}. Common defaults are {cmd:workers(10000)}, {cmd:firms(500)}, {cmd:periods(10)}, {cmd:frequency(year)}, {cmd:start(2000)}, {cmd:initial(stationary)}, {cmd:burnin(0)}, {cmd:jobrule(end)}, {cmd:truth(basic)}, {cmd:connectivity(keep)}, and {cmd:report}. Omitting {cmd:seed()} records {cmd:current}; configuration resolution itself never changes the RNG state.

For the simple AKM contract, {cmd:initial(stationary)} uses the exact interval transition matrix over unemployment and firms and initializes job age from the stationary geometric distribution. {cmd:initial(random)} uses employment probability 0.5, attraction-weighted firm assignment, tenure zero, and requires {cmd:burnin()} of at least one period. {cmd:initial(allunemployed)} is a diagnostic start.

{pstd}
The simple model parameters accepted in {cmd:parameters()} are {cmd:mu}, {cmd:sd_worker}, {cmd:sd_firm}, {cmd:sd_error}, {cmd:firm_size_sd}, {cmd:p_eu}, {cmd:p_ee}, {cmd:p_ue}, and {cmd:wage_trend}. Registered defaults are 3, .40, .15, .20, 1, .08, .12, .60, and 0, respectively. Standard deviations are nonnegative; transition probabilities are bounded in [0,1], with {cmd:p_eu} and {cmd:p_ee} strictly below 1 and summing to less than 1. These model parameters do not have separate named options in {cmd:v0.1.0}.

{title:Time and rate units}

{pstd}
{cmd:frequency()} selects abstract Stata annual, quarterly, or monthly output periods and the corresponding {cmd:%ty}, {cmd:%tq}, or {cmd:%tm} time format. Reduced-form transition inputs {cmd:p_eu}, {cmd:p_ee}, and {cmd:p_ue} are annual probabilities. Quarterly or monthly output does not reinterpret them as per-period probabilities: {cmd:fesim} applies the documented constant-hazard conversion, treating EU and EE as competing risks.

{title:Simulation output}

{pstd}
The returned dataset is sorted by {cmd:workerid time} and satisfies {cmd:isid workerid time}. Required variables are {cmd:workerid}, {cmd:time}, {cmd:firmid}, {cmd:employed}, {cmd:lnwage}, {cmd:spellid}, {cmd:tenure}, {cmd:newjob}, {cmd:from_unemp}, {cmd:to_unemp}, {cmd:jobtojob}, and {cmd:ntransitions}. With {cmd:truth(basic)} or {cmd:truth(full)}, the simple preset also generates {cmd:alpha_true}, {cmd:psi_true}, {cmd:time_true}, {cmd:xb_true}, {cmd:match_true}, {cmd:epsilon_true}, and {cmd:lnwage_true}. {cmd:truth(none)} suppresses those columns without changing any economic draw or common output value.

{pstd}
{cmd:alpha_true} is the persistent worker effect. {cmd:psi_true} is the persistent current-firm effect and is missing outside employment. {cmd:time_true} is {cmd:wage_trend} times elapsed retained-sample years. {cmd:xb_true} and {cmd:match_true} are zero in the simple preset. {cmd:epsilon_true} is the idiosyncratic wage shock, and {cmd:lnwage_true} equals the observed employed log wage because the simple preset has no measurement error.

{pstd}
Simulation results are returned through {cmd:r()} scalars for dimensions, realized flows, network diagnostics, and stage runtimes; macros for the resolved DGP, preset, timing, RNG, and version; and matrices {cmd:r(parameters)}, {cmd:r(moments)}, {cmd:r(targets)}, and {cmd:r(network)}. Simple-AKM component moments and targets are computed even under {cmd:truth(none)}. Dataset characteristics record the version, canonical DGP and requested alias, preset and calibration class, command, actual master seed and RNG, frequency and internal clock, employer rule, burn-in, connectivity rule, truth mode, and normalization reference.

{title:Connectivity}

{pstd}
The observed graph contains ever-employed workers, active firms, and one edge per unique observed worker-firm match. Never-employed workers and inactive firms are excluded. Largest-component observation, worker, and firm shares respectively use employed observations, ever-employed workers, and active firms as denominators. Ties are resolved by employed observations, then workers, then firms, then the lowest component identifier.

{pstd}
{cmd:connectivity(keep)} leaves the generated panel unchanged. {cmd:connectivity(largest)} retains all periods, including nonemployment, for workers in the selected component, so the returned panel remains balanced. {cmd:r(network)} has {cmd:generated} and {cmd:returned} columns and stable rows for component, edge, observation, worker, firm, largest-component count, and share diagnostics. Under {cmd:largest}, {cmd:r(N_workers)} is the retained count; the requested worker count remains in {cmd:r(parameters)}. A generated panel without employment rejects {cmd:largest}.

{title:Safety and RNG behavior}

{pstd}
Discovery and configuration resolution do not alter data or Stata's RNG state. The simulation parser validates recognized options before any possible clear or random draw. If data are loaded and {cmd:clear} is absent, it exits without modifying them. A failing simulation restores the prior dataset and RNG state. With {cmd:seed(#)}, the caller RNG state is unchanged; without it, one integer draw supplies the recorded master seed and advances the caller sequence exactly once. {cmd:connectivity(force)} has no accepted scientific generation rule and fails before replacement or draws.

{title:Registered designs}

{p2colset 9 24 26 2}{...}
{p2col:{cmd:akm}}Preset {cmd:simple} and alias {cmd:akmsimple} are qualified; {cmd:empirical} and {cmd:akmempirical} are planned.{p_end}
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
{synopt:{cmd:r(qualified)}}qualified DGP/preset names; currently {cmd:akm/simple}{p_end}
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
{synopt:{cmd:r(dgp)}, {cmd:r(dgp_alias)}, {cmd:r(preset)}}canonical identity and requested alias{p_end}
{synopt:{cmd:r(seed)}, {cmd:r(rng)}}actual master seed and component-stream RNG{p_end}
{synopt:{cmd:r(frequency)}, {cmd:r(internal_clock)}}output and internal timing{p_end}
{synopt:{cmd:r(command)}, {cmd:r(version)}, {cmd:r(reference)}}scientific command and package metadata{p_end}

{title:Examples}

{phang2}{cmd:. fesim version}{p_end}
{phang2}{cmd:. fesim list}{p_end}
{phang2}{cmd:. fesim presets akm}{p_end}
{phang2}{cmd:. fesim describe AKMSIMPLE}{p_end}
{phang2}{cmd:. fesim describe akm, preset(simple)}{p_end}
{phang2}{cmd:. fesim, dgp(akmsimple) seed(12345) clear}{p_end}
{phang2}{cmd:. fesim, workers(5000) periods(8) parameters(sd_worker .45 p_ee .10) clear}{p_end}
{phang2}{cmd:. fesim, workers(5000) periods(8) seed(12345) connectivity(largest) clear}{p_end}
{phang2}{cmd:. areg lnwage i.workerid i.time if employed, absorb(firmid) vce(cluster workerid)}{p_end}

{title:Limitations}

{pstd}
Version 0.2.0-dev retains the released stylized {cmd:akm/simple} panel but does not yet expose the empirical-mobility engine under development. It does not estimate a model or provide a paper calibration. {cmd:connectivity(force)} has no accepted scientific design. Other registered presets remain discovery-only.

{pstd}
The supported minimum for {cmd:v0.1.0} is Stata 19. Exact-source qualification covers Stata/MP 19 on macOS Apple Silicon and Windows x86-64; no cross-version or cross-platform bitwise claim is made.

{title:License}

{pstd}
{cmd:fesim} is released under the MIT License. Type {cmd:help fesim_license} for the full license text.

{title:Author}

{pstd}
Johannes Schmieder. Development repository: {browse "https://github.com/johannes-schmieder/fesim"}.
