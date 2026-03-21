{
  config,
  lib,
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
  home.stateVersion = "26.05";

  xdg.enable = true;

  # copyApps rsyncs materialized .app trees into ~/Applications/Home Manager Apps. That often
  # fails with Permission denied on unlink (macOS TCC / bundle flags). linkApps instead symlinks
  # the merged home.packages Applications/ directory into the store; rebuilds update the link.
  targets.darwin.copyApps.enable = true;
  # targets.darwin.linkApps.enable = true;

  # One stable path for Launchpad / "Open with" / App Management: points at the current
  # pkgs.alacritty bundle in the store; updated on every home activation / darwin-rebuild.
  home.file."Applications/Alacritty.app" = lib.mkIf pkgs.stdenv.isDarwin {
    source = "${pkgs.alacritty}/Applications/Alacritty.app";
    recursive = true;
  };

  home.packages =
    [dot-nix-scripts]
    ++ (with pkgs; [
    # wave 1: terminal
    alacritty
    tmux
    htop
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
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
      "--border"
      "--inline-info"
      "--color=bg+:#414559,bg:#303446,spinner:#f2d5cf,hl:#e78284"
      "--color=fg:#c6d0f5,header:#e78284,info:#ca9ee6,pointer:#f2d5cf"
      "--color=marker:#f2d5cf,fg+:#c6d0f5,prompt:#ca9ee6,hl+:#e78284"
    ];
  };

  home.sessionVariables = {
    ZSH_DISABLE_COMPFIX = "true";
    DISABLE_MAGIC_FUNCTIONS = "true";
    HIST_STAMPS = "dd.mm.yyyy";
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    dotDir = "${config.xdg.configHome}/zsh";
    "oh-my-zsh" = {
      enable = true;
      theme = "bira";
      plugins = ["git"];
    };
    # zinit stays on Homebrew. Order: mkBefore (early), mkOrder 550 (before oh-my-zsh), tail (after HM hooks).
    initContent = lib.mkMerge [
      (lib.mkBefore ''
        eval "$(/opt/homebrew/bin/brew shellenv)"
        source /opt/homebrew/opt/zinit/zinit.zsh
        zinit light zsh-users/zsh-autosuggestions
        zinit light zdharma-continuum/fast-syntax-highlighting
        zinit light marlonrichert/zsh-autocomplete
        ulimit -n 65536
        source ${config.xdg.configHome}/zsh/setopt-history.zsh
        source ${config.xdg.configHome}/zsh/aliases.zsh
        source ${config.xdg.configHome}/zsh/exports.zsh
        [[ -r ${config.xdg.configHome}/zsh/conf-seda.zsh ]] && source ${config.xdg.configHome}/zsh/conf-seda.zsh
        [[ -r ${config.xdg.configHome}/zsh/conf-sietch.zsh ]] && source ${config.xdg.configHome}/zsh/conf-sietch.zsh
      '')
      (lib.mkOrder 550 ''
        zstyle ':omz:update' mode auto
        export GPG_TTY=$(tty)
      '')
      ''
        # Atuin, zoxide, fzf: Home Manager adds hooks when programs.*.enableZshIntegration is true.
        bindkey '^[[1;9A' beginning-of-line
        bindkey '^[[1;9B' end-of-line
      ''
    ];
  };

  xdg.configFile."zsh/aliases.zsh".source = ./static/zsh/aliases.zsh;
  xdg.configFile."zsh/setopt-history.zsh".source = ./static/zsh/setopt-history.zsh;
  xdg.configFile."zsh/exports.zsh".source = ./static/zsh/exports.zsh;

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
