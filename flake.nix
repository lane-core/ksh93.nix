{
  description = "ksh93u+m — the actively maintained KornShell fork";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-utils.url = "github:numtide/flake-utils";
    shnix.url = "github:lane-core/sh.nix";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-parts,
      flake-utils,
      shnix,
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      flake =
        let
          base = shnix.lib.mkPosixShellModule {
            name = "ksh";
            etcRcPath = "kshrc";
            homeRcPath = ".kshrc";
          };

          # ksh93-specific options, wired into programs.ksh.initExtra.
          kshOptions =
            { config, lib, ... }:
            let
              cfg = config.programs.ksh;
            in
            {
              options.programs.ksh = {
                shellOptions = lib.mkOption {
                  type = with lib.types; listOf str;
                  default = [ ];
                  description = "Shell options to enable via `set -o`.";
                };

                functionsDir = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "Directory for autoload functions (sets FPATH).";
                };
              };

              config.programs.ksh = {
                # ksh93 defaults: larger history than the generic POSIX default.
                histSize = lib.mkDefault 10000;

                initExtra = lib.mkIf cfg.enable (lib.mkAfter ''
                  ${lib.concatMapStringsSep "\n" (o: "set -o ${o}") cfg.shellOptions}
                  ${lib.optionalString (cfg.functionsDir != null) ''
                    export FPATH="${cfg.functionsDir}:''${FPATH:-/usr/share/ksh/functions}"
                  ''}
                '');
              };
            };
        in
        {
          overlays.default = final: prev: {
            ksh = final.callPackage ./packages/stable.nix { };
          };

          nixosModules.ksh = { config, lib, pkgs, ... }: {
            imports = [ base.nixosModule kshOptions ];
          };

          darwinModules.ksh = { config, lib, pkgs, ... }: {
            imports = [ base.darwinModule kshOptions ];
          };

          homeManagerModules.ksh = { config, lib, pkgs, ... }: {
            imports = [ base.homeManagerModule kshOptions ];
          };
        };

      systems = flake-utils.lib.defaultSystems;

      perSystem =
        {
          config,
          self',
          inputs',
          pkgs,
          system,
          ...
        }:
        {
          packages.ksh = pkgs.callPackage ./packages/stable.nix { };
          packages.ksh-nightly = pkgs.callPackage ./packages/nightly.nix { };
          packages.default = config.packages.ksh;
        };
    };
}
