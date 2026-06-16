default:
    just --list

deploy target:
    nix run github:nix-community/nixos-anywhere -- --flake .#hydra {{target}}

switch-remote target:
    nixos-rebuild switch --flake .#hydra --target-host {{target}} --use-remote-sudo
