{ pkgs, ...}: {

  environment.systemPackages = with pkgs; [
    git
    git-lfs
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

    brews = [
      "zinit"
      "neovim"
      "tmux"
      "eza"
      "languagetool"
      "gnupg"
      "zoxide"
      "fzf"
      "ripgrep"

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
      "postman"
      "jetbrains-toolbox"
      "google-cloud-sdk"
      "docker"
      "lens"
    ];
  };
}
