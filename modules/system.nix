{
  pkgs,
  username,
  hostConfig,
  ...
}: {
  time.timeZone = hostConfig.timeZone or "Europe/Belgrade";

  # nix-darwin master (a1fa429, 2026-06-18) still passes --toc-depth to
  # nixos-render-docs, which nixpkgs >= 2026-07 removed, so the HTML manual fails
  # to build. darwin-uninstaller embeds an inner default-config system that
  # builds that manual regardless of the option above, so it goes too. Drop both
  # once a nix-darwin bump renders with --sidebar-depth.
  documentation.doc.enable = false;
  system.tools.darwin-uninstaller.enable = false;

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
  programs.zsh.enableGlobalCompInit = false;
}
