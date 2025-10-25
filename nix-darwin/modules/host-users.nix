{
  hostname,
  username,
  ...
}:
#############################################################
#
#  Host & Users configuration
#
#############################################################
{
  networking.hostName = hostname;
  networking.computerName = hostname;
  system.defaults.smb.NetBIOSName = hostname;

  # Specify which network services should have DNS managed by nix-darwin
  # Retrieved from: networksetup -listallnetworkservices
  networking.knownNetworkServices = [
    "Wi-Fi"
    "Thunderbolt Bridge"
    # Note: VPN services (like ProtonVPN) intentionally excluded
    # to allow them to manage their own DNS
  ];

  # DNS servers to apply to the above network services
  networking.dns = [
    "1.1.1.1" # Cloudflare Primary (fast, privacy-focused)
    "1.0.0.1" # Cloudflare Secondary
    "8.8.8.8" # Google Primary (reliable fallback)
    "8.8.4.4" # Google Secondary (reliable fallback)
    # "192.168.2.1"
  ];

  users.users."${username}" = {
    home = "/Users/${username}";
    description = username;
  };

  nix.settings.trusted-users = [username];
}
