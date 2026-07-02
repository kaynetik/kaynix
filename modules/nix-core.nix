{pkgs, ...}: {
  nixpkgs.config = {
    allowUnfree = true;
    # checkov -> python ecdsa (CVE-2024-23342, Minerva timing attack; upstream
    # ecdsa won't fix). checkov is a CLI/CI tool, not exposed to attacker-timed
    # signing, so the timing side-channel is not in our threat model.
    permittedInsecurePackages = ["python3.13-ecdsa-0.19.2"];
  };

  nixpkgs.overlays = [
    (_final: prev: {
      # nixpkgs still ships macmon 0.6.1; track upstream releases here.
      # Drop this override once the lock contains macmon >= 0.7.2.
      macmon = prev.rustPlatform.buildRustPackage {
        pname = "macmon";
        version = "0.7.2";
        src = prev.fetchFromGitHub {
          owner = "vladkens";
          repo = "macmon";
          tag = "v0.7.2";
          hash = "sha256-i6x4ZAh+gIG6aHEfoSifwFU/itOcPmBiQ0IrBkqz+L8=";
        };
        cargoHash = "sha256-faEuoroZ/d8FntZaxkTbgVQ0nSwddxZR7KOfNPrU4Eg=";
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
