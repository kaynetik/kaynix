{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaynix.programs.jujutsu;
in {
  options.kaynix.programs.jujutsu = {
    enable = lib.mkEnableOption "jujutsu (jj)";
  };

  config = lib.mkIf cfg.enable {
    programs.jujutsu = {
      enable = true;
      settings = {
        user = {
          name = "kaynetik";
          email = "aleksandar@nesovic.dev";
        };
        fetch.prune = true;
        init.default_branch = "main";
        lfs.enabled = true;
        signing = {
          backend = "ssh";
          key = "${config.home.homeDirectory}/.ssh/prim_sk_id_ed25519";
        };
        push = {
          autoSetupRemote = true;
          default = "current";
        };
        rebase.auto_stash = true;
        ui.default-command = "log";
      };
    };

    home.shellAliases = lib.mkIf pkgs.stdenv.isDarwin {
      jj = "RAYON_NUM_THREADS=4 command jj";
    };
  };
}
