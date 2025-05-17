{ pkgs, ...}: {

  environment.systemPackages = with pkgs; [
    zig
    rustup
    git
    git-lfs
    lazygit
    jq
    bat
    bun
    nodejs
    wget
    kubectl
    kustomize
    tree
    infracost
    terraformer # GCP tool for easier importing of lost/drifted state
    tparse # CLI summarizer for `go test` output
    htop
    postgresql_17
  ];

  fonts.packages =
    builtins.filter pkgs.lib.attrsets.isDerivation
      (builtins.attrValues pkgs.nerd-fonts);

  homebrew = {
    enable = true;
    # FIXME: Research how to disable ANALYTICS by default
    # I've caught by accident an outgoing request to InfluxDB for analytics
    # brew analytics off

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
      "nikitabobko/tap"
      "FelixKratz/formulae"
      "txn2/tap"
      "jwt-rs/jwt-ui"
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

      "helm"
      "k3d"
      "kubefwd"
      "buildifier" # https://github.com/bazelbuild/buildtools
      "protobuf"
      "crane"
      "protoc-gen-grpc-swift"
      "swift-protobuf"

      "posting"
      "grpcurl"
      "jwt-rs/jwt-ui/jwt-ui"
      "pgcli"
      "goose"

      "lua"
      "luarocks"
      "fd"
      "sketchybar"
      "borders"
      "switchaudio-osx"
      "nowplaying-cli"
      "swiftlint"
      "swiftgen"

      "pandoc"
      "exiftool"
    ];

    casks = [
      "brave-browser"
	    "alacritty"
      "keepassxc"
      "gpg-suite"
      # "lulu" => causing strange issues for git
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
      "ngrok"
      # "pareto-security" # Ocassionally Run Checks!

      "viber"
      "spotify"
      "audacity"
      "vlc"
      "calibre"
      "shottr"
      "gimp"
      "qbittorrent"
      "mactex"
      "texstudio"
    ];
  };
}
