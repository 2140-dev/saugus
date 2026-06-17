# Hydra Forge Handoff - 2026-06-17

This note captures the resume point after wiring the Hetzner Hydra host,
Ironworks, Saugus, and the `2140-dev/bitcoin` staging source snapshot.

Keep this file operational but non-secret. Do not record private keys, rescue
passwords, Hydra admin passwords, cache signing keys, or GitHub tokens here.

## Current Baseline

Repositories and refs:

| Repo | Branch/ref | State |
| --- | --- | --- |
| `2140-dev/ironworks` | `master` | `cde069b7f24b4131603d43e925b632426d2f8031` |
| `2140-dev/saugus` | `staging-lock` | `31a12a4` pins Forge inputs |
| `2140-dev/bitcoin` | staging source pin | `6e7021efb96d020c7fa6980cee04a0a33666ce40` |

Saugus staging lock:

- `locks/staging.json` pins the source and Ironworks commits above.
- `locks/hydra-stage.json` selects jobset `forge` and stage `staging`.
- Do not put docs-only commits on `staging-lock` unless a new Hydra evaluation
  is intended.

Hydra:

- Project: `saugus`
- Jobset: `forge`
- Last evaluated snapshot: eval `16`
- Green build range: `206` through `219`
- Services were active when checked: `hydra-init`, `hydra-evaluator`,
  `hydra-queue-runner`
- The host successfully booted NixOS after the vKVM/rescue work.

Green Forge jobs from eval `16`:

| Build | Job | Result |
| --- | --- | --- |
| `206` | `x86_64-linux.staging.bench-sanity` | success |
| `207` | `x86_64-linux.staging.full` | success |
| `208` | `x86_64-linux.staging.fuzz.targets-report` | success |
| `209` | `x86_64-linux.staging.fuzz.valgrind-smoke` | success |
| `210` | `x86_64-linux.staging.fuzz-smoke` | success |
| `211` | `x86_64-linux.staging.heavy.asan-ubsan` | success |
| `212` | `x86_64-linux.staging.heavy.msan-build` | success |
| `213` | `x86_64-linux.staging.heavy.tsan` | success |
| `214` | `x86_64-linux.staging.platforms.aarch64` | success |
| `215` | `x86_64-linux.staging.platforms.armv7` | success |
| `216` | `x86_64-linux.staging.platforms.i686` | success |
| `217` | `x86_64-linux.staging.platforms.musl` | success |
| `218` | `x86_64-linux.staging.regtest-smoke` | success |
| `219` | `x86_64-linux.staging.required` | success |

Do not auto-merge PR #47. It was explicitly left for manual review/decision.

## Useful Resume Commands

Check local repo state:

```sh
cd /home/josie/2140-node-packaging
git status --short --branch

cd /home/josie/saugus
git status --short --branch
```

Verify Saugus stage filtering locally:

```sh
cd /home/josie/saugus
nix eval .#hydraJobs.x86_64-linux --apply builtins.attrNames --accept-flake-config
nix eval .#hydraJobs.x86_64-linux.staging --apply builtins.attrNames --accept-flake-config
```

Check the green Hydra build window:

```sh
sudo -u hydra psql hydra -Atc \
  "select id, job, finished, coalesce(buildstatus::text, 'null')
   from builds
   where id between 206 and 219
   order by id;"

sudo -u hydra psql hydra -Atc \
  "select build, stepnr, status, regexp_replace(drvpath, '.*/', ''), coalesce(errormsg, '')
   from buildsteps
   where build between 206 and 219
     and status is not null
     and status <> 0
   order by build, stepnr;"
```

Manually re-evaluate Forge:

```sh
sudo -u hydra hydra-eval-jobset saugus forge
```

## Remaining Work

### 1. Analysis Jobs

Ironworks exposes:

```text
hydraJobs.x86_64-linux.staging.analysis.clang-tidy-report
hydraJobs.x86_64-linux.staging.analysis.iwyu-report
```

These are not part of the green eval `16` build range. The latest Hydra rows
seen on 2026-06-17 were:

```text
182|x86_64-linux.staging.analysis.clang-tidy-report|finished|4
183|x86_64-linux.staging.analysis.iwyu-report|finished|4
```

Diagnostic context:

- No `buildsteps` rows were recorded for builds `182` or `183`.
- `starttime` and `stoptime` were identical for each row, so this looks like
  immediate Hydra-side status handling rather than a long compile failure.
- A local probe from Saugus started both derivations. IWYU reached
  `installPhase`; clang-tidy was actively running at 100% CPU before the probe
  was stopped because it was only a handoff-context check.

Next actions:

- Re-run the two analysis derivations locally to completion.
- Re-run or force the Hydra analysis jobs after confirming whether status `4`
  means cancelled, unsupported, or another Hydra-specific state in this
  deployment.
- Keep analysis non-gating until the reports are reliable and their runtime is
  known.

### 2. Legacy CI Parity

Still missing or partial from the old source CI matrix:

- `test ancestor commits`: not ported. Decide whether it belongs in `spark` or
  `forge`; start non-gating until runtime and flakiness are known.
- Source lint parity: `checks.${system}.correctness-lint` is partial. Compare
  against the current source `ci/lint.py` inventory and either port each check
  or explicitly document why it is intentionally omitted.
- macOS cross arm64 and x86_64: reserved in the model but not implemented.
- FreeBSD cross: reserved in the model but not implemented.
- Native Darwin: cannot be gated until there is a Darwin builder.
- macOS native fuzz: planned for `harden`, not implemented.

Do not disable the legacy source CI wholesale until each migrated job has a
stage, a Hydra output, an artifact/log story, and at least a small history of
green runs where appropriate.

### 3. Hardening Jobs

The scheduled `harden` surface exists, but parts are still scaffolds:

```text
hydraJobs.x86_64-linux.scheduled.ibd-small
hydraJobs.x86_64-linux.scheduled.previous-releases
hydraJobs.x86_64-linux.scheduled.fuzz-corpus
hydraJobs.x86_64-linux.scheduled.benchmark-artifact
hydraJobs.x86_64-linux.scheduled.benchmark-report
```

Remaining decisions/work:

- Choose fixture/corpus storage for IBD, previous-release compatibility, and
  long fuzzing.
- Pin fixture metadata with hashes and retention policy.
- Define schedules for `harden-lock`.
- Decide which harden outputs are release evidence versus hard gates.
- Replace metadata-only reports with real fixture-backed jobs.

### 4. Sanitizers

Current status:

- ASan/UBSan is green locally and on Hydra.
- TSan is green locally and on Hydra.
- MSan is build-only and green locally/on Hydra.

Remaining work:

- Observe ASan/UBSan and TSan across more Hydra evaluations before making them
  required gates.
- Package instrumented dependencies before turning MSan into a runtime test.
- Map MSan fuzzing to scheduled harden work once instrumented dependencies and
  corpus storage exist.

### 5. Benchmarks

Current status:

- `bench-sanity` is green on Hydra.
- Will Clark's benchmark ideas were translated into the Ironworks model rather
  than imported as mutable queue-runner state.

Remaining work:

- Add real benchmark artifact storage.
- Decide benchmark worker topology.
- Define baseline selection and comparison policy.
- Record how release managers review and accept/reject regressions before
  `stamp`.

Benchmarks should inform `temper` and `stamp`; they should not become automatic
CI blockers until the noise profile is measured.

### 6. Hydra Production Operations

Remaining operational work:

- Put authentication in front of `hydra.2140.dev` before treating it as a
  production service. Public read-only can be revisited later, but write/admin
  surfaces should not be exposed.
- Finish DNS/TLS/reverse-proxy policy if it is not already deployed.
- Investigate intermittent TLS reset warnings from
  `https://2140-dev.cachix.org`.
- Install out-of-git cache signing/upload credentials if Hydra should publish
  signed outputs.
- Define backup, GC, retention, and disk-pressure policy.
- Enable branch protection for Ironworks, Saugus, and source branches after the
  bootstrap workflow is stable.
- Decide whether production Hydra evaluations are triggered by polling,
  webhook, or explicit lock-branch promotion command.

### 7. Host Safety

The host is currently usable, but future NixOS changes should be handled
conservatively because SSH access was previously lost during boot attempts.

Before host config changes:

- Confirm current generation and configuration revision.
- Run local evaluation/build first.
- Keep vKVM or Rescue available for rollback.
- Avoid unsolicited reboot/power-cycle actions.
- Preserve the Hetzner boot fixes in `modules/hetzner-bare-metal.nix` and the
  Hydra host config unless a replacement is tested.

Post-switch checks:

```sh
nixos-version --configuration-revision
zpool status
systemctl status hydra-init hydra-evaluator hydra-queue-runner
```

### 8. Other 2140 Repos

`flotilla` and `roost` exist under the `2140-dev` org, but they were not part
of the completed Forge wiring baseline. Revisit them separately and decide
whether they are consumers of Ironworks, Saugus-managed services, or unrelated
deployment concerns.

## Suggested Tomorrow Sequence

1. Check Saugus `master`, `staging-lock`, and Ironworks `master` are clean and
   pushed.
2. Reconfirm Hydra eval `16` build range `206`-`219` is still green.
3. Investigate analysis jobs `clang-tidy-report` and `iwyu-report`.
4. Decide which Forge jobs become required after observation.
5. Decide auth policy for `hydra.2140.dev`.
6. Plan legacy CI cutover job-by-job; do not disable everything at once.
7. Pick the next parity item to implement: ancestor commits, lint parity, or
   analysis-job reliability are the best immediate candidates.
