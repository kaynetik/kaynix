{pkgs, ...}: {
  services.sketchybar.enable = true;

  environment.systemPackages = with pkgs; [
    # ============================================================
    # Languages & Runtimes
    # ============================================================
    zig
    rustup
    go
    lua
    alejandra
    hugo
    bun
    nodejs

    # ============================================================
    # Nix - i3 akin flow
    # ============================================================
    sbarlua
    jankyborders
    switchaudio-osx
    nowplaying-cli

    # ============================================================
    # VCS
    # ============================================================
    git
    git-lfs
    git-filter-repo
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
    # zinit -> fix for nixdarwin
    zoxide
    fzf
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
    # mvt # phone spyware analysis
    cmctl # interact with a cert-manager instalation on k8s
    # dotenvx -> broken upstream, PR pending: https://github.com/NixOS/nixpkgs/pull/500959#issuecomment-4103458168

    # ============================================================
    # Network & Transfer Utilities
    # ============================================================
    curl
    wget
    croc
    grpcurl
    wireguard-tools
    wireguard-ui

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
    podman
    podman-desktop
    sops # manage encryption keys
    checkov # if it fails to compile, check for Wayland issues
    bazel-buildtools
    bazelisk

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

    # ============================================================
    # Go Development Tools
    # ============================================================
    tparse # CLI summarizer for `go test` output
    goose
    crane

    # ============================================================
    # Media | Audio | Video
    # ============================================================
    audacity
    imagemagick
    shottr
    languagetool
    # vlc => fix this for darwinians?
  ];

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
      "openjdk" # equal alt in nix?
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
      "lulu"
      "reikey"
      "protonvpn"
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
      "gcloud-cli"
      "docker-desktop"
      "lens" # k9s migration should happen asap!

      # Media Tools
      "calibre"
      "vlc"
      "spotify"
      "gimp"
      "transmission"
      "unetbootin"

      # Communication
      "telegram"
      "slack"
    ];
  };
}
