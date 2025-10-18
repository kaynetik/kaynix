{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # ============================================================
    # Languages & Runtimes
    # ============================================================
    zig
    rustup
    alejandra
    hugo
    bun
    nodejs

    # ============================================================
    # VCS
    # ============================================================
    git
    git-lfs
    lazygit
    gh
    pre-commit

    # ============================================================
    # Terminal & Shell Utilities
    # ============================================================
    alacritty
    alacritty-theme
    neovim
    tmux
    atuin
    zoxide
    fzf
    fzf-zsh
    htop
    #
    # Text Processing & Search
    jq
    yq
    bat
    ripgrep
    fd
    eza
    tree
    exiftool

    # ============================================================
    # Network & Transfer Utilities
    # ============================================================
    curl
    wget
    croc
    grpcurl

    # ============================================================
    # Kubernetes & Container Tools
    # ============================================================
    kubectl
    kustomize
    k9s
    argocd
    kubefwd
    k3d
    kubernetes-helm

    # ============================================================
    # Cloud Platforms
    # ============================================================
    awscli2

    # ============================================================
    # IaC & Security
    # ============================================================
    infracost
    tflint
    checkov
    trivy

    # ============================================================
    # Monitoring & Observability
    # ============================================================
    prometheus
    prometheus.cli # This provides promtool
    grafana-alloy

    # ============================================================
    # Database & API Tools
    # ============================================================
    postgresql_18
    pgcli
    postman
    stripe-cli
    dotenvx

    # ============================================================
    # Go Development Tools
    # ============================================================
    tparse # CLI summarizer for `go test` output
    goose
    crane
    bazel-buildtools
    bazelisk

    # ============================================================
    # Media | Audio | Video
    # ============================================================
    audacity
    qbittorrent-enhanced
    spotify
    imagemagick
    shottr

    # ============================================================
    # Comms
    # ============================================================
    slack
    languagetool
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

    taps = [
      "nikitabobko/tap"
      "FelixKratz/formulae"
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

      # Programming Languages & Runtimes
      "openjdk"
      "lua"
      "luarocks"

      # Shell Tools
      "zinit"
      "tfenv"
      "jwt-rs/jwt-ui/jwt-ui"

      # UI & Desktop Tools
      "sketchybar"
      "borders"

      # Audio & Media Utilities
      "switchaudio-osx"
      "nowplaying-cli"

      # Swift Development
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
      # "lulu" => causing strange issues for git
      "protonvpn"
      # "pareto-security" # Occasionally run security checks

      # Productivity & Utilities
      "raycast"
      "obsidian"
      "nikitabobko/tap/aerospace"

      # Development Tools
      "cursor"
      "jetbrains-toolbox"

      # Fonts & Design Resources
      "sf-symbols"
      "font-sf-pro"
      "font-sf-mono"

      # Cloud & Infrastructure
      "gcloud-cli"
      "docker-desktop"
      "lens" # k9s migration should happen asap!

      # Media & Creative Tools
      "calibre"
      "mactex"
      "texstudio"
      "vlc"
      "gimp"

      # Communication & Entertainment
      "gather"
      "steam"
      "telegram"
    ];
  };
}
