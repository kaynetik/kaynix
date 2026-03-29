{
  config,
  lib,
  pkgs,
  kaynixStatic,
  ...
}: let
  cfg = config.kaynix.programs.sketchybar;
in {
  options.kaynix.programs.sketchybar = {
    enable = lib.mkEnableOption "sketchybar";
  };

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isDarwin) {
    xdg.configFile."sketchybar" = {
      source = "${kaynixStatic}/sketchybar";
      recursive = true;
    };
  };
}
