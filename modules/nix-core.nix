{pkgs, ...}: let
  darwinFlakyCheckPhases = [
    "av"
    "imageio"
    "scikit-image"
    "plotly"
    "igraph"
  ];

  disableChecks = pyPrev: name:
    pyPrev.${name}.overridePythonAttrs (_: {
      doCheck = false;
      pythonImportsCheck = [];
    });
in {
  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [];
  };

  nixpkgs.overlays = [
    (final: prev: {
      # nixpkgs has tabulate 0.10.0; checkov 3.2.510 declares tabulate<0.10, so pythonRuntimeDepsCheck fails.
      checkov = prev.checkov.overridePythonAttrs (old: {
        pythonRelaxDeps = (old.pythonRelaxDeps or []) ++ ["tabulate"];
      });

      # Extend every Python package set so overrides propagate through transitive
      # consumers (e.g. checkov -> igraph -> plotly -> scikit-image -> imageio -> av, and pgcli -> cli-helpers).
      pythonPackagesExtensions =
        (prev.pythonPackagesExtensions or [])
        ++ [
          (pyFinal: pyPrev:
            # cli-helpers 2.10.0 fails three pygments-based ANSI styling tests on Darwin.
            # Tracked in https://github.com/NixOS/nixpkgs/issues/513102, fixed upstream by https://github.com/NixOS/nixpkgs/pull/493910
            # (bump to 2.14.0). Drop after nixpkgs input bumps cli-helpers to >= 2.14.0.
              {
                cli-helpers = pyPrev.cli-helpers.overridePythonAttrs (old: {
                  disabledTests =
                    (old.disabledTests or [])
                    ++ [
                      "test_style_output"
                      "test_style_output_with_newlines"
                      "test_style_output_custom_tokens"
                    ];
                });
              }
              // builtins.listToAttrs (map (n: {
                  name = n;
                  value = disableChecks pyPrev n;
                })
                darwinFlakyCheckPhases))
        ];

      macmon = prev.rustPlatform.buildRustPackage {
        pname = "macmon";
        version = "0.7.0";
        src = prev.fetchFromGitHub {
          owner = "vladkens";
          repo = "macmon";
          tag = "v0.7.0";
          hash = "sha256-OLrljN3AlsB63TSgd+UqvFKriImhFZ/xexCT30yTmuA=";
        };
        cargoHash = "sha256-Epj3L+db1flGNK5y6yfSig8piEiXTz15lPo/FNkqlkA=";
        meta = prev.macmon.meta;
      };
    })
  ];

  nix.settings = {
    experimental-features = ["nix-command" "flakes"];

    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
    builders-use-substitutes = false;

    max-jobs = 8;
    cores = 0;

    auto-optimise-store = false; # https://github.com/NixOS/nix/issues/7273#issuecomment-1325073957

    warn-dirty = false;
  };

  nix.gc = {
    automatic = true;
    # nix-darwin launchd schedule: run monthly on day 1 at 15:15 local time.
    interval = {
      Day = 1;
      Hour = 15;
      Minute = 15;
    };
    options = "--delete-older-than 30d";
  };

  nix.enable = true;
  nix.package = pkgs.nix;
}
