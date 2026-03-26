{pkgs, ...}: {
  services.sketchybar.enable = true;

  # User packages are in homes/kaynetik.nix (home.packages, programs.*).
  # dotenvx is broken upstream: https://github.com/NixOS/nixpkgs/pull/500959#issuecomment-4103458168

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

    taps = [
      "txn2/tap"
      "jwt-rs/jwt-ui"
    ];

    brews = [
      # Security & GPG
      "keychain"
      "gpg"
      "gpg2"
      "gnupg"
      "pinentry-mac"
      "secp256k1"
      "tor"

      # Programming Languages & Runtimes
      # "openjdk" # equal alt in nix?
      "luarocks"

      # Shell Tools
      "zinit"
      "tfenv" # wtf why isnt this in nix already?
      "jwt-rs/jwt-ui/jwt-ui"

      # Swift Development ## Migrate to nix asap
      "swiftlint"
      "swiftgen"
      "protobuf"
      "swift-protobuf"
      "protoc-gen-grpc-swift"
    ];

    casks = [
      # Browsers
      "brave-browser"

      # Security & Privacy
      "keepassxc"
      "gpg-suite"
      "protonvpn"
      ## objectivesee
      "lulu"
      "reikey"
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
      # "gcloud-cli"
      "lens" # Rice k9s more to reach the LENS usability levels.

      # Media Tools
      "calibre"
      "vlc"
      "spotify" # Ditch this crap ASAP
      "gimp"
      "transmission"
      "unetbootin"

      # Communication
      "telegram"
      "slack"
    ];
  };
}
