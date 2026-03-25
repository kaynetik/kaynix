{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./agents.nix
    ./home-packages.nix
    ./zsh-config.nix
    ./sops.nix
  ];

  programs.home-manager.enable = true;

  home.username = "kaynetik";
  home.homeDirectory = "/Users/kaynetik";
  home.stateVersion = "26.05";

  xdg.enable = true;

  home.file = {
    # Alacritty.app: stable path for Launchpad / "Open with" / App Management
    "Applications/Alacritty.app" = lib.mkIf pkgs.stdenv.isDarwin {
      source = "${pkgs.alacritty}/Applications/Alacritty.app";
      recursive = true;
    };
    ".gitignore_global".source = ./static/git/ignore_global;
  };

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

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
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
        identityFile = "~/.ssh/prim_sk_id_ed25519";
        identitiesOnly = true;
      };
      "gist.github.com" = {
        hostname = "gist.github.com";
        user = "git";
        identityFile = "~/.ssh/prim_sk_id_ed25519";
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
    EDITOR = "nvim";
  };

  # PATH for what's not in the nix store.
  home.sessionPath = [
    "${config.home.homeDirectory}/go/bin"
  ];

  programs.java = {
    enable = true;
    package = pkgs.jdk25;
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
