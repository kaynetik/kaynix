{
  config,
  lib,
  ...
}: let
  cfg = config.kaynix.programs.eza;
in {
  options.kaynix.programs.eza = {
    enable = lib.mkEnableOption "eza";
  };

  config = lib.mkIf cfg.enable {
    programs.eza = {
      enable = true;
      enableZshIntegration = true;
      extraOptions = [
        "--group-directories-first"
        "--header"
        "--hyperlink"
        "--follow-symlinks"
      ];
      git = true;
      icons = "auto";
    };

    home.shellAliases = {
      la = "eza -lah --tree";
      tree = "eza --tree --icons=always";
    };
  };
}
