{
  config,
  lib,
  kaynixStatic,
  ...
}: let
  cfg = config.kaynix.programs.neovim;
in {
  options.kaynix.programs.neovim = {
    enable = lib.mkEnableOption "neovim";
  };

  config = lib.mkIf cfg.enable {
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
    };

    xdg.configFile."nvim" = {
      source = "${kaynixStatic}/nvim";
      recursive = true;
    };

    home.sessionVariables = {
      EDITOR = "nvim";
    };
  };
}
