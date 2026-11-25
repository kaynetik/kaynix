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

    nixpkgs.follows = "nixpkgs-darwin";

    darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    # Fork: decrypts each sops file once (one YubiKey touch per activation).
    # Point back at github:Mic92/sops-nix once #956 is fixed and #911 merged.
    sops-nix = {
      url = "github:kaynetik/sops-nix/main";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    # Private repo, see secrets/README.md. CI and fresh clones use the stub from
    # scripts/vault-stub via `--override-input kaynix-vault`.
    kaynix-vault.url = "git+ssh://git@github.com/kaynetik/kaynix-vault";

    solc-nix = {
      url = "github:hellwolf/solc.nix";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    zapmenu = {
      url = "github:kaynetik/zapmenu";
      flake = false;
    };
  };

  outputs = inputs @ {
    nixpkgs-darwin,
    darwin,
    home-manager,
    sops-nix,
    kaynix-vault,
    solc-nix,
    zapmenu,
    ...
  }: let
    # Mirrored by the fallback in homes/static/sketchybar/colors.lua.
    sketchybarThemeDefault = "rose_pine";

    # Consumers: imports = [inputs.kaynix.homeModules.kaynix-identity];
    identityModule = import ./modules/home/identity.nix;

    kaynixOverlay = final: prev: let
      # solc.nix reads stdenv.isDarwin (eval warning). Drop once
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

        # nixpkgs anomaly-hex is x86_64-linux only. Drop this override once it
        # supports aarch64-darwin.
        anomaly-hex = final.callPackage ./pkgs/anomaly-hex {};

        fluidaudiocli = final.callPackage ./pkgs/fluidaudiocli {};

        zapmenu = final.callPackage ./pkgs/zapmenu {src = zapmenu;};

        # swift-collections 1.7.6 links libswiftCompatibilitySpan, which enables
        # an install_name_tool -add_rpath step that fails without header padding
        # ("larger updated load commands do not fit"). Same fix as nixpkgs
        # 5b0748384. Drop this override once `nix flake update nixpkgs-darwin`
        # lands a rev containing that commit.
        swiftPackages = prev.swiftPackages.overrideScope (_swiftFinal: swiftPrev: {
          swift-collections = swiftPrev.swift-collections.overrideAttrs (old: {
            env =
              (old.env or {})
              // {
                NIX_LDFLAGS = final.lib.optionalString prev.stdenv.hostPlatform.isDarwin "-headerpad_max_install_names";
              };
          });
        });

        # patchShebangs bakes a /nix/store bash path into installed git hooks,
        # which breaks after GC. Restore the portable shebang (tests assert the
        # patched one, so skip them). Drop once nixpkgs stops patching the hook
        # template.
        #
        # virtualenv 21.14.12 imports `packaging` without declaring it, which
        # breaks hook environments. Scoped to pre-commit's python set so other
        # packages keep their cached builds. Drop the `.override` once nixpkgs
        # lists packaging in virtualenv's dependencies.
        pre-commit =
          (prev.pre-commit.override {
            python3Packages = prev.python3Packages.overrideScope (pyfinal: pyprev: {
              virtualenv = pyprev.virtualenv.overridePythonAttrs (old: {
                dependencies = (old.dependencies or []) ++ [pyfinal.packaging];
                doCheck = false;
              });
            });
          }).overridePythonAttrs (old: {
            doCheck = false;
            doInstallCheck = false;
            dontUsePytestCheck = true;
            postFixup =
              (old.postFixup or "")
              + ''
                sed -i '1s|^#!.*|#!/usr/bin/env bash|' \
                  "$(find "$out" -path '*pre_commit/resources/hook-tmpl')"
              '';
          });

        # checkov dependency: unidiff rejects test_data/sample.diff because the
        # last git header and its ---/+++ lines disagree. Drop once the fixture
        # is fixed upstream or in nixpkgs.
        pythonPackagesExtensions =
          prev.pythonPackagesExtensions
          ++ [
            (_pyfinal: pyprev: {
              bc-detect-secrets = pyprev.bc-detect-secrets.overridePythonAttrs (old: {
                postPatch =
                  (old.postPatch or "")
                  + ''
                    substituteInPlace test_data/sample.diff \
                      --replace-fail $'diff --git a/setup.py b/setup.py\nindex 12ce201..02fcca5 200644' \
                      $'diff --git a/.secrets.baseline b/.secrets.baseline\nindex 12ce201..02fcca5 100644'
                  '';
              });
            })
          ];

        # Single sketchybar Lua search path shared by every consumer.
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

    # Per-host config; `config` overrides module defaults.
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
      # Defaults, so modules can read hostConfig without fallbacks.
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
          ./modules/pki.nix
          ./modules/homebrew.nix
          ./modules/fonts.nix
          ./modules/sketchybar.nix
          ./modules/aerospace.nix
          ./modules/host-users.nix
          ./modules/netbird.nix

          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {
              inherit username hostConfig;
              kaynixStatic = ./homes/static;
            };
            home-manager.sharedModules = [
              sops-nix.homeManagerModules.sops
              kaynix-vault.homeManagerModules.default
            ];
            home-manager.backupFileExtension = "hm-backup";
            home-manager.users.${username} = import ./homes/kaynetik.nix;
          }
        ];
      };

    # Selects the devShells system, so keep it on the machine in daily use.
    primaryHost = hosts.mbp;

    primaryPkgs = import inputs.nixpkgs-darwin {
      inherit (primaryHost) system;
      config.allowUnfree = true;
      overlays = [kaynixOverlay];
    };

    # CI lints on Linux; the flake's other outputs stay darwin-only.
    ciSystem = "x86_64-linux";
    # Same overlay as the hosts, so CI runs the pre-commit it runs locally.
    ciPkgs = import nixpkgs-darwin {
      system = ciSystem;
      overlays = [kaynixOverlay];
    };

    # Tools the pre-commit hooks call (see .pre-commit-config.yaml).
    lintTools = pkgs:
      with pkgs; [
        alejandra
        statix
        deadnix
        gitleaks
        shellcheck
        stylua
        pre-commit
      ];
  in {
    darwinConfigurations = builtins.mapAttrs mkDarwin hosts;

    homeModules = {
      kaynix-identity = identityModule;
      default = identityModule;
    };

    packages.${primaryHost.system} = {
      inherit (primaryPkgs) fluidaudiocli zapmenu;
    };

    devShells.${primaryHost.system} = let
      pkgs = primaryPkgs;
    in {
      # Same tool set CI uses.
      default = pkgs.mkShell {
        buildInputs = lintTools pkgs;
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
          echo "  reload: sketchybar --reload"
        '';
      };
    };

    devShells.${ciSystem}.default = ciPkgs.mkShell {
      buildInputs = lintTools ciPkgs;
    };

    formatter.${primaryHost.system} = inputs.nixpkgs-darwin.legacyPackages.${primaryHost.system}.alejandra;
    formatter.${ciSystem} = ciPkgs.alejandra;
  };
}
