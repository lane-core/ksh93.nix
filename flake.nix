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
                etcName = "profile";
                homePath = ".profile";
                when = "login";
                envVar = null;
              };

              rc = {
                etcName = "kshrc";
                homePath = ".kshrc";
                when = "interactive";
                envVar = "ENV";
              };
            };

            # ksh93-specific programmable options.
            programmableOptions = {
              shellOptions = {
                type = with nixpkgs.lib.types; listOf str;
                default = [ ];
                description = "Shell options to enable via set -o";
                target = "interactiveShellInit";
                generator = opts: nixpkgs.lib.concatMapStringsSep "\n" (o: "set -o ${o}") opts;
              };

              functionsDir = {
                type = nixpkgs.lib.types.nullOr nixpkgs.lib.types.str;
                default = null;
                description = "Directory for autoload functions (sets FPATH)";
                target = "interactiveShellInit";
                generator = dir: ''
                  export FPATH="${dir}:''${FPATH:-/usr/share/ksh/functions}"
                '';
              };

              histfile = {
                type = nixpkgs.lib.types.nullOr nixpkgs.lib.types.str;
                default = null;
                description = "Path to the ksh history file";
                target = "interactiveShellInit";
                generator = path: ''HISTFILE="${path}"'' + "\n";
              };

              histsize = {
                type = nixpkgs.lib.types.int;
                default = 10000;
                description = "Number of history entries to keep";
                target = "interactiveShellInit";
                generator = n: "HISTSIZE=${toString n}\n";
              };

              initExtra = {
                type = nixpkgs.lib.types.lines;
                default = "";
                description = "Extra shell commands for interactive initialisation";
                target = "interactiveShellInit";
                generator = nixpkgs.lib.id;
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
