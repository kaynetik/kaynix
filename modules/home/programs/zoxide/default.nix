{
  config,
  lib,
  ...
}: let
  cfg = config.kaynix.programs.zoxide;
in {
  options.kaynix.programs.zoxide = {
    enable = lib.mkEnableOption "zoxide";
  };

  config = lib.mkIf cfg.enable {
    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
