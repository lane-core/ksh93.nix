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
          kshModules = shnix.lib.mkPosixShellModule {
            name = "ksh";
            # Default to pkgs.ksh (resolved via overlay at evaluation time).
            package = "ksh";

            initFiles = {
              profile = {
                # Don't write /etc/profile on NixOS — bash already manages it.
                nixos = null;
                homeManager = {
                  homePath = ".profile";
                };
                darwin = {
                  etcName = "profile";
                };
                when = "login";
                envVar = null;
              };
              rc = {
                nixos = {
                  etcName = "kshrc";
                };
                homeManager = {
                  homePath = ".kshrc";
                };
                darwin = {
                  etcName = "kshrc";
                };
                when = "interactive";
                envVar = "ENV";
              };
            };
          };
        in
        {
          overlays.default = final: prev: {
            ksh = final.callPackage ./packages/stable.nix { };
          };

          nixosModules.ksh = kshModules.nixosModule;
          homeManagerModules.ksh = kshModules.homeManagerModule;
          darwinModules.ksh = kshModules.darwinModule;
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
