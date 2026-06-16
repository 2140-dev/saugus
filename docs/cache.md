# Binary Cache

Saugus currently standardizes on the public `2140-dev` Cachix cache for
substitution:

```text
https://2140-dev.cachix.org
2140-dev.cachix.org-1:0brdoxVmXjL5udKuI+vXXwdEjPInGQKjCiyJLReZBt8=
```

This repo only commits public trust configuration. Signing credentials and
upload tokens stay outside git.

## Developers

For one-off use, run commands through this flake and accept its `nixConfig`.
For persistent machine config, add:

```nix
{
  nix.settings.substituters = [ "https://2140-dev.cachix.org" ];
  nix.settings.trusted-public-keys = [
    "2140-dev.cachix.org-1:0brdoxVmXjL5udKuI+vXXwdEjPInGQKjCiyJLReZBt8="
  ];
}
```

## Hosted Spark

The source repository Spark workflow adds the same substituter through
`cachix/install-nix-action`, so hosted GitHub runners can reuse public outputs.

## Hydra

`modules/common.nix` configures the Hydra host to trust the org cache for
substitution. Publishing signed Hydra outputs still needs an out-of-git secret:

```nix
{
  nix.settings.secret-key-files = [ "/run/secrets/nix-cache-signing-key" ];
}
```

Only enable that once the cache signing key has been created and installed on
the Hydra host.
