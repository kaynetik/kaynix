
{ pkgs, ... }:

{
  nix.settings = {
    # enable flakes globally
    experimental-features = ["nix-command" "flakes"];

    # substituers that will be considered before the official ones(https://cache.nixos.org)
    substituters = [
      "https://mirror.sjtu.edu.cn/nix-channels/store"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
    builders-use-substitutes = true;

    # TODO: Migrate to host-users
    trusted-users = [
      "root"
      "@admin"
      "kaynetik"
    ];

    # gets rid of duplicate store files
    # turned off due to
    # https://github.com/NixOS/nix/issues/7273#issuecomment-1325073957
    auto-optimise-store = false;
  };

  # clean up every once in a while
  nix.gc.automatic = true;


  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  nix.package = pkgs.nix;
}
