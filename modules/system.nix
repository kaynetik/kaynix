{
  pkgs,
  username,
  ...
}: {
  time.timeZone = "Europe/Belgrade";

  system = {
    stateVersion = 5;
    primaryUser = "kaynetik";
    # activationScripts run on boot and on `darwin-rebuild`.

    defaults = {
      menuExtraClock.Show24Hour = true;

      trackpad = {
        # tap to click
        Clicking = true;
        # tap-tap-drag to drag
        Dragging = true;
        # two-finger-tap right click
        TrackpadRightClick = true;
      };

      dock = {
        autohide = true;
        magnification = true;
        # most recently used spaces
        mru-spaces = false;
        tilesize = 32;
        largesize = 96;
      };

      NSGlobalDomain = {
        _HIHideMenuBar = true;
      };

      screencapture.location = "~/Pictures/screenshots";
      screensaver.askForPasswordDelay = 15;

      # https://github.com/LnL7/nix-darwin/blob/master/modules/system/defaults/finder.nix
      finder = {
        ShowStatusBar = true;
        ShowPathbar = true;

        # default to list view
        FXPreferredViewStyle = "clmv";
        # full path in window title
        _FXShowPosixPathInTitle = true;
        AppleShowAllExtensions = true;
      };

      loginwindow.LoginwindowText = "nixcademy.com"; # Specific text as greeting on login
    };
  };

  security.pam.services.sudo_local.touchIdAuth = true;

  programs.zsh.enable = true;
}
