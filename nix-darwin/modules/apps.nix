{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # Development languages & tools
    zig
    rustup
    alejandra

    # Version control
    git
    git-lfs
    lazygit
    gh

    # CLI utilities & text processing
    jq
    yq
    bat
    curl
    wget
    tree

    # JavaScript/Node ecosystem
    bun
    nodejs

    # Kubernetes & cloud tools
    kubectl
    kustomize
    k9s
    awscli2
    argocd

    # Terraform & infrastructure
    infracost
    terraformer # GCP tool for easier importing of lost/drifted state

    # Monitoring & observability
    prometheus
    prometheus.cli # This provides promtool
    grafana-alloy

    # Database & API tools
    postgresql_18
    stripe-cli
    dotenvx

    # Go tools
    tparse # CLI summarizer for `go test` output

    # System utilities
    htop
    imagemagick
  ];

  fonts.packages =
    builtins.filter pkgs.lib.attrsets.isDerivation
    (builtins.attrValues pkgs.nerd-fonts);

  homebrew = {
    enable = true;
    # Note: Analytics needs to be disabled manually with: brew analytics off

    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
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
      "pre-commit"

      "bazelisk"
      "openjdk"

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
      "hugo"
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
      "gcloud-cli"
      "docker-desktop"
      "lens" #k9s migration should happen asap!
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
      "gather"
      "steam"
    ];
  };
}
