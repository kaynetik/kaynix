{
  config,
  lib,
  ...
}: let
  cfg = config.kaynix.programs.atuin;
in {
  options.kaynix.programs.atuin = {
    enable = lib.mkEnableOption "atuin";
  };

  config = lib.mkIf cfg.enable {
    programs.atuin = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
