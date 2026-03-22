{
  hostname,
  username,
  ...
}: {
  networking.hostName = hostname;
  networking.computerName = hostname;

  # Specify which network services should have DNS managed by nix-darwin
  # Retrieved from: networksetup -listallnetworkservices
  networking.knownNetworkServices = [
    "Wi-Fi"
    "Thunderbolt Bridge"
    "ThinkPad TBT 3 Dock"
    "USB 10/100 LAN"
    # Note: VPN services (like ProtonVPN) intentionally excluded
    # to allow them to manage their own DNS
  ];

  # DNS servers to apply to the above network services
  networking.dns = [
    "192.168.2.1"
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
