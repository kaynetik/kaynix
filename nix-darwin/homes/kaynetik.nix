{
  config,
  pkgs,
  ...
}: {
  programs.home-manager.enable = true;

  home.username = "kaynetik";
  home.homeDirectory = "/Users/kaynetik";
  home.stateVersion = "25.05";

  xdg.enable = true;

  home.packages = with pkgs; [
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
  ];

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
    # includes = [ # old example; cleannup
    #   {
    #     condition = "gitdir:${config.home.homeDirectory}/Development/Work/opencorp/";
    #     path = "${config.home.homeDirectory}/.gitconfig_opencorp";
    #   }
    # ];
  };

  # home.file.".gitconfig_opencorp".source = ./static/git/opencorp.gitconfig;

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
