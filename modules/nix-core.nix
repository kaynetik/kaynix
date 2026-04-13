{pkgs, ...}: {
  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [];
  };

  # nixpkgs has tabulate 0.10.0; checkov 3.2.510 declares tabulate<0.10, so pythonRuntimeDepsCheck fails.
  nixpkgs.overlays = [
    (final: prev: {
      checkov = prev.checkov.overridePythonAttrs (old: {
        pythonRelaxDeps = (old.pythonRelaxDeps or []) ++ ["tabulate"];
      });

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

    # gets rid of duplicate store files
    # turned off due to
    # https://github.com/NixOS/nix/issues/7273#issuecomment-1325073957
    auto-optimise-store = false;

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
