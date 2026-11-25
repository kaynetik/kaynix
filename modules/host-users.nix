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

  # Stealth mode drops unsolicited probes (ping, closed-port scans). Signed
  # apps keep their default allowance, so LuLu stays the per-app filter.
  networking.applicationFirewall = {
    enable = true;
    enableStealthMode = true;
  };

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
}
