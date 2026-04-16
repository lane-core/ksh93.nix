{
  description = "ksh93u+m — the actively maintained KornShell fork";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-parts,
      flake-utils,
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      flake = {
        overlays.default = final: prev: {
          ksh = final.callPackage ./packages/stable.nix { };
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
