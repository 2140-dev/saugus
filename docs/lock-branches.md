# Lock Branches

Hydra should evaluate Saugus lock branches, not mutable source branches.

Each lock branch records:

- source repository and commit
- Ironworks repository and commit
- nixpkgs input from `flake.lock`
- selected Hydra stage in `locks/hydra-stage.json`
- UTC update timestamp

## Staging

After a source PR is promoted to `staging`, update the Saugus staging lock:

```sh
nix run .#update-lock -- \
  --source-rev <source-sha> \
  --ironworks-rev <ironworks-sha> \
  staging
```

This updates `flake.nix`, updates `flake.lock`, writes `locks/staging.json`,
writes `locks/hydra-stage.json` with `forge`/`staging`, commits the result, and
leaves the branch named `staging-lock`.

Dry-run:

```sh
nix run .#update-lock -- \
  --source-rev <source-sha> \
  --ironworks-rev <ironworks-sha> \
  --dry-run \
  staging
```

## Harden

After a staging snapshot is ready for scheduled validation, update the Saugus
harden lock:

```sh
nix run .#update-lock -- \
  --source-rev <source-sha> \
  --ironworks-rev <ironworks-sha> \
  harden
```

This writes `locks/harden.json`, writes `locks/hydra-stage.json` with
`harden`/`scheduled`, commits the result, and leaves the branch named
`harden-lock`.

## Release

For a release candidate:

```sh
nix run .#update-lock -- \
  --source-rev <source-sha> \
  --ironworks-rev <ironworks-sha> \
  release --version <version>
```

The default branch is `release-lock/<version>` and the metadata file is
`locks/release/<version>.json`. Release lock branches write
`locks/hydra-stage.json` with `temper`/`release`.

## Push

Pass `--push` only after reviewing the lock update locally:

```sh
nix run .#update-lock -- \
  --source-rev <source-sha> \
  --ironworks-rev <ironworks-sha> \
  --push \
  staging
```

Until `2140-dev/ironworks` and `2140-dev/saugus` are published, use `--dry-run`
only. The production helper pins GitHub inputs, while the local bootstrap still
uses path inputs.
