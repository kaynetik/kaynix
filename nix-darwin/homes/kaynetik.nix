{
  config,
  pkgs,
  ...
}: let
  # Checkout root (flake is under nix-darwin/). Used by nvim-lazy-update.
  dotNixRoot = "${config.home.homeDirectory}/Development/Personal/dot-nix";

  # Scripts must be tracked by git (flake source filter).
  dot-nix-scripts = pkgs.runCommand "dot-nix-scripts" {} ''
    mkdir -p $out/bin
    install -m755 ${../scripts/count-loc} $out/bin/count-loc
    install -m755 ${../scripts/on} $out/bin/on
    install -m755 ${../scripts/og} $out/bin/og
    cp ${../scripts/nvim-Lazy-update} $out/bin/nvim-lazy-update
    chmod +x $out/bin/nvim-lazy-update
    substituteInPlace $out/bin/nvim-lazy-update \
      --replace '@DOT_NIX_ROOT@' '${dotNixRoot}'
  '';
in {
  programs.home-manager.enable = true;

  home.username = "kaynetik";
  home.homeDirectory = "/Users/kaynetik";
  home.stateVersion = "25.05";

  xdg.enable = true;

  home.packages =
    [dot-nix-scripts]
    ++ (with pkgs; [
    # wave 1: terminal
    alacritty
    tmux
    atuin
    htop
    fzf
    zoxide
    bat
    ripgrep
    fd
    eza
    # wave 2: editor + VCS helpers (git / git-lfs via programs.git; gh via programs.gh)
    # neovim binary via programs.neovim below
    git-filter-repo
    lazygit
    pre-commit
    # wave 2: structured data + files
    jq
    yq-go
    tree
    exiftool
    cmctl
    # wave 2: network
    curl
    wget
    croc
    grpcurl
    wireguard-tools
    wireguard-ui

    # wave 3: Kubernetes & containers
    kubectl
    kustomize
    k9s
    argocd
    kubefwd
    k3d
    kubernetes-helm
    podman
    podman-desktop
    sops
    checkov # if it fails to compile, check for Wayland issues
    bazel-buildtools
    bazelisk

    # wave 3: cloud platforms
    awscli2

    # wave 3: IaC & security scanning
    infracost
    tflint
    trivy
    terraform-docs

    # wave 3: monitoring & observability
    prometheus
    prometheus.cli # promtool
    grafana-alloy

    # wave 3: database & API tools
    postgresql_18
    pgcli
    stripe-cli

    # wave 3: Go development tools
    tparse # CLI summarizer for `go test` output
    goose
    crane

    # wave 3: media | audio | video
    audacity
    imagemagick
    shottr
    languagetool

    # these make sense only on darwin arch, shouldn't they be behind a flag?
    sbarlua
    jankyborders
    switchaudio-osx
    nowplaying-cli

    zig
    rustup
    go
    lua
    alejandra
    hugo
    bun
    nodejs
  ]);

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  xdg.configFile."nvim" = {
    source = ./static/nvim;
    recursive = true;
  };

  programs.gh.enable = true;

  programs.git = {
    enable = true;
    lfs.enable = true;
    signing = {
      format = "openpgp";
      signByDefault = true;
      key = "FC04210D2782C032";
    };
    settings = {
      user = {
        name = "kaynetik";
        email = "aleksandar@nesovic.dev";
      };
      credential = {helper = "osxkeychain";};
      push = {autoSetupRemote = true;};
      init = {defaultBranch = "main";};
      core = {
        excludesFile = "${config.xdg.configHome}/git/ignore_global";
        autocrlf = "input";
      };
      advice = {detachedHead = false;};
      http = {postBuffer = "524288000";};
    };
    ## Example when it's necessary to have different signing in specific repos.
    # includes = [
    #   {
    #     condition = "gitdir:${config.home.homeDirectory}/Development/Work/template/";
    #     path = "${config.home.homeDirectory}/.gitconfig_template";
    #   }
    # ];
  };

  # home.file.".gitconfig_template".source = ./static/git/template.gitconfig;

  xdg.configFile."git/ignore_global".source = ./static/git/ignore_global;

  programs.atuin = {
    enable = true;
    enableZshIntegration = false;
  };

  xdg.configFile."alacritty/alacritty.toml".source = ./static/alacritty/alacritty.toml;
  xdg.configFile."alacritty/catppuccin-frappe.toml".source = ./static/alacritty/catppuccin-frappe.toml;

  xdg.configFile."tmux" = {
    source = ./static/tmux;
    recursive = true;
  };

  xdg.configFile."sketchybar" = {
    source = ./static/sketchybar;
    recursive = true;
  };
}
