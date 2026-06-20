{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaynix.programs.hunk;
  toml = pkgs.formats.toml {};
in {
  options.kaynix.programs.hunk = {
    enable = lib.mkEnableOption "hunk diff viewer";

    package = lib.mkPackageOption pkgs "hunk" {};

    enableGitIntegration = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Configure git to use hunk as its pager.";
    };

    settings = lib.mkOption {
      inherit (toml) type;
      default = {};
      example = {
        theme = "graphite";
        mode = "auto";
        line_numbers = true;
        wrap_lines = false;
      };
      description = "Written to {file}`$XDG_CONFIG_HOME/hunk/config.toml`.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [cfg.package];

    xdg.configFile."hunk/config.toml" = lib.mkIf (cfg.settings != {}) {
      source = toml.generate "hunk-config" cfg.settings;
    };

    programs.git.settings.core.pager =
      lib.mkIf cfg.enableGitIntegration "${lib.getExe cfg.package} pager";
  };
}
