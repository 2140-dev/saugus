# Saugus

Saugus is the 2140 deployment of Ironworks.

Ironworks defines the reusable build, CI, release, and infrastructure library.
Saugus consumes that library for the 2140 production deployment: Hydra,
builders, benchmark workers, cache policy, lock branches, host inventory, and
operational runbooks.

The local bootstrap currently points at local paths:

```text
ironworks -> /home/josie/2140-node-packaging
node      -> /home/josie/2140-node
```

After publishing the repositories, switch those inputs to:

```text
github:2140-dev/ironworks
git+https://github.com/2140-dev/bitcoin.git?rev=<locked-source-sha>
```

## Evaluation

```sh
nix fmt
nix flake check --no-build --all-systems --print-build-logs
nix eval .#hydraJobs.x86_64-linux --apply builtins.attrNames
nix eval .#nixosConfigurations.hydra.config.services.hydra.hydraURL
```

Current active jobsets are `correctness`, `staging`, and `release`, which map
to Ironworks `spark`, `forge`, and `temper`. `harden` is implemented in
Ironworks but remains disabled in Saugus with `ironworks.lib.mkStageConfig`
until fixture storage and scheduling policy are approved. `stamp` remains
visible through the Ironworks stage catalog but is not exported as an active
jobset yet.

## Host

The initial Hydra host is exposed as:

```text
nixosConfigurations.hydra
```

The host is installable through `nixos-anywhere` once the real Hetzner NVMe
device IDs are written into `hosts/hydra/disko.nix`.

See `docs/install.md` for the Rescue boot, disk inventory, install, and first
login flow. See `docs/cache.md` for the current binary cache trust settings.
