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

  launchd.user.agents.sketchybar = {
    # services.sketchybar builds the agent PATH from environment.systemPath, whose
    # "$HOME"/"$USER" entries launchd never expands, so per-user profile binaries
    # (SwitchAudioSource, jq, macmon) are unreachable from widgets. The launchd
    # module's `path` option overrides environment.PATH, so it must be fixed here;
    # list entries merge with the module's own.
    path = ["/etc/profiles/per-user/${username}/bin"];
    environment = {
      LUA_CPATH = "${pkgs.lua5_5}/lib/lua/5.5/?.so;${pkgs.lua5_5}/lib/lua/5.5/loadall.so;${pkgs.sbarlua}/lib/lua/5.5/?.so;./?.so";
      SKETCHYBAR_THEME = sketchybarTheme;
    };
  };

  fonts.packages =
    [
      pkgs.sketchybar-app-font # App icon ligatures for the sketchybar workspace widget
    ]
    ++ (with pkgs.nerd-fonts; [
      jetbrains-mono # Primary terminal font (Alacritty)
      fira-code
      meslo-lg
    ]);

  homebrew = {
    enable = true;
    # Note: Analytics still needs to be disabled manually with: brew analytics off

    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
      # Homebrew >= 4.7 rejects `brew bundle --cleanup` without an explicit
      # confirmation flag. The locked nix-darwin module emits `--cleanup --zap`
      # but not `--force`, so activation aborts. Append it ourselves.
      extraFlags = ["--force-cleanup"];
    };

    taps = [];

    brews = [
      # Security & GPG
      "keychain"
      "gnupg" # gpg and gpg2 are brew aliases of gnupg; one formula is enough.
      "pinentry-mac"
      "secp256k1"
      "tor"

      # Local LLM dependencies - temporarily avoid local LLMs
      #"python@3.14" # Python 3.14 from brew is required for mlx-lm to work on Apple GPU silicon.
      #"ollama"
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
      "figma"

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
