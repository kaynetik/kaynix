{
  config,
  lib,
  pkgs,
  ...
}: let
  dotNixRoot = "${config.home.homeDirectory}/Development/Personal/kaynix";

  kaynix-scripts = pkgs.runCommand "kaynix-scripts" {} ''
    mkdir -p $out/bin
    install -m755 ${../../scripts/count-loc} $out/bin/count-loc
    install -m755 ${../../scripts/on} $out/bin/on
    install -m755 ${../../scripts/og} $out/bin/og
    cp ${../../scripts/nvim-lazy-update} $out/bin/nvim-lazy-update
    chmod +x $out/bin/nvim-lazy-update
    substituteInPlace $out/bin/nvim-lazy-update \
      --replace '@DOT_NIX_ROOT@' '${dotNixRoot}'
  '';

  terminal = with pkgs; [
    alacritty
    zinit
    tmux
    htop
    btop
    bat
    fd
    ripgrep
    tree
  ];

  gitTools = with pkgs; [
    git-filter-repo
    lazyjj
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
    mimir
    cmctl
    k3d
    kubectl
    kubefwd
    kubernetes-helm
    kustomize
    k9s
    podman
    podman-desktop
    docker
  ];

  # nixpkgs `tfenv` (3.0.0) on Darwin trips upstream's check_dependencies():
  # when Homebrew is on PATH it requires GNU grep to be invocable as `ggrep`,
  # but the nix wrapper only exposes `grep` from gnugrep. Symlink it.
  tfenvWithGgrep = pkgs.tfenv.overrideAttrs (old: {
    postFixup =
      (old.postFixup or "")
      + ''
        ln -s ${pkgs.gnugrep}/bin/grep $out/bin/ggrep
      '';
  }); #TODO: Add a fix to the nixpkgs tfenv package to make it work on Darwin without this workaround.

  iacAndCD = with pkgs; [
    bazel-buildtools
    bazelisk
    checkov
    infracost
    tfenvWithGgrep
    terraform-docs
    tflint
    trivy
  ];

  cloud = with pkgs; [
    awscli2
    (google-cloud-sdk.withExtraComponents [
      google-cloud-sdk.components.gke-gcloud-auth-plugin
    ])
    hcloud
  ];

  observability = with pkgs; [
    grafana-alloy
    prometheus
    prometheus.cli
    macmon # monitor CPU, memory - freq & temps
  ];

  databases = with pkgs; [
    pgcli
    postgresql_18
    stripe-cli
  ];

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
    lua5_5
    (lua5_5.pkgs.luarocks)
    nodejs_24
    rustup
    zig
    foundry
    slither-analyzer
    solc # latest solc from nixpkgs (default `solc` on PATH)
    solc_0_8_19 # pinned solc 0.8.19 (exposed as `solc-0.8.19`) via solc-nix overlay
    svm-rs # alloy-rs svm CLI (`svm install 0.8.19`, `svm use 0.8.19`)
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
    # python314Packages.mlx-lm # Apple Silicon LLM runner (mlx_lm.* CLIs)
  ];
in {
  targets.darwin.copyApps.enable = lib.mkIf pkgs.stdenv.isDarwin true;
  targets.darwin.linkApps.enable = lib.mkIf pkgs.stdenv.isDarwin false;

  # Podman / docker CLI (k8sAndOci): SSH tunnel to VM and machine socket path.
  # tfenv (iacAndCD): TFENV_ROOT lives in the read-only nix store, so point
  # TFENV_CONFIG_DIR at a writable HOME path for installs, pins, and locks.
  home.sessionVariables = {
    DOCKER_HOST = "ssh://root@127.0.0.1:63646";
    DOCKER_SOCK = "/run/podman/podman.sock";
    TFENV_CONFIG_DIR = "${config.home.homeDirectory}/.tfenv";
  };

  home.activation.tfenvConfigDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run mkdir -p "${config.home.homeDirectory}/.tfenv/versions"
  '';
  # FIXME: ASAP FIX IN NIXPKGS

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
