{...}: {
  homebrew = {
    enable = true;
    # Note: Analytics still needs to be disabled manually with: brew analytics off

    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
      extraFlags = ["--force-cleanup"];
    };

    brews = [
      # Security & GPG
      "keychain"
      "gnupg" # gpg and gpg2 are brew aliases of gnupg; one formula is enough.
      "pinentry-mac"
      "secp256k1"
      "tor"
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
