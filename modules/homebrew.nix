_: {
  homebrew = {
    enable = true;
    # Analytics must be disabled manually: brew analytics off

    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
      extraFlags = ["--force-cleanup"];
    };

    brews = [
      "keychain"
      "gnupg"
      "pinentry-mac"
      "secp256k1"
      "tor"
    ];

    casks = [
      "brave-browser"
      "google-chrome" # agent test automation

      "keepassxc"
      "gpg-suite"
      "protonvpn"
      "lulu"
      "knockknock"
      "dhs"
      "whatsyoursign"
      "pareto-security" # periodic security checks

      "obsidian"

      "cursor"
      "postman"
      "figma"

      "sf-symbols"
      "font-sf-pro"
      "font-sf-mono"

      "lens"

      "calibre"
      "vlc"
      "spotify" # Ditch this crap ASAP
      "gimp"
      "transmission"

      "telegram"
      "slack"
    ];
  };
}
