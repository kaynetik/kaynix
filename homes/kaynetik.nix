{
  config,
  lib,
  pkgs,
  ...
}: let
  # Checkout root (flake at repo root). Used by nvim-lazy-update substitution.
  dotNixRoot = "${config.home.homeDirectory}/Development/Personal/kaynix";
  # YubiKey age identity stub (local file; never commit). Layout and commands: homes/static/sops/README.md
  sopsAgeIdentityYubikey = "${config.xdg.configHome}/sops/age/age-yubikey-identity-nix-sops.txt";
  sopsLaunchAgentPlist = "${config.home.homeDirectory}/Library/LaunchAgents/org.nix-community.home.sops-nix.plist";

  # Same exports launchd passes to the sops-nix agent (needed for age-plugin-yubikey on PATH).
  sopsActivationEnvExports = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: value: "export ${name}=${lib.escapeShellArg (toString value)}") config.sops.environment
  );

  # Scripts must be tracked by git (flake source filter).
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
  programs.home-manager.enable = true;

  home.username = "kaynetik";
  home.homeDirectory = "/Users/kaynetik";
  home.stateVersion = "26.05";

  xdg.enable = true;

  # programs.zsh.dotDir keeps the real zsh config under ~/.config/zsh/. zsh only reads that
  # directory when ZDOTDIR is set before the .zshrc phase. If it is not set, zsh falls back to
  # ~/.zshrc in $HOME (you had a second copy there without the nixpkgs OpenSSH PATH line).
  # Some hosts also source ~/.zshrc by path; delegate both to Home Manager.
  home.file.".zshenv".text = ''
    export ZDOTDIR="${config.home.homeDirectory}/.config/zsh"
    [[ -r "$ZDOTDIR/.zshenv" ]] && . "$ZDOTDIR/.zshenv"
  '';

  home.file.".zshrc".text = ''
    export ZDOTDIR="${config.home.homeDirectory}/.config/zsh"
    [[ -r "$ZDOTDIR/.zshrc" ]] && . "$ZDOTDIR/.zshrc"
  '';

  # sops-nix: decrypts secrets.yaml into ~/.config/zsh/conf-{seda,sietch}.zsh (see secrets/README.md).
  # Bootstrap key lives in the repo checkout; move to ~/Library/Application Support/sops/age/keys.txt
  # and rotate .sops.yaml before you store real secrets (especially if the repo is public).
  #
  # YubiKey (PIV) age identities: generate with `age-plugin-yubikey`, store the identity stub at
  # ~/.config/sops/age/age-yubikey-identity-nix-sops.txt (local; do not commit), add age1yubikey1... to .sops.yaml, then set
  # age.keyFile to sopsAgeIdentityYubikey and remove the bootstrap key from .sops.yaml.
  sops = {
    defaultSopsFile = ../secrets/secrets.yaml;
    age = {
      keyFile = sopsAgeIdentityYubikey;
      plugins = [pkgs.age-plugin-yubikey];
    };
    secrets = {
      "zsh-seda" = {
        key = "zsh_seda";
        path = "${config.xdg.configHome}/zsh/conf-seda.zsh";
        mode = "0600";
        format = "yaml";
      };
      "zsh-sietch" = {
        key = "zsh_sietch";
        path = "${config.xdg.configHome}/zsh/conf-sietch.zsh";
        mode = "0600";
        format = "yaml";
      };
      # Sensitive SSH host blocks (work servers, internal IPs, etc.).
      # Decrypted to ~/.ssh/conf.d/work and included by programs.ssh extraConfig.
      # Edit with: sops secrets/secrets.yaml  (add key: ssh_config_work)
      "ssh-work" = {
        key = "ssh_config_work";
        path = "${config.home.homeDirectory}/.ssh/conf.d/work";
        mode = "0600";
        format = "yaml";
      };
    };
  };

  # sops-nix on Darwin: (1) Order after setupLaunchAgents so the plist exists
  # (https://github.com/Mic92/sops-nix/issues/910). (2) Run the same command the LaunchAgent uses
  # once synchronously here: decrypt only happens in that script, not in the bare launchctl lines,
  # and GUI launchd jobs often lack an interactive TTY for YubiKey. Repo zsh/conf-*.zsh is not
  # deployed to ~/.config/zsh; only these secrets do.
  home.activation.sops-nix = lib.mkIf pkgs.stdenv.isDarwin (
    lib.mkForce (
      lib.hm.dag.entryAfter ["setupLaunchAgents"] ''
        ${sopsActivationEnvExports}
        _plist=${lib.escapeShellArg sopsLaunchAgentPlist}
        if [[ -r "$_plist" ]]; then
          _cmd=$(/usr/libexec/PlistBuddy -c "Print :ProgramArguments:2" "$_plist" 2>/dev/null) || true
          if [[ -n "$_cmd" ]]; then
            /bin/bash -o errexit -c "$_cmd"
          fi
        fi
        _hm_uid="$(id -u)"
        /bin/launchctl bootout gui/''${_hm_uid}/org.nix-community.home.sops-nix && true
        /bin/launchctl bootstrap gui/''${_hm_uid} ${lib.escapeShellArg sopsLaunchAgentPlist}
      ''
    )
  );

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
    [kaynix-scripts]
    ++ (with pkgs; [
      # Terminal
      alacritty
      tmux
      htop

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
      google-cloud-sdk

      # Observability
      grafana-alloy
      prometheus
      prometheus.cli

      # Databases and APIs
      pgcli
      postgresql_18
      stripe-cli

      # Go
      crane
      goose
      tparse

      # Media
      audacity
      imagemagick
      languagetool
      shottr

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
    # i3-like flow for MacOS
    ++ lib.optionals pkgs.stdenv.isDarwin (with pkgs; [
      jankyborders
      nowplaying-cli
      sbarlua
      switchaudio-osx
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

  # Create ~/.ssh/conf.d before sops-nix writes the work host block into it.
  home.activation.sshConfDir = lib.hm.dag.entryBefore ["sops-nix"] ''
    mkdir -p "${config.home.homeDirectory}/.ssh/conf.d"
    chmod 700 "${config.home.homeDirectory}/.ssh/conf.d"
  '';

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      # Global defaults.
      # AddKeysToAgent is understood by nixpkgs openssh (the binary on PATH).
      # UseKeychain is macOS-only (Apple openssh); IgnoreUnknown silences the
      # error when nixpkgs openssh parses this file.
      # Include cannot appear inside a Host block, so it goes in extraConfig
      # via lib.mkBefore to guarantee it lands before the Host blocks below.
      "*" = {
        extraOptions = {
          IgnoreUnknown = "UseKeychain";
          UseKeychain = "yes";
          AddKeysToAgent = "yes";
          ServerAliveInterval = "60";
          ServerAliveCountMax = "3";
        };
      };
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/ed_kaynetik";
        identitiesOnly = true;
      };
      "gist.github.com" = {
        hostname = "gist.github.com";
        user = "git";
        identityFile = "~/.ssh/ed_kaynetik";
        identitiesOnly = true;
      };
    };
    # Include must be a top-level directive; lib.mkBefore places it ahead of
    # the Host blocks that HM generates from matchBlocks above.
    extraConfig = lib.mkBefore ''
      Include ~/.ssh/conf.d/work
    '';
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
        excludesFile = "${config.home.homeDirectory}/.gitignore_global";
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

  home.file.".gitignore_global".source = ./static/git/ignore_global;

  xdg.configFile."sops/age/README.md".source = ./static/sops/README.md;

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
    EDITOR = "nvim";
    # Required by the sops CLI when editing secrets/secrets.yaml manually.
    # sops-nix itself uses the ageKeyFile field in the manifest, not this var.
    SOPS_AGE_KEY_FILE = sopsAgeIdentityYubikey;
  };

  # PATH for what's not in the nix store.
  home.sessionPath = [
    "${config.home.homeDirectory}/go/bin"
  ];

  programs.java = {
    enable = true;
    package = pkgs.jdk25;
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
        # sops-nix writes these paths at activation (see sops.secrets).
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
      (lib.mkAfter ''
        # After brew shellenv and oh-my-zsh: macOS /usr/bin OpenSSH has no working FIDO provider.
        # Prepend nixpkgs openssh so ssh, ssh-keygen, scp, sftp match (libfido2-backed sk keys).
        export PATH="${lib.makeBinPath [pkgs.openssh]}:$PATH"
      '')
    ];
  };

  xdg.configFile."zsh/aliases.zsh".source = ./static/zsh/aliases.zsh;
  xdg.configFile."zsh/setopt-history.zsh".source = ./static/zsh/setopt-history.zsh;

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
