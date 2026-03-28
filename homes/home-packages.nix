{
  config,
  lib,
  pkgs,
  ...
}: let
  dotNixRoot = "${config.home.homeDirectory}/Development/Personal/kaynix";

  kaynix-scripts = pkgs.runCommand "kaynix-scripts" {} ''
    mkdir -p $out/bin
    install -m755 ${../scripts/count-loc} $out/bin/count-loc
    install -m755 ${../scripts/on} $out/bin/on
    install -m755 ${../scripts/og} $out/bin/og
    cp ${../scripts/nvim-lazy-update} $out/bin/nvim-lazy-update
    chmod +x $out/bin/nvim-lazy-update
    substituteInPlace $out/bin/nvim-lazy-update \
      --replace '@DOT_NIX_ROOT@' '${dotNixRoot}'
  '';

  terminal = with pkgs; [
    alacritty
    tmux
    htop
    btop
    bat
    eza
    fd
    ripgrep
    tree
  ];

  gitTools = with pkgs; [
    git-filter-repo
    pre-commit
  ];

  dataParsing = with pkgs; [
    exiftool
    jq
    yq-go
  ];

  network = with pkgs; [
    croc
    curl
    grpcurl
    wget
    wireguard-tools
    wireguard-ui
  ];

  k8sAndOci = with pkgs; [
    argocd
    cmctl # Manage certs.
    k3d
    kubectl
    kubefwd
    kubernetes-helm
    kustomize
    k9s
    podman
    podman-desktop
    docker # in podman-compatibility mode
  ];

  iacAndCD = with pkgs; [
    bazel-buildtools
    bazelisk
    checkov
    infracost
    terraform-docs
    tflint
    trivy
  ];

  cloud = with pkgs; [
    awscli2
    (google-cloud-sdk.withExtraComponents [
      google-cloud-sdk.components.gke-gcloud-auth-plugin
    ])
  ];

  observability = with pkgs; [
    grafana-alloy
    prometheus
    prometheus.cli
  ];

  databases = with pkgs; [
    pgcli
    postgresql_18
    stripe-cli
  ];

  # Makes sense to now migrate to Go-dev env?
  goTools = with pkgs; [
    crane
    goose
    tparse
  ];

  media = with pkgs; [
    audacity
    imagemagick
    languagetool
  ];

  compilersAndRuntimes = with pkgs; [
    alejandra
    bun
    go
    hugo
    lua
    nodejs_24
    rustup
    zig
    foundry
  ];

  sshAndAge = with pkgs; [
    age
    sops
    age-plugin-yubikey
    openssh
    yubikey-agent
    yubikey-manager
    dotenvx
  ];

  darwinOnly = with pkgs; [
    jankyborders
    nowplaying-cli
    sbarlua
    switchaudio-osx
    shottr
  ];
in {
  # copyApps rsyncs materialized .app trees into ~/Applications/Home Manager Apps
  targets.darwin.copyApps.enable = true;
  targets.darwin.linkApps.enable = false;

  home.packages =
    [kaynix-scripts]
    ++ terminal
    ++ gitTools
    ++ dataParsing
    ++ network
    ++ k8sAndOci
    ++ iacAndCD
    ++ cloud
    ++ observability
    ++ databases
    ++ goTools
    ++ media
    ++ compilersAndRuntimes
    ++ sshAndAge
    ++ lib.optionals pkgs.stdenv.isDarwin darwinOnly;
}
