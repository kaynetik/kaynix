
{ pkgs, ... }:

{
  # Configure nixpkgs to handle deprecation warnings gracefully
  nixpkgs.config = {
    allowUnfree = true;
    # Suppress some evaluation warnings
    permittedInsecurePackages = [];
  };
  nix.settings = {
    # enable flakes globally
    experimental-features = ["nix-command" "flakes"];

    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
    builders-use-substitutes = false;

    # gets rid of duplicate store files
    # turned off due to
    # https://github.com/NixOS/nix/issues/7273#issuecomment-1325073957
    auto-optimise-store = false;

    # Suppress warnings during evaluation
    warn-dirty = false;
  };

  # clean up every once in a while
  nix.gc.automatic = true;


  # Auto upgrade nix package and the daemon service.
  nix.enable = true;
  nix.package = pkgs.nix;
}
