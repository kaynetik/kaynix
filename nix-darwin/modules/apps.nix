{pkgs, ...}: {
  services.sketchybar.enable = true;

  # environment.systemPackages = with pkgs; [
    # ============================================================
    # Languages & Runtimes
    # ============================================================


    # ============================================================
    # Nix - i3 akin flow
    # ============================================================


    # ============================================================
    # VCS
    # (git, git-lfs, git-filter-repo, lazygit, gh, pre-commit -> homes/kaynetik.nix + programs.git / programs.gh)
    # ============================================================

    # ============================================================
    # Terminal & Shell Utilities
    # (alacritty, tmux, atuin, zoxide, fzf, htop, bat, ripgrep, fd, eza, neovim, jq, yq-go, tree, exiftool, cmctl,
    #  curl, wget, croc, grpcurl, wireguard-tools, wireguard-ui -> home.packages in homes/kaynetik.nix)
    # ============================================================
    # zinit stays on Homebrew (nixpkgs zinit has issues)
    #
    # mvt # phone spyware analysis
    # dotenvx -> broken upstream, PR pending: https://github.com/NixOS/nixpkgs/pull/500959#issuecomment-4103458168

    # ============================================================
    # Kubernetes & Container Tools
    # (kubectl, kustomize, k9s, argocd, kubefwd, k3d, kubernetes-helm, podman, podman-desktop,
    #  sops, checkov, bazel-buildtools, bazelisk -> home.packages in homes/kaynetik.nix)
    # ============================================================

    # ============================================================
    # Cloud Platforms
    # (awscli2 -> home.packages in homes/kaynetik.nix)
    # ============================================================

    # ============================================================
    # IaC & Security
    # (infracost, tflint, trivy, terraform-docs -> home.packages in homes/kaynetik.nix)
    # ============================================================

    # ============================================================
    # Monitoring & Observability
    # (prometheus, prometheus.cli, grafana-alloy -> home.packages in homes/kaynetik.nix)
    # ============================================================

    # ============================================================
    # Database & API Tools
    # (postgresql_18, pgcli, stripe-cli -> home.packages in homes/kaynetik.nix)
    # ============================================================

    # ============================================================
    # Go Development Tools
    # (tparse, goose, crane -> home.packages in homes/kaynetik.nix)
    # ============================================================

    # ============================================================
    # Media | Audio | Video
    # (audacity, imagemagick, shottr, languagetool -> home.packages in homes/kaynetik.nix)
    # vlc => fix this for darwinians?
    # ============================================================
  # ];

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
      "lens" # Rice k9s more to reach the LENS usability levels.

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
