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

    # Declarative per-version Solidity compilers (pkgs.solc_0_8_19, etc.).
    # Nix-native replacement for `svm install <ver>`.
    solc-nix = {
      url = "github:hellwolf/solc.nix";
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
    solc-nix,
    ...
  }: let
    # Default sketchybar palette; hosts override via `config.sketchybar.theme`.
    # Mirrored by the fallback in homes/static/sketchybar/colors.lua.
    sketchybarThemeDefault = "rose_pine";

    # Reusable Home Manager modules. Another flake consumes the identity with
    #   imports = [inputs.kaynix.homeManagerModules.kaynix-identity];
    identityModule = import ./modules/home/identity.nix;

    # Overlay that exposes solc versions from solc-nix and our custom svm-rs.
    kaynixOverlay = final: prev: let
      # solc.nix still reads stdenv.isDarwin (eval warning). Shadow the
      # alias with a plain bool before that overlay runs. Drop once
      # hellwolf/solc.nix uses stdenv.hostPlatform.isDarwin.
      solcPrev =
        prev
        // {
          stdenv =
            prev.stdenv
            // {
              isDarwin = prev.stdenv.hostPlatform.isDarwin;
            };
        };
    in
      (solc-nix.overlay final solcPrev)
      // {
        svm-rs = final.callPackage ./pkgs/svm-rs {};

        # checkov 3.3.9's secrets plugin finds 0 matches for the multiline
        # fixture in the Darwin Nix sandbox (bc_integration enrichment is
        # empty). Drop once nixpkgs disables test_multiline_finding or the
        # check phase passes on Darwin.
        checkov = prev.checkov.overridePythonAttrs (old: {
          disabledTests =
            (old.disabledTests or [])
            ++ final.lib.optionals final.stdenv.hostPlatform.isDarwin [
              "test_multiline_finding"
            ];
        });

        # checkov deps whose release tags still declare the previous version,
        # failing pythonMetadataCheckPhase. Each override fails the build once
        # upstream fixes the metadata, so neither outlives its use.
        pythonPackagesExtensions =
          prev.pythonPackagesExtensions
          ++ [
            (pyfinal: pyprev: {
              # 0.7.0's pyproject.toml says 0.7.0.dev9. Drop once nixpkgs
              # ships past 0.7.0 or upstream retags it.
              pycep-parser = pyprev.pycep-parser.overrideAttrs (old: {
                nativeBuildInputs = (old.nativeBuildInputs or []) ++ [pyfinal.pyprojectVersionPatchHook];
              });

              # 0.16.0 reads its version from version.py, left at 0.15.2
              # upstream. Drop once nixpkgs ships past 0.16.0.
              policy-sentry = pyprev.policy-sentry.overrideAttrs (old: {
                postPatch =
                  (old.postPatch or "")
                  + ''
                    substituteInPlace policy_sentry/bin/version.py \
                      --replace-fail '0.15.2' '${old.version}'
                  '';
              });
            })
          ];

        # Shared non-package values. `luaCpath` is the one sketchybar Lua
        # runtime search path, so a lua5_5/sbarlua bump reaches every
        # consumer at once.
        kaynixLib = let
          luaLibDir = drv: "${drv}/lib/lua/${final.lua5_5.luaversion}";
        in {
          luaCpath = final.lib.concatStringsSep ";" [
            "${luaLibDir final.lua5_5}/?.so"
            "${luaLibDir final.lua5_5}/loadall.so"
            "${luaLibDir final.sbarlua}/?.so"
            "./?.so"
          ];
        };
      };

    # Per-host config. Add an entry here when deploying to a new machine.
    # Shared defaults live in the modules; `config` overrides per machine.
    hosts = {
      mbp = {
        system = "aarch64-darwin";
        username = "kaynetik";
        config = {
          homeStateVersion = "26.05";
        };
      };
    };

    mkDarwin = hostname: hostCfg: let
      inherit (hostCfg) system username;
      # Shared host defaults; per-host `config` entries override them, so
      # modules can read e.g. `hostConfig.sketchybar.theme` without fallbacks.
      hostConfig = nixpkgs-darwin.lib.recursiveUpdate {
        sketchybar.theme = sketchybarThemeDefault;
      } (hostCfg.config or {});
      specialArgs =
        inputs
        // {
          inherit username hostname hostConfig;
        };
    in
      darwin.lib.darwinSystem {
        inherit system specialArgs;
        modules = [
          {nixpkgs.overlays = [kaynixOverlay];}

          ./modules/nix-core.nix
          ./modules/system.nix
          ./modules/homebrew.nix
          ./modules/fonts.nix
          ./modules/sketchybar.nix
          ./modules/aerospace.nix
          ./modules/host-users.nix
          ./modules/netbird.nix
          ./modules/objective-see.nix

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
        ];
      };

    # Selects the devShells system, so keep it on the machine in daily use.
    primaryHost = hosts.mbp;
  in {
    darwinConfigurations = builtins.mapAttrs mkDarwin hosts;

    homeManagerModules = {
      kaynix-identity = identityModule;
      default = identityModule;
    };

    # Dev shells intentionally re-declare packages that overlap with home.packages.
    # home.packages provides the always-available baseline; dev shells provide
    # version-isolated, project-scoped environments activated via `nix develop .#<name>`.
    devShells.${primaryHost.system} = let
      pkgs = import inputs.nixpkgs-darwin {
        system = primaryHost.system;
        config.allowUnfree = true;
        overlays = [kaynixOverlay];
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

      # SketchyBar: format Lua config (StyLua), same lua5_5 + LUA_CPATH as launchd (modules/sketchybar.nix).
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
          export SKETCHYBAR_THEME="''${SKETCHYBAR_THEME:-${sketchybarThemeDefault}}"
          export LUA_CPATH="${pkgs.kaynixLib.luaCpath}"
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
