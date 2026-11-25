{
  config,
  lib,
  pkgs,
  ...
}: let
  dotNixRoot = "${config.home.homeDirectory}/Development/Personal/kaynix";
  obsidianVault = "${config.home.homeDirectory}/Documents/obsidian_vault";

  kaynix-scripts = pkgs.runCommand "kaynix-scripts" {} ''
    mkdir -p $out/bin
    install -m755 ${../../scripts/count-loc} $out/bin/count-loc
    install -m755 ${../../scripts/objsee-check} $out/bin/objsee-check
    install -m755 ${../../scripts/filevault-check} $out/bin/filevault-check
    install -m755 ${../../scripts/on} $out/bin/on
    install -m755 ${../../scripts/og} $out/bin/og
    cp ${../../scripts/nvim-lazy-update} $out/bin/nvim-lazy-update
    chmod +x $out/bin/nvim-lazy-update
    substituteInPlace $out/bin/nvim-lazy-update \
      --replace-fail '@DOT_NIX_ROOT@' '${dotNixRoot}'
    substituteInPlace $out/bin/on \
      --replace-fail '@OBSIDIAN_VAULT@' '${obsidianVault}'
    substituteInPlace $out/bin/og \
      --replace-fail '@OBSIDIAN_VAULT@' '${obsidianVault}'
    substituteInPlace $out/bin/objsee-check \
      --replace-fail '@PYTHON3@' '${pkgs.python3.interpreter}'
  '';

  shellTools = with pkgs; [
    alacritty
    tmux
    zinit
    bat
    fd
    ripgrep
    tree
  ];

  systemMonitors = with pkgs; [
    htop
    btop
    macmon
  ];

  dataTools = with pkgs; [
    jq
    yq-go
    exiftool
    shellcheck
  ];

  networkTools = with pkgs; [
    curl
    wget
    grpcurl
    croc
    netbird
    wireguard-tools
    wireguard-ui
  ];

  mediaTools = with pkgs; [
    ffmpeg
    sox
    imagemagick
    audacity
    languagetool
    anomaly-hex # local voice transcriber (https://github.com/anomalyco/hex)
  ];

  vcsTools = with pkgs; [
    git-filter-repo
    lazyjj
    pre-commit
  ];

  languageToolchains = with pkgs; [
    go
    tparse
    rustup
    zig
    nodejs_26
    bun
    uv
    lua5_5
    lua5_5.pkgs.luarocks
    stylua
    protobuf
    hugo
  ];

  buildTools = with pkgs; [
    bazelisk
    bazel-buildtools
  ];

  nixTools = with pkgs; [
    nil
    alejandra
    statix
    deadnix
    nixos-rebuild
    nixpkgs-review
  ];

  web3Tools = with pkgs; [
    foundry
    slither-analyzer # 26.11 - too many failures!
    solc # latest solc from nixpkgs (default `solc` on PATH)
    solc_0_8_19 # pinned solc 0.8.19 (exposed as `solc-0.8.19`) via solc-nix overlay
    svm-rs # alloy-rs svm CLI (`svm install 0.8.19`, `svm use 0.8.19`)
  ];

  kubernetesTools = with pkgs; [
    kubectl
    kubectl-cnpg
    kubernetes-helm
    kustomize
    kubeconform
    k9s
    k3d
    kubefwd
    cmctl
    argocd
  ];

  containerTools = with pkgs; [
    docker
    podman
    podman-desktop
    crane
  ];

  iacTools = with pkgs; [
    tfenv
    terraform-docs
    tflint
    checkov
    infracost
  ];

  cloudTools = with pkgs; [
    awscli2
    (google-cloud-sdk.withExtraComponents [
      google-cloud-sdk.components.gke-gcloud-auth-plugin
    ])
    hcloud
  ];

  observabilityTools = with pkgs; [
    grafana-alloy
    prometheus
    prometheus.cli
    mimir
  ];

  dataAndServices = with pkgs; [
    postgresql_18
    pgcli
    goose
    rabbitmqadmin-ng
    stripe-cli
  ];

  secretsAndKeys = with pkgs; [
    age
    age-plugin-yubikey
    sops
    dotenvx
    openssh
    yubikey-agent
    yubikey-manager
  ];

  securityScanners = with pkgs; [
    trivy
    cosign
    osv-scanner
    trufflehog
    gitleaks
    clamav
  ];

  osintTools = with pkgs; [
    theharvester
    sherlock
    recon-ng
  ];

  darwinDesktop = with pkgs; [
    jankyborders
    sbarlua
    nowplaying-cli
    switchaudio-osx
    raycast
    shottr
    zapmenu
  ];

  darwinTools = with pkgs; [
    macfuse-stubs
    e2fsprogs
    fluidaudiocli
  ];
in {
  targets.darwin.copyApps.enable = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin true;
  targets.darwin.linkApps.enable = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin false;

  # Podman / docker CLI (containerTools): SSH tunnel to VM and machine socket path.
  home.sessionVariables = {
    DOCKER_HOST = "ssh://root@127.0.0.1:63646";
    DOCKER_SOCK = "/run/podman/podman.sock";
  };

  home.packages = lib.concatLists [
    [kaynix-scripts]

    shellTools
    systemMonitors
    dataTools
    networkTools
    mediaTools
    vcsTools

    languageToolchains
    buildTools
    nixTools
    web3Tools

    kubernetesTools
    containerTools
    iacTools
    cloudTools
    observabilityTools
    dataAndServices

    secretsAndKeys
    securityScanners
    osintTools

    (lib.optionals pkgs.stdenv.hostPlatform.isDarwin (darwinDesktop ++ darwinTools))
  ];
}
