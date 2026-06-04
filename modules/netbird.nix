{pkgs, ...}: {
  # Runs the NetBird client daemon as a root LaunchDaemon, which is the only
  # way the daemon can manage the WireGuard interface, routes, DNS, and the
  # /var/run/netbird/sock socket. Survives reboots and `darwin-rebuild switch`.
  #
  # The `netbird` CLI itself stays in Home Manager (modules/home/packages.nix);
  services.netbird = {
    enable = true;
    package = pkgs.netbird;
  };
}
