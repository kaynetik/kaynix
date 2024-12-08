{ pkgs, ...}: {

  environment.systemPackages = with pkgs; [
    git
    git-lfs
    lazygit
    nerdfonts
    jq
    bat
    bun
    nodejs
  ];

  fonts.packages = with pkgs; [ nerdfonts ];

  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      # 'zap': uninstalls all formulae(and related files) not listed here.
    };

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

      "lua"
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
      "raycast"
      "obsidian"
      "slack"
      "telegram"
      "zed"
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
    ];
  };
}
