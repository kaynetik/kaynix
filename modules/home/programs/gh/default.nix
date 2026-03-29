{
  config,
  lib,
  ...
}: let
  cfg = config.kaynix.programs.gh;
in {
  options.kaynix.programs.gh = {
    enable = lib.mkEnableOption "GitHub CLI";
  };

  config = lib.mkIf cfg.enable {
    programs.gh.enable = true;
  };
}
