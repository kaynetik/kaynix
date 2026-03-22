{
  description = "Nix for macOS [darwin]";

  # the nixConfig here only affects the flake itself, not the system configuration!
  nixConfig = {
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs.follows = "nixpkgs-darwin";

    darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
  };

  # `inputs @ { ... }` binds flake inputs by name; `self` is the flake itself.
  outputs = inputs @ {
    self,
    nixpkgs,
    nixpkgs-darwin,
    darwin,
    home-manager,
    sops-nix,
    ...
  }: let
    # FIXME: Update in case username changes, or this is deployed to a new Mac.
    username = "kaynetik";
    system = "aarch64-darwin"; # aarch64-darwin (M-series) or x86_64-darwin
    hostname = "knt-mbp";

    specialArgs =
      inputs
      // {
        inherit username hostname;
      };
  in {
    darwinConfigurations."${hostname}" = darwin.lib.darwinSystem {
      inherit system specialArgs;
      modules = [
        ./modules/nix-core.nix
        ./modules/system.nix
        ./modules/apps.nix
        ./modules/aerospace.nix
        ./modules/host-users.nix
        ./modules/secrets.nix

        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.sharedModules = [sops-nix.homeManagerModules.sops];
          # First switch: rename any plain files that block HM into *.hm-backup, then link from the store.
          home-manager.backupFileExtension = "hm-backup";
          # zinit stays on Homebrew (nixpkgs zinit is problematic); zsh is managed in homes/kaynetik.nix.
          home-manager.users.kaynetik = import ./homes/kaynetik.nix;
        }

        # Minimal inline module for user directory setup (Home Manager owns git + listed dotfiles)
        {
          system.activationScripts.userDirectories.text = ''
            sudo -u ${username} mkdir -p /Users/${username}/Development/{Work,Personal}
            sudo -u ${username} mkdir -p /Users/${username}/Development/Nix/{flakes,shells}
            sudo -u ${username} mkdir -p /Users/${username}/.config/zsh
          '';
        }
      ];
    };

    devShells.${system} = let
      pkgs = import inputs.nixpkgs-darwin {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      default = pkgs.mkShell {
        buildInputs = with pkgs; [
          git
          alejandra
          nil # Nix LSP
          sops
          age
          age-plugin-yubikey
        ];
        shellHook = ''
          echo "Default dev shell: git, alejandra, nil, sops, age, age-plugin-yubikey"
        '';
      };

      web = pkgs.mkShell {
        buildInputs = with pkgs; [
          nodejs_24
          bun
          typescript
          tailwindcss
          git
        ];
        shellHook = ''
          echo "Web dev shell: node $(node --version), bun $(bun --version)"
        '';
      };

      devops = pkgs.mkShell {
        buildInputs = with pkgs; [
          kubectl
          kubernetes-helm
          terraform
          awscli2
          docker
          k9s
          git
        ];
        shellHook = ''
          echo "DevOps shell: kubectl, helm, terraform, aws, docker, k9s"
        '';
      };

      # Rust + GHC/cabal (ghcup is not wired here).
      rust = pkgs.mkShell {
        buildInputs = with pkgs; [
          rustc
          cargo
          rustfmt
          rust-analyzer
          clippy
          ghc
          cabal-install
          git
        ];
        shellHook = ''
          echo "Rust/Haskell shell: $(rustc --version)"
          echo "$(ghc --version | head -n1)"
        '';
      };
    };

    formatter.${system} = inputs.nixpkgs-darwin.legacyPackages.${system}.alejandra;
  };
}
