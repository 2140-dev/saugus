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

Initial active jobsets:

| Identifier | Type | Flake URI | Scheduling | Keep |
| --- | --- | --- | --- | --- |
| `spark` | Flake | `github:2140-dev/saugus` | Optional Hydra mirror of Spark | 20 |
| `forge` | Flake | `github:2140-dev/saugus/staging-lock` | Every promoted staging snapshot | 50 |
| `temper` | Flake | `github:2140-dev/saugus/release-lock/<version>` | Every release candidate update | 20 |

Expected outputs:

| Jobset | Output |
| --- | --- |
| `spark` | `hydraJobs.x86_64-linux.correctness` |
| `forge` | `hydraJobs.x86_64-linux.staging` |
| `temper` | `hydraJobs.x86_64-linux.release` |

Planned stage handles:

| Stage | Flake output | Condition |
| --- | --- | --- |
| `harden` | `hydraJobs.x86_64-linux.scheduled` | Add after Saugus enables the stage and real fixture/corpus policies are approved |
| `stamp` | `hydraJobs.x86_64-linux.stamp` | Add after release publication jobs exist and Saugus enables the stage |

The Ironworks harden output currently contains these handles:

```text
required
ibd-small
previous-releases
fuzz-corpus
benchmark-artifact
```

Only enable the Saugus `harden` jobset after the storage-backed fixtures and
schedule are decided; the current IBD, previous-release, and fuzz-corpus jobs
are metadata scaffolds.

Do not let production jobsets chase mutable source refs directly.
