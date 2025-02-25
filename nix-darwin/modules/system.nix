{ pkgs, ... }:
{
  time.timeZone = "Europe/Belgrade";

  system = {
    stateVersion = 5;
    # activationScripts are executed every time you boot the system or run `nixos-rebuild` / `darwin-rebuild`.
    activationScripts.postUserActivation.text = ''
      # activateSettings -u will reload the settings from the database and apply them to the current session,
      # so we do not need to logout and login again to make the changes take effect.
      /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    '';

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
        FXPreferredViewStyle = "clmv"; # # Default folder view is Columns "Nlsv";
        # full path in window title
        _FXShowPosixPathInTitle = true;
        AppleShowAllExtensions = true;
      };

      loginwindow.LoginwindowText = "nixcademy.com"; # Specific text as greeting on login
    };
  };

  # Add ability to used TouchID for sudo authentication
  security.pam.services.sudo_local.touchIdAuth = true;

  programs.zsh.enable = true;
}
