{
  description = "Saugus: the 2140 production deployment of Ironworks";

  nixConfig = {
    extra-substituters = [ "https://2140-dev.cachix.org" ];
    extra-trusted-public-keys = [
      "2140-dev.cachix.org-1:0brdoxVmXjL5udKuI+vXXwdEjPInGQKjCiyJLReZBt8="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ironworks.url = "path:/home/josie/2140-node-packaging";
    node = {
      url = "path:/home/josie/2140-node";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      disko,
      ironworks,
      node,
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllSystems =
        f: nixpkgs.lib.genAttrs supportedSystems (system: f nixpkgs.legacyPackages.${system});

      mkFormatCheck =
        pkgs:
        pkgs.runCommand "saugus-format-check"
          {
            nativeBuildInputs = [
              pkgs.findutils
              pkgs.nixfmt
            ];
            src = self.outPath;
          }
          ''
            cp -R "$src" source
            chmod -R u+w source
            cd source

            find . -name '*.nix' -print0 | xargs -0 nixfmt --check
            touch "$out"
          '';

      mkProject =
        pkgs:
        ironworks.lib.mkProject {
          inherit pkgs;
          adapter = ironworks.lib.projectAdapters."2140-node";
          src = node;
          flakeLock = ./flake.lock;
          treefmtCheck = mkFormatCheck pkgs;
          config = {
            projectId = "2140-node";
            deploymentId = "saugus";
            stages = ironworks.lib.mkStageConfig {
              disable = [
                "harden"
                "stamp"
              ];
            };
          };
        };

      mkChecks =
        pkgs:
        let
          project = mkProject pkgs;
        in
        project.checks
        // {
          saugus-update-lock =
            pkgs.runCommand "saugus-update-lock-smoke"
              {
                nativeBuildInputs = [ pkgs.python3 ];
              }
              ''
                python3 -m py_compile ${./apps/update-lock.py}
                python3 ${./apps/update-lock.py} \
                  --source-rev 0000000000000000000000000000000000000000 \
                  --ironworks-rev 1111111111111111111111111111111111111111 \
                  --dry-run \
                  --no-switch \
                  --no-commit \
                  staging > smoke.log
                grep -q "staging-lock" smoke.log
                grep -q "locks/staging.json" smoke.log
                touch "$out"
              '';

          saugus-consumer-api =
            pkgs.runCommand "saugus-consumer-api"
              {
                activeJobsets = builtins.toJSON (builtins.attrNames project.hydraJobs);
                activeChecks = builtins.toJSON (builtins.attrNames project.checks);
                canonicalStages = builtins.toJSON (builtins.attrNames ironworks.lib.stages);
                canonicalStageNames = builtins.toJSON ironworks.lib.stageNames;
                stageJobsets = builtins.toJSON (builtins.attrNames project.stageHydraJobs);
                stageConfig = builtins.toJSON {
                  harden = project.meta.stages.harden.enable;
                  stamp = project.meta.stages.stamp.enable;
                };
              }
              ''
                test "$activeJobsets" = '["correctness","release","staging"]'
                case "$activeChecks" in
                  *scheduled*) exit 1 ;;
                esac
                test "$canonicalStages" = '["forge","harden","spark","stamp","temper"]'
                test "$canonicalStageNames" = "$canonicalStages"
                test "$stageJobsets" = "$canonicalStages"
                test "$stageConfig" = '{"harden":false,"stamp":false}'

                {
                  echo "activeJobsets=$activeJobsets"
                  echo "activeChecks=$activeChecks"
                  echo "canonicalStages=$canonicalStages"
                  echo "canonicalStageNames=$canonicalStageNames"
                  echo "stageJobsets=$stageJobsets"
                  echo "stageConfig=$stageConfig"
                } > "$out"
              '';
        };
    in
    {
      packages = forAllSystems (pkgs: (mkProject pkgs).packages);

      checks = forAllSystems mkChecks;

      hydraJobs = forAllSystems (pkgs: (mkProject pkgs).hydraJobs);

      nixosConfigurations.hydra = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit self; };
        modules = [
          disko.nixosModules.disko
          ./modules/common.nix
          ./modules/hetzner-bare-metal.nix
          ironworks.nixosModules.hydra-controller
          ./hosts/hydra/configuration.nix
        ];
      };

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [
            pkgs.git
            pkgs.nixos-anywhere
            pkgs.nixos-rebuild
          ];
        };
      });

      apps = forAllSystems (
        pkgs:
        let
          updateLock = pkgs.writeShellApplication {
            name = "update-lock";
            runtimeInputs = [
              pkgs.git
              pkgs.nix
              pkgs.python3
            ];
            text = ''
              exec ${pkgs.python3}/bin/python3 ${./apps/update-lock.py} "$@"
            '';
          };
        in
        {
          update-lock = {
            type = "app";
            program = "${updateLock}/bin/update-lock";
            meta.description = "Update Saugus staging and release lock branches";
          };
        }
      );

      formatter = forAllSystems (
        pkgs:
        pkgs.writeShellApplication {
          name = "saugus-format";
          runtimeInputs = [
            pkgs.findutils
            pkgs.nixfmt
          ];
          text = ''
            if [ "$#" -gt 0 ]; then
              exec nixfmt "$@"
            fi

            find . -name '*.nix' -print0 | xargs -0 nixfmt
          '';
        }
      );
    };
}
