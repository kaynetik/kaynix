{pkgs, ...}: {
  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [];
  };
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
