# Hydra Jobsets

Hydra should evaluate Saugus, not Ironworks directly. Saugus pins the source
tree, Ironworks revision, and nixpkgs revision in its lock file.

Initial project:

```text
saugus
```

Project fields:

| Field | Value |
| --- | --- |
| Identifier | `saugus` |
| Display name | `Saugus` |
| Description | `2140 production deployment of Ironworks` |
| Enabled | yes |
| Visible | yes |

Hydra flake jobsets should point at Saugus, because Saugus pins the source
tree, Ironworks, and nixpkgs in `flake.lock`.

Active jobsets:

| Identifier | Type | Flake URI | Scheduling | Keep |
| --- | --- | --- | --- | --- |
| `spark` | Flake | `github:2140-dev/saugus` | Optional Hydra mirror of Spark | 20 |
| `forge` | Flake | `github:2140-dev/saugus/staging-lock` | Every promoted staging snapshot | 50 |
| `harden` | Flake | `github:2140-dev/saugus/harden-lock` | Scheduled after forge-green snapshots | 20 |
| `temper` | Flake | `github:2140-dev/saugus/release-lock/<version>` | Every release candidate update | 20 |

Expected outputs:

| Jobset | Output |
| --- | --- |
| `spark` | `hydraJobs.x86_64-linux.correctness` |
| `forge` | `hydraJobs.x86_64-linux.staging` |
| `harden` | `hydraJobs.x86_64-linux.scheduled` |
| `temper` | `hydraJobs.x86_64-linux.release` |

Hydra evaluates the whole `hydraJobs` tree for a flake jobset. Saugus prevents
duplicate runs by filtering `hydraJobs` through `locks/hydra-stage.json` on each
production branch:

| Branch | Selector | Published jobset |
| --- | --- | --- |
| `master` | default `spark` | `correctness` |
| `staging-lock` | `forge` | `staging` |
| `harden-lock` | `harden` | `scheduled` |
| `release-lock/<version>` | `temper` | `release` |

Planned stage handles:

| Stage | Flake output | Condition |
| --- | --- | --- |
| `stamp` | `hydraJobs.x86_64-linux.stamp` | Add after release publication jobs exist and Saugus enables the stage |

The Ironworks harden output currently contains these handles:

```text
required
ibd-small
previous-releases
fuzz-corpus
benchmark-artifact
benchmark-report
```

The Saugus `harden` jobset is enabled so Hydra can evaluate the scheduled
surface now. The current IBD, previous-release, and fuzz-corpus jobs are still
metadata scaffolds until storage-backed fixtures and the final schedule are
approved.

Do not let production jobsets chase mutable source refs directly.
