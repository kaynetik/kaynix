{ pkgs, ...}: {

  environment.systemPackages = with pkgs; [
    git
    git-lfs
    lazygit
    nerdfonts
    jq
    bat
    bun
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
    ];

    # FIXME: Everything that's not GUI should be moved to systemPackages!
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
      "postman"
      "jetbrains-toolbox"
      "google-cloud-sdk"
      "docker"
      "lens"
      "openvpn-connect"
      "viber"
    ];
  };
}
