{smcl}
{* *! version 0.0.0-dev 28aug2026}{...}
{vieweralsosee "fesim design" "DESIGN.md"}{...}
{title:Title}

{p 4 8}{cmd:fesim} {hline 2} development interface for linked employer-employee simulation{p_end}

{title:Syntax available in 0.0.0-dev}

{p 8 12}{cmd:fesim version}{p_end}
{p 8 12}{cmd:fesim list}{p_end}
{p 8 12}{cmd:fesim describe} {it:dgp} [{cmd:, preset(}{it:name}{cmd:)}]{p_end}

{title:Reserved simulation syntax}

{p 8 12}{cmd:fesim} [{cmd:, dgp(}{it:name}{cmd:)} {cmd:preset(}{it:name}{cmd:)}
{cmd:workers(}{it:#}{cmd:)} {cmd:firms(}{it:#}{cmd:)} {cmd:periods(}{it:#}{cmd:)}
{cmd:frequency(}{it:year|quarter|month}{cmd:)} {cmd:start(}{it:string}{cmd:)}
{cmd:seed(}{it:#}{cmd:)} {cmd:initial(}{it:name}{cmd:)} {cmd:burnin(}{it:#}{cmd:)}
{cmd:jobrule(}{it:name}{cmd:)} {cmd:truth(}{it:name}{cmd:)}
{cmd:connectivity(}{it:name}{cmd:)} {cmd:parameters(}{it:string}{cmd:)}
{cmd:report} {cmd:noreport} {cmd:clear}]{p_end}

{pstd}
The simulation syntax is reserved and validated, but no DGP is simulation-qualified in this checkpoint. A valid simulation request exits with return code 498 without clearing data or consuming random draws.

{title:Description}

{pstd}
{cmd:fesim} will generate worker-period linked employer-employee panels using a common Stata/Mata engine. The package separates the DGP, mobility engine, calibration preset, and observation scheme. Current defaults and all registered presets are development metadata only.

{pstd}
{cmd:fesim list} shows canonical DGP families, presets, aliases, and implementation status. {cmd:fesim describe} resolves case-insensitive names to canonical lowercase names. For example, {cmd:akmsimple} resolves to {cmd:dgp(akm) preset(simple)}.

{title:Safety and RNG behavior}

{pstd}
Discovery commands do not alter data or Stata's RNG state. The development simulation parser validates recognized options before any possible clear or random draw. If data are loaded and {cmd:clear} is absent, it exits without modifying them. Because simulation is not implemented, even a request with {cmd:clear} leaves the current dataset intact in version 0.0.0-dev.

{title:Registered designs}

{p2colset 9 24 26 2}{...}
{p2col:{cmd:akm}}Presets {cmd:simple} and {cmd:empirical}; aliases {cmd:akmsimple} and {cmd:akmempirical}; planned.{p_end}
{p2col:{cmd:akmpaygap}}Presets {cmd:simple} and planned, unaudited {cmd:cck2016}; planned.{p_end}
{p2col:{cmd:bm}}Preset {cmd:simple}; alias {cmd:bmsimple}; planned pending an accepted equilibrium derivation.{p_end}
{p2colreset}{...}

{title:Stored results}

{pstd}{cmd:fesim version} returns:{p_end}
{synoptset 22 tabbed}{...}
{synopt:{cmd:r(version)}}development version{p_end}
{synopt:{cmd:r(status)}}development status{p_end}
{synopt:{cmd:r(api_level)}}discovery API level{p_end}

{pstd}{cmd:fesim list} returns:{p_end}
{synopt:{cmd:r(dgps)}}canonical DGP names{p_end}
{synopt:{cmd:r(aliases)}}registered aliases{p_end}
{synopt:{cmd:r(qualified)}}qualified DGP names; empty in this checkpoint{p_end}
{synopt:{cmd:r(n_dgps)}}number of canonical registered DGP families{p_end}

{pstd}{cmd:fesim describe} returns:{p_end}
{synopt:{cmd:r(dgp)}}canonical DGP{p_end}
{synopt:{cmd:r(dgp_alias)}}requested lowercase name{p_end}
{synopt:{cmd:r(preset)}}resolved preset{p_end}
{synopt:{cmd:r(title)}}design title{p_end}
{synopt:{cmd:r(calibration_class)}}calibration classification{p_end}
{synopt:{cmd:r(status)}}implementation status{p_end}
{synopt:{cmd:r(frequencies)}}registered output frequencies{p_end}
{synopt:{cmd:r(jobrules)}}registered observation rules{p_end}

{title:Examples}

{phang2}{cmd:. fesim version}{p_end}
{phang2}{cmd:. fesim list}{p_end}
{phang2}{cmd:. fesim describe AKMSIMPLE}{p_end}
{phang2}{cmd:. fesim describe akm, preset(simple)}{p_end}

{title:Limitations}

{pstd}
Version 0.0.0-dev does not generate data, estimate a model, or provide a paper calibration. The first intended vertical slice is the stylized {cmd:akmsimple} panel described in {cmd:DESIGN.md}.

{title:Author}

{pstd}
Johannes Schmieder. Development repository: {browse "https://github.com/johannes-schmieder/fesim"}.
