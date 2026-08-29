# CI and exact-source qualification

`fesim` separates checks that can run on a public GitHub host from tests that require licensed Stata. A green static job is not a Stata qualification claim.

## GitHub-hosted static lane

`.github/workflows/static.yml` runs on pushes, pull requests, and manual dispatch. It uses only Git, shell, and the Python standard library. The job checks:

- whitespace and tracked-artifact hygiene;
- one-to-one agreement between `fesim.pkg` and installed root-level ado/help files;
- version-source consistency;
- complete Mata source registration in `src/build_mlib.do`;
- complete unit/integration Stata test registration in `tests/run_all.do`;
- absence of foreign-runtime calls from installed ado files;
- the expected static workflow structure;
- valid and invalid exact-SHA receipt cases.

It does not install, emulate, or invoke Stata, and its job name states `no Stata`.

## Licensed Stata lane

Run exact-source qualification from a clean checkout with:

```sh
STATA_BIN=/path/to/stata-mp scripts/run_stata_tests.sh
```

The wrapper refuses tracked or untracked source changes, derives the exact `HEAD` SHA and branch itself, runs `tests/run_all.do`, and then passes the generated JSON receipt to `scripts/verify_stata_receipt.py`. The verifier requires:

- an exact 40-character receipt SHA equal to checked-out `HEAD`;
- a clean worktree;
- a receipt filename, repository path, and branch matching the checkout;
- accepted status, zero exit code and failed-test count, a positive passed-test count, and a clean Mata rebuild.

Receipts and logs remain ignored local evidence. `PLAN.md` records accepted exact-SHA results. No licensed self-hosted workflow is configured because the repository has no `gptpro.md` or approved Stata runner instructions.

## Owner-controlled Windows qualification

Formal Windows qualification uses the private guarded Windows/Stata runner,
not GitHub Actions. The exact clean source archive contains `windows-ci.do`,
which invokes the complete Stata suite and writes `windows-ci.status` with the
authoritative final marker only after every assertion passes. The external
runner binds that result to the exact commit and source-archive hash, collects
only sanitized evidence, removes transient source/results, and returns the
machine to its stopped state. Raw Stata startup logs and license information
must never be collected or published.
