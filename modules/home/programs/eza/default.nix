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
      eld = "eza -lD --icons=auto";
      elf = "eza -lf --color=always --icons=auto | grep -v /";
      elh = "eza -dl .* --group-directories-first --icons=always";
      ell = "eza -al --group-directories-first --icons=always";
      els = "eza -alf --color=always --sort=size --icons=always | grep -v /";
      elt = "eza -lah --tree --level 2 --ignore-glob=.git";
      elt3 = "eza -lah --tree --level 3 --ignore-glob=.git";
    };
  };
}
