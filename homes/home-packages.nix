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
in {
  # copyApps rsyncs materialized .app trees into ~/Applications/Home Manager Apps. That often
  # fails with Permission denied on unlink (macOS TCC / bundle flags). linkApps instead symlinks
  # the merged home.packages Applications/ directory into the store; rebuilds update the link.
  targets.darwin.copyApps.enable = true;
  # targets.darwin.linkApps.enable = true;

  home.packages =
    [kaynix-scripts]
    ++ (with pkgs; [
      # Terminal
      alacritty
      tmux
      htop
      btop

      # Pager, search, listing
      bat
      eza
      fd
      ripgrep
      tree

      # Git
      git-filter-repo
      lazygit
      pre-commit

      # Data and certs
      cmctl
      exiftool
      jq
      yq-go

      # Network
      croc
      curl
      grpcurl
      wget
      wireguard-tools
      wireguard-ui

      # Kubernetes and OCI
      argocd
      k3d
      kubectl
      kubefwd
      kubernetes-helm
      kustomize
      k9s
      podman
      podman-desktop
      sops

      # IaC and policy
      bazel-buildtools
      bazelisk
      checkov
      infracost
      terraform-docs
      tflint
      trivy

      # Cloud CLIs
      awscli2
      (google-cloud-sdk.withExtraComponents [
        google-cloud-sdk.components.gke-gcloud-auth-plugin
      ])

      # Observability
      grafana-alloy
      prometheus
      prometheus.cli

      # Databases and APIs; maybe prep a DB-uber shell that would contain more tools?
      pgcli
      postgresql_18
      stripe-cli

      # Go => start migration to the dev shell
      crane
      goose
      tparse

      # Media
      audacity
      imagemagick
      languagetool

      # Compilers and runtimes
      alejandra
      bun
      go
      hugo
      lua
      nodejs_24
      rustup
      zig

      # SSH (nixpkgs openssh for FIDO on macOS) and age for SOPS
      age
      age-plugin-yubikey
      openssh
      yubikey-agent
      yubikey-manager
    ])
    ++ lib.optionals pkgs.stdenv.isDarwin (with pkgs; [
      # i3-like flow for MacOS
      jankyborders
      nowplaying-cli
      sbarlua
      switchaudio-osx

      shottr # Screen Shots
    ]);
}
