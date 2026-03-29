{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaynix.programs.java;
in {
  options.kaynix.programs.java = {
    enable = lib.mkEnableOption "java";
  };

  config = lib.mkIf cfg.enable {
    programs.java = {
      enable = true;
      package = pkgs.jdk25;
    };
  };
}
