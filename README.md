# Saugus

Saugus is the 2140 deployment of Ironworks.

Ironworks defines the reusable build, CI, release, and infrastructure library.
Saugus consumes that library for the 2140 production deployment: Hydra,
builders, benchmark workers, cache policy, lock branches, host inventory, and
operational runbooks.

The deployment flake consumes the production repositories:

```text
github:2140-dev/ironworks
git+https://github.com/2140-dev/bitcoin.git?ref=master
```

`staging-lock` and `release-lock/<version>` branches replace the source ref
with exact source and Ironworks revisions before Hydra evaluates `forge` or
`temper`.

## Evaluation

```sh
nix fmt
nix flake check --no-build --all-systems --print-build-logs
nix eval .#hydraJobs.x86_64-linux --apply builtins.attrNames
nix eval .#nixosConfigurations.hydra.config.services.hydra.hydraURL
```

Saugus exports a stage-filtered `hydraJobs` tree for production Hydra. `master`
defaults to `spark`/`correctness`; lock branches write `locks/hydra-stage.json`
so `staging-lock` exposes `forge`/`staging`, `harden-lock` exposes
`harden`/`scheduled`, and release lock branches expose `temper`/`release`. This
keeps Hydra flake jobsets from duplicating the full Ironworks graph.

The `scheduled` harden jobset is exported for observation while fixture-backed
IBD, previous-release, and long-fuzz jobs are still being replaced. `stamp`
remains visible through the Ironworks stage catalog but is not exported as an
active jobset yet.

## Host

The initial Hydra host is exposed as:

```text
nixosConfigurations.hydra
```

The host is installable through `nixos-anywhere`; `hosts/hydra/disko.nix`
currently targets the discovered Hetzner disks on `167.235.5.73`.

See `docs/install.md` for the Rescue boot, disk inventory, install, and first
login flow. See `docs/cache.md` for the current binary cache trust settings.
