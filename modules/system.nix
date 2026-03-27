{
  pkgs,
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
      screensaver.askForPasswordDelay = 15;

      finder = {
        ShowStatusBar = true;
        ShowPathbar = true;
        FXPreferredViewStyle = "clmv";
        _FXShowPosixPathInTitle = true;
        AppleShowAllExtensions = true;
      };

      loginwindow.LoginwindowText = hostConfig.loginGreeting or "nixing";
    };
  };

  security.pam.services.sudo_local.touchIdAuth = true;

  programs.zsh.enable = true;
}
