{
  username,
  hostConfig,
  ...
}: {
  time.timeZone = hostConfig.timeZone or "Europe/Belgrade";

  system = {
    stateVersion = 5;
    primaryUser = username;

    defaults = {
      menuExtraClock.Show24Hour = true;

      trackpad = {
        Clicking = true;
        Dragging = true;
        TrackpadRightClick = true;
      };

      dock = {
        autohide = true;
        magnification = true;
        mru-spaces = false;
        tilesize = 32;
        largesize = 96;
      };

      NSGlobalDomain = {
        _HIHideMenuBar = true;
      };

      screencapture.location = "~/Pictures/screenshots";
      screensaver.askForPasswordDelay = 0;

      finder = {
        ShowStatusBar = true;
        ShowPathbar = true;
        FXPreferredViewStyle = "clmv";
        _FXShowPosixPathInTitle = true;
        AppleShowAllExtensions = true;
      };

      loginwindow.LoginwindowText = hostConfig.loginGreeting or "nixing";
      loginwindow.GuestEnabled = false;
    };
  };

  # Pinned in /etc/ssh/ssh_known_hosts so a first connection is not
  # trust-on-first-use. Source: https://api.github.com/meta (ssh_keys).
  programs.ssh.knownHosts."github.com".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";

  security.pam.services.sudo_local.touchIdAuth = true;

  programs.zsh.enable = true;
  programs.zsh.enableGlobalCompInit = false;
}
