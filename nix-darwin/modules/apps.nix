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
    yq-go
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
    trivy
    terraform-docs

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
    imagemagick
    shottr
    languagetool
  ];

  fonts.packages = with pkgs.nerd-fonts; [
    jetbrains-mono # Primary terminal font (Alacritty)
    fira-code
    meslo-lg
  ];

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
      "secp256k1"

      # Programming Languages & Runtimes
      "openjdk"
      "lua"
      "luarocks"

      # Shell Tools
      "zinit"
      "tfenv"
      "jwt-rs/jwt-ui/jwt-ui"
      "checkov" # Note: Installing via pkgmanager caused Wayland dependency.

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
      "postman"

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
      "vlc"
      "gimp"
      "transmission"

      # Communication & Entertainment
      "gather"
      "telegram"
      "slack"
      "spotify"
      "viber"
    ];
  };
}
