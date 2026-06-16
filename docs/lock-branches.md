# Lock Branches

Hydra should evaluate Saugus lock branches, not mutable source branches.

Each lock branch records:

- source repository and commit
- Ironworks repository and commit
- nixpkgs input from `flake.lock`
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
commits the result, and leaves the branch named `staging-lock`.

Dry-run:

```sh
nix run .#update-lock -- \
  --source-rev <source-sha> \
  --ironworks-rev <ironworks-sha> \
  --dry-run \
  staging
```

## Release

For a release candidate:

```sh
nix run .#update-lock -- \
  --source-rev <source-sha> \
  --ironworks-rev <ironworks-sha> \
  release --version <version>
```

The default branch is `release-lock/<version>` and the metadata file is
`locks/release/<version>.json`.

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
