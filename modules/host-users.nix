{
  hostname,
  username,
  hostConfig,
  ...
}: let
  net = hostConfig.networking or {};
in {
  networking.hostName = hostname;
  networking.computerName = hostname;

  # Retrieved from: networksetup -listallnetworkservices
  # VPN services (like ProtonVPN) intentionally excluded to let them manage their own DNS.
  networking.knownNetworkServices =
    net.knownNetworkServices or [
      "Wi-Fi"
      "Thunderbolt Bridge"
    ];

  networking.dns =
    net.dns or [
      "1.1.1.1"
      "1.0.0.1"
      "8.8.8.8"
      "8.8.4.4"
    ];

  users.users."${username}" = {
    home = "/Users/${username}";
    description = username;
  };

  nix.settings.trusted-users = [username];
}
