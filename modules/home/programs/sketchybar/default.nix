{
  config,
  lib,
  pkgs,
  kaynixStatic,
  hostConfig,
  ...
}: let
  cfg = config.kaynix.programs.sketchybar;
  sketchybarTheme = (hostConfig.sketchybar or {}).theme or "tokyo_night";
in {
  options.kaynix.programs.sketchybar = {
    enable = lib.mkEnableOption "sketchybar";
  };

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isDarwin) {
    xdg.configFile."sketchybar" = {
      source = "${kaynixStatic}/sketchybar";
      recursive = true;
    };

    # Matches launchd (modules/apps.nix); set theme in flake host `config.sketchybar.theme`.
    home.sessionVariables.SKETCHYBAR_THEME = sketchybarTheme;
  };
}
