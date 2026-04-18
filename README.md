# ksh93.nix

[ksh93u+m](https://github.com/ksh93/ksh) — the actively maintained KornShell fork — packaged for Nix, with first-class NixOS / nix-darwin / home-manager module support via [sh.nix](https://github.com/lane-core/sh.nix).

## Quick start

### 1. Add the flake input

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    ksh93.url = "github:lane-core/ksh93.nix";
  };

  outputs = { self, nixpkgs, home-manager, ksh93, ... }:
    # see below for NixOS, home-manager, or nix-darwin
}
```

### 2. Use the overlay (optional but recommended)

The overlay provides `pkgs.ksh` pointing to ksh93u+m:

```nix
# In your nixosConfiguration or homeConfiguration
nixpkgs.overlays = [ ksh93.overlays.default ];
```

Without the overlay, the module defaults to `pkgs.ksh` from nixpkgs (which may be an older version).

---

## NixOS

```nix
# flake.nix
outputs = { self, nixpkgs, ksh93, ... }:
  let
    system = "x86_64-linux"; # or aarch64-linux
    pkgs = import nixpkgs {
      inherit system;
      overlays = [ ksh93.overlays.default ];
    };
  in {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      inherit system pkgs;
      modules = [
        ksh93.nixosModules.ksh
        ./configuration.nix
      ];
    };
  };
```

```nix
# configuration.nix
{ config, pkgs, ... }: {
  programs.ksh = {
    enable = true;

    # The overlay provides pkgs.ksh = ksh93u+m
    # package = pkgs.ksh;  # default

    shellAliases = {
      ll = "ls -l";
      la = "ls -la";
    };

    interactiveShellInit = ''
      set -o vi
    '';

    # ksh93-specific options
    histfile = "$HOME/.ksh_history";
    histsize = 10000;
  };

  # Optional: make ksh the default shell for a user
  users.users.lane.shell = pkgs.ksh;
}
```

### How NixOS module works

ksh93 hardcodes `/etc/profile` for login shells, which conflicts with bash's `/etc/profile` on NixOS. Instead of writing a conflicting file, the module:

1. **Does not write `/etc/profile`** — relies on bash's existing file
2. **Writes `/etc/kshrc`** — the interactive startup file
3. **Sets `ENV=/etc/kshrc` globally** — via `environment.variables`, picked up by `setEnvironment`

When ksh93 starts as a login shell:
- Reads `/etc/profile` (bash's file) → sources `setEnvironment` → `ENV` is set
- Starts interactive phase → reads `$ENV` → `/etc/kshrc`

---

## Home Manager

```nix
# flake.nix
outputs = { self, nixpkgs, home-manager, ksh93, ... }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      overlays = [ ksh93.overlays.default ];
    };
  in {
    homeConfigurations.lane = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        ksh93.homeManagerModules.ksh
        ./home.nix
      ];
    };
  };
```

```nix
# home.nix
{ config, pkgs, ... }: {
  programs.ksh = {
    enable = true;

    shellAliases = {
      g = "git";
    };

    interactiveShellInit = ''
      # Personal ksh config
      set -o emacs
    '';
  };
}
```

### How home-manager module works

The module writes:
- `~/.profile` — sources `hm-session-vars.sh`, exports `ENV=~/.kshrc`
- `~/.kshrc` — interactive shell config (aliases, initExtra, etc.)

---

## nix-darwin

```nix
# flake.nix
outputs = { self, nixpkgs, darwin, ksh93, ... }:
  let
    system = "aarch64-darwin";
    pkgs = import nixpkgs {
      inherit system;
      overlays = [ ksh93.overlays.default ];
    };
  in {
    darwinConfigurations.mymac = darwin.lib.darwinSystem {
      inherit system pkgs;
      modules = [
        ksh93.darwinModules.ksh
        ./darwin-configuration.nix
      ];
    };
  };
```

```nix
# darwin-configuration.nix
{ config, pkgs, ... }: {
  programs.ksh = {
    enable = true;

    shellAliases = {
      ls = "ls -G";
    };
  };
}
```

### How nix-darwin module works

Unlike NixOS, nix-darwin does not manage `/etc/profile` the same way. The module writes:
- `/etc/profile` — login shell setup
- `/etc/kshrc` — interactive shell setup (with `ENV=/etc/kshrc` exported from profile)

---

## Module options

The module extends the POSIX shell base from [sh.nix](https://github.com/lane-core/sh.nix) with ksh93-specific options:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `programs.ksh.enable` | `bool` | `false` | Enable the ksh module |
| `programs.ksh.package` | `package` | `pkgs.ksh` | The ksh package to use |
| `programs.ksh.shellAliases` | `attrsOf str` | `{}` | Shell aliases |
| `programs.ksh.shellInit` | `lines` | `""` | Run for all shells |
| `programs.ksh.loginShellInit` | `lines` | `""` | Run for login shells |
| `programs.ksh.interactiveShellInit` | `lines` | `""` | Run for interactive shells |
| `programs.ksh.promptInit` | `lines` | `""` | Prompt configuration |
| `programs.ksh.logoutExtra` | `lines` | `""` | Run on logout |
| `programs.ksh.histfile` | `nullOr str` | `"${HOME}/.ksh_history"` | History file path |
| `programs.ksh.histsize` | `int` | `10000` | Number of history entries |

---

## Shell integration for other tools

Other home-manager modules can integrate with ksh via `home.shell.enableKshIntegration`:

```nix
{ config, ... }: {
  programs.direnv = {
    enable = true;
    enableKshIntegration = true;  # adds direnv hook to ksh
  };
}
```

This follows the same pattern as `enableBashIntegration`, `enableZshIntegration`, and `enableFishIntegration`.

---

## Building from source

```bash
# Build the stable release
nix build github:lane-core/ksh93.nix#ksh

# Build the nightly (dev branch)
nix build github:lane-core/ksh93.nix#ksh-nightly
```

---

## License

EPL-2.0 (same as upstream ksh93)
