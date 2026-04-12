{
  description = "Nix for macOS and Linux [kaynix]";

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

    # Alias so transitive inputs that expect "nixpkgs" by name (darwin,
    # home-manager, sops-nix) all resolve to the same evaluated nixpkgs.
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
    # Per-host config. Add an entry here when deploying to a new machine.
    # Shared defaults live in the modules; `config` overrides per machine.
    hosts = {
      knt-mbp = {
        system = "aarch64-darwin";
        username = "kaynetik";
        config = {
          homeStateVersion = "24.11";
          timeZone = "Europe/Belgrade";
          loginGreeting = "nixing";
          sketchybar.theme = "rose_pine";
          networking = {
            knownNetworkServices = [
              "Wi-Fi"
              "Thunderbolt Bridge"
              "ThinkPad TBT 3 Dock"
              "USB 10/100 LAN"
            ];
            dns = [
              "192.168.2.1"
              "1.1.1.1"
              "1.0.0.1"
              "8.8.8.8"
              "8.8.4.4"
            ];
          };
        };
      };

      mbp = {
        system = "aarch64-darwin";
        username = "kaynetik";
        config = {
          homeStateVersion = "26.05";
          timeZone = "Europe/Belgrade";
          sketchybar.theme = "rose_pine";
          networking = {
            knownNetworkServices = ["Wi-Fi" "Thunderbolt Bridge"];
            dns = ["1.1.1.1" "1.0.0.1" "8.8.8.8" "8.8.4.4"];
          };
        };
      };
    };

    mkDarwin = hostname: hostCfg: let
      inherit (hostCfg) system username;
      hostConfig = hostCfg.config or {};
      specialArgs =
        inputs
        // {
          inherit username hostname hostConfig;
        };
    in
      darwin.lib.darwinSystem {
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
            home-manager.extraSpecialArgs = {
              inherit username hostConfig;
              kaynixStatic = ./homes/static;
            };
            home-manager.sharedModules = [sops-nix.homeManagerModules.sops];
            home-manager.backupFileExtension = "hm-backup";
            home-manager.users.${username} = import ./homes/kaynetik.nix;
          }

          {
            system.activationScripts.userDirectories.text = ''
              sudo -u ${username} mkdir -p /Users/${username}/Development/{Work,Personal}
              sudo -u ${username} mkdir -p /Users/${username}/Development/Nix/{flakes,shells}
              sudo -u ${username} mkdir -p /Users/${username}/.config/zsh
            '';
          }
        ];
      };

    primaryHost = hosts.knt-mbp;
  in {
    darwinConfigurations = builtins.mapAttrs mkDarwin hosts;

    # Dev shells intentionally re-declare packages that overlap with home.packages.
    # home.packages provides the always-available baseline; dev shells provide
    # version-isolated, project-scoped environments activated via `nix develop .#<name>`.
    devShells.${primaryHost.system} = let
      pkgs = import inputs.nixpkgs-darwin {
        system = primaryHost.system;
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
          gh
          nixpkgs-review
          jq
          curl
          cacert
        ];
        shellHook = ''
          echo "Default dev shell: git, alejandra, nil, sops, age, age-plugin-yubikey"
        '';
      };

      python = pkgs.mkShell {
        buildInputs = with pkgs; [
          uv
          python3
          ruff
          basedpyright
          git
        ];
        shellHook = ''
          echo "Python shell: $(python3 --version), uv $(uv --version)"
        '';
      };

      # SketchyBar: format Lua config (StyLua), same lua5_5 + LUA_CPATH as launchd (modules/apps.nix).
      sketchybar = pkgs.mkShell {
        buildInputs =
          (with pkgs; [
            stylua
            git
            gnumake
            lua5_5
            sbarlua
            sketchybar
          ])
          ++ [pkgs."lua-language-server"];
        shellHook = ''
          _repo="$(git rev-parse --show-toplevel 2>/dev/null || true)"
          if [ -n "$_repo" ] && [ -d "$_repo/homes/static/sketchybar" ]; then
            export CONFIG_DIR="$_repo/homes/static/sketchybar"
          else
            export CONFIG_DIR="''${PWD}/homes/static/sketchybar"
          fi
          export SKETCHYBAR_THEME="''${SKETCHYBAR_THEME:-tokyo_night}"
          export LUA_CPATH="${pkgs.lua5_5}/lib/lua/5.5/?.so;${pkgs.lua5_5}/lib/lua/5.5/loadall.so;${pkgs.sbarlua}/lib/lua/5.5/?.so;./?.so"
          echo "SketchyBar dev shell: lua $(lua -v 2>&1 | head -n1), stylua $(stylua --version)"
          echo "  CONFIG_DIR=$CONFIG_DIR"
          echo "  check:  stylua --check \"\$CONFIG_DIR\""
          echo "  fmt:    stylua \"\$CONFIG_DIR\""
          echo "  make:   (cd \"\$CONFIG_DIR/helpers\" && make)"
          echo "  reload: sketchybar --reload"
        '';
      };
    };

    formatter.${primaryHost.system} = inputs.nixpkgs-darwin.legacyPackages.${primaryHost.system}.alejandra;
  };
}
