<h3 align="center">
 <br/>
 <img src="https://raw.githubusercontent.com/catppuccin/catppuccin/main/assets/misc/transparent.png" height="30" width="0px"/>
  NixOS Config for <a href="https://github.com/kaynetik">kaynetik</a>
 <img src="https://raw.githubusercontent.com/catppuccin/catppuccin/main/assets/misc/transparent.png" height="30" width="0px"/>
</h3>

<p align="center">
 <a href="https://github.com/kaynetik/kaynix/commits"><img src="https://img.shields.io/github/last-commit/kaynetik/kaynix?colorA=363a4f&colorB=f5a97f&style=for-the-badge" alt="Last commit"></a>
 <a href="https://github.com/kaynetik/kaynix/actions/workflows/security.yml"><img src="https://img.shields.io/github/actions/workflow/status/kaynetik/kaynix/security.yml?branch=main&amp;colorA=363a4f&amp;style=for-the-badge&amp;logo=github&amp;logoColor=d8dee9&amp;label=Security" alt="Security CI workflow status"></a>
 <a href="https://github.com/kaynetik/kaynix/blob/main/.github/workflows/security.yml"><img src="https://img.shields.io/static/v1?label=CI%20runners&amp;message=Ubuntu%20%26%20macOS&amp;labelColor=363a4f&amp;color=cad3f5&amp;logo=githubactions&amp;logoColor=d8dee9&amp;style=for-the-badge" alt="CI runs on Ubuntu and macOS"></a>
 <a href="https://github.com/kaynetik/kaynix/blob/main/LICENSE"><img src="https://img.shields.io/github/license/kaynetik/kaynix?colorA=363a4f&colorB=b7bdf8&style=for-the-badge" alt="License"></a>

 <a href="https://wiki.nixos.org/wiki/Flakes" target="_blank">
 <img alt="Nix Flakes Ready" src="https://img.shields.io/static/v1?logo=nixos&logoColor=d8dee9&label=Nix%20Flakes&labelColor=5e81ac&message=Ready&color=d8dee9&style=for-the-badge">
 </a>
</p>

---

# kaynix

Personal [nix-darwin](https://github.com/nix-darwin/nix-darwin) flake with [Home Manager](https://github.com/nix-community/home-manager) and [sops-nix](https://github.com/Mic92/sops-nix). System modules live under `modules/`; user config is `homes/kaynetik.nix`.

## Prerequisites

1. **Install Nix** via the [Determinate Systems installer](https://github.com/DeterminateSystems/nix-installer) (recommended -- enables flakes and the `nix` CLI out of the box):

```bash
curl --proto '=https' --tlsv1.2 -sSf -L \
  https://install.determinate.systems/nix | sh -s -- install
```

2. **Install [Homebrew](https://brew.sh/)** -- required for the casks and brews declared in `modules/apps.nix` (GUI apps and CLI tools not packaged in nixpkgs):

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

3. **Familiarize yourself** with `flake.nix`, `modules/`, and `homes/kaynetik.nix` before switching. For background on flakes and nix-darwin, [ryan4yin/nixos-and-flakes-book](https://github.com/ryan4yin/nixos-and-flakes-book) is a solid intro.

## First deploy

The flake defines per-host entries in the `hosts` attrset inside `flake.nix` (currently `knt-mbp` and `knt-mbpf`). Replace `HOSTNAME` below with whichever entry matches your machine, or add a new one first.

```bash
# 1. Clone the repo
git clone https://github.com/kaynetik/kaynix.git
cd kaynix

# 2. Build the system derivation
nix build .#darwinConfigurations.HOSTNAME.system

# 3. Apply (first run bootstraps nix-darwin + Home Manager)
./result/sw/bin/darwin-rebuild switch --flake .#HOSTNAME
```

Subsequent rebuilds only need step 3 (or `darwin-rebuild switch --flake .#HOSTNAME` once nix-darwin is on `$PATH`).

## Architecture

```mermaid
graph TD
    subgraph inputs["Flake Inputs"]
        NP["nixpkgs-darwin<br/><i>follows nixpkgs-unstable</i>"]
        DW["darwin<br/><i>nix-darwin</i>"]
        HMI["home-manager"]
        SOPS["sops-nix"]
    end

    F["flake.nix<br/>hosts: knt-mbp, knt-mbpf<br/>+ devShells, formatter"]

    subgraph darwin["darwinConfigurations (per host)"]
        direction LR
        NC["nix-core.nix<br/>nixpkgs, overlays, GC"]
        SYS["system.nix<br/>macOS defaults, Touch ID"]
        APPS["apps.nix<br/>Homebrew, fonts, SketchyBar"]
        HU["host-users.nix<br/>hostname, DNS, users"]
        AERO["aerospace.nix<br/>tiling WM"]
        SEC["secrets.nix<br/>writable secrets dir"]
    end

    subgraph hm["Home Manager (embedded in darwin)"]
        KN["homes/kaynetik.nix<br/>program toggles, session"]
        SOPS_HM["homes/sops.nix<br/>secret paths, activation, rekey"]

        subgraph hmmod["modules/home/"]
            direction LR
            PKG["packages.nix<br/>CLI tools, runtimes, scripts/"]
            PROGS["programs/*<br/>zsh, git, neovim, tmux,<br/>terminals, ssh, fzf, atuin,<br/>sketchybar, lazygit, jujutsu, ..."]
        end

        STATIC["homes/static/<br/>nvim, tmux, alacritty,<br/>sketchybar, zsh, git, sops"]
    end

    inputs --> F
    F --> darwin
    darwin -- "darwinModules.home-manager" --> hm
    KN --> SOPS_HM
    KN --> hmmod
    PROGS --> STATIC
    SOPS["sops-nix"] -. "sharedModules" .-> SOPS_HM
```

## Secrets (SOPS + YubiKey)

Secrets are encrypted at rest in `secrets/secrets.yaml`, decrypted at Home Manager activation by sops-nix. See `secrets/README.md` for editing and `yubikey.md` for the full YubiKey setup.

```mermaid
flowchart LR
    YK["YubiKey (PIV slot)"]
    PLUGIN["age-plugin-yubikey"]
    ID["~/.config/sops/age/<br/>identity stub"]
    SOPSF["secrets/secrets.yaml<br/>(encrypted)"]
    SOPSNIX["sops-nix<br/>(HM activation)"]
    PLAIN["~/.config/zsh/conf-*.zsh<br/>~/.ssh/conf.d/work<br/>(decrypted, 0600)"]

    YK -- "PIV PIN + touch" --> PLUGIN
    PLUGIN --> ID
    ID --> SOPSNIX
    SOPSF --> SOPSNIX
    SOPSNIX --> PLAIN
```

## Layout

```text
.
├── flake.nix          # inputs, hosts, darwinConfigurations, devShells
├── flake.lock
├── modules/           # nix-darwin system modules + modules/home/ (HM programs)
├── homes/
│   ├── kaynetik.nix   # Home Manager user config (program toggles)
│   ├── sops.nix       # sops-nix secret paths, activation, rekey script
│   └── static/        # dotfiles: nvim, tmux, alacritty, sketchybar, zsh, git
├── secrets/           # sops-encrypted secrets (see secrets/README.md)
└── scripts/           # helper scripts installed into home.packages
```
