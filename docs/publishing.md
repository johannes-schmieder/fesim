# Source archives and releases

A public repository exposes source; a software release additionally needs an
immutable version and a qualified installable archive. Current `main` is a
1.2.0-rc.1 development candidate. `v0.1.0` remains the older simple-AKM tag.

## Build an exact archive

From clean committed source, with a licensed Stata executable:

```sh
python3 scripts/qualify_archive.py . /path/to/stata-mp build/releases/new-candidate
```

Choose a new output directory each time. The tool creates `git archive HEAD`,
extracts it without Git or a development Mata library, runs every registered
Stata test including source-only installation, and binds the accepted receipt
to the source SHA and archive SHA-256. It rejects unsafe archive paths, symlinks,
generated test/data/library artifacts, and tracked-source changes. Logs and
receipts stay under ignored `build/`.

## Installation and reproducibility

```stata
net install fesim, from("https://raw.githubusercontent.com/johannes-schmieder/fesim/main") replace
fesim version
```

Use an exact commit in place of `main` for reproducibility. `v0.1.0` is an
immutable simple-AKM alternative. Offline source installation uses
`net install fesim, from("/path/to/extracted/source") replace`.
The runtime loads authoritative official Mata source in Stata.

For an existing installation with `_fesim_*` helpers, run `ado uninstall fesim`
before the installation command. A direct `replace` upgrade works but leaves
the obsolete helper files on disk; uninstalling the old package first removes
those files. Fresh installation and reinstalling the current package need no
extra step.

## Release review

Review scientific claims, API compatibility, full-suite evidence, archive
installation, platform scope, performance controls, and the rendered manual.
Preserve source/receipt/archive/manual checksums outside tracked source. Hosted
static CI and licensed testing are separate evidence.

Create a new tag or GitHub release only with owner authorization and qualified
exact source. Never move an existing tag or claim wider platform support from
another version's evidence. Update citation metadata, package/help versions,
release notes, and installation instructions together. SSC submission is a
separate distribution decision. Public visibility does not imply a new tag.
