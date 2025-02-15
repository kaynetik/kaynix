{ pkgs, ...}: {

  environment.systemPackages = with pkgs; [
    git
    git-lfs
    lazygit
    jq
    bat
    bun
    nodejs
    wget
    kubectl
    tree
    infracost
  ];

  fonts.packages =
    builtins.filter pkgs.lib.attrsets.isDerivation
      (builtins.attrValues pkgs.nerd-fonts);

  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
    };

    # FIXME: Redownload not available...
    # masApps = {
    #   "Bitwarden" = 1352778147;
    #   "Windows App" = 1295203466;
    # };

    taps = [
      "homebrew/services"
      "nikitabobko/tap"
      "FelixKratz/formulae"
    ];

    brews = [
      "zinit"
      "neovim"
      "tmux"
      "eza"
      "languagetool"
      "keychain"
      "gpg"
      "gpg2"
      "gnupg"
      "pinentry-mac"
      "zoxide"
      "fzf"
      "ripgrep"
      "croc"
      "ntfs-3g"

      "bazelisk"
      "openjdk"
      "awscli"
      "pre-commit"
      "gh"

      # Terraform
      "tfenv"
      "tflint"
      "checkov"
      "trivy"

      "posting"

      "lua"
      "luarocks"
      "fd"
      "sketchybar"
      "borders"
      "switchaudio-osx"
      "nowplaying-cli"
    ];

    casks = [
      "brave-browser"
	    "alacritty"
      "keepassxc"
      "gpg-suite"
      "protonvpn"
      "raycast"
      "obsidian"
      "slack"
      "telegram"
      "zed"
      "cursor"
      "nikitabobko/tap/aerospace"
      "sf-symbols"
      "font-sf-pro"
      "font-sf-mono"
      "postman"
      "jetbrains-toolbox"
      "google-cloud-sdk"
      "docker"
      "lens"
      "openvpn-connect"
      "viber"
      "spotify"
      "audacity"
      "vlc"
      "calibre"
      "shottr"
      "gimp"
      "qbittorrent"
    ];
  };
}
