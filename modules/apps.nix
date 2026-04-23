{
  pkgs,
  username,
  hostConfig,
  ...
}: let
  sketchybarTheme = (hostConfig.sketchybar or {}).theme or "tokyo_night";
in {
  services.sketchybar = {
    enable = true;
    extraPackages = [pkgs.lua5_5 pkgs.sbarlua];
  };

  launchd.user.agents.sketchybar.environment = {
    LUA_CPATH = "${pkgs.lua5_5}/lib/lua/5.5/?.so;${pkgs.lua5_5}/lib/lua/5.5/loadall.so;${pkgs.sbarlua}/lib/lua/5.5/?.so;./?.so";
    SKETCHYBAR_THEME = sketchybarTheme;
    PATH = "/etc/profiles/per-user/${username}/bin:/run/current-system/sw/bin:/usr/bin:/bin:/usr/sbin:/sbin";
  };

  fonts.packages = with pkgs.nerd-fonts; [
    jetbrains-mono # Primary terminal font (Alacritty)
    fira-code
    meslo-lg
  ];

  homebrew = {
    enable = true;
    # Note: Analytics still needs to be disabled manually with: brew analytics off

    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };

    taps = [];

    brews = [
      # Security & GPG
      "keychain"
      "gpg"
      "gpg2"
      "gnupg"
      "pinentry-mac"
      "secp256k1"
      "tor"

      # Local LLM dependencies
      "python@3.14" # Python 3.14 from brew is required for mlx-lm to work on Apple GPU silicon.
      "uv"
      "ollama"

      "tfenv"
      "protobuf"
      "pandoc"
      "typst"
    ];

    casks = [
      # Browsers
      "brave-browser"

      # Security & Privacy
      "keepassxc"
      "gpg-suite"
      "protonvpn"
      "lulu"
      "knockknock"
      "blockblock"
      "ransomwhere"
      "dhs"
      "whatsyoursign"
      "pareto-security" # Occasionally run security checks

      # Productivity & Utilities
      "raycast"
      "obsidian"

      # Development Tools
      "cursor"
      "postman"

      # Fonts
      "sf-symbols"
      "font-sf-pro"
      "font-sf-mono"

      # Cloud & Infrastructure
      "lens" # Rice k9s more to reach the LENS usability levels.

      # Media Tools
      "calibre"
      "vlc"
      "spotify" # Ditch this crap ASAP
      "gimp"
      "transmission"

      # Communication
      "telegram"
      "slack"
    ];
  };
}
