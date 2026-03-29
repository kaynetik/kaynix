{
  config,
  lib,
  ...
}: let
  cfg = config.kaynix.programs.ssh;
in {
  options.kaynix.programs.ssh = {
    enable = lib.mkEnableOption "ssh";
  };

  config = lib.mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = {
        "*" = {
          extraOptions = {
            IgnoreUnknown = "UseKeychain";
            UseKeychain = "yes";
            AddKeysToAgent = "yes";
            ServerAliveInterval = "60";
            ServerAliveCountMax = "3";
          };
        };
        "github.com" = {
          hostname = "github.com";
          user = "git";
          identityFile = "~/.ssh/prim_sk_id_ed25519";
          identitiesOnly = true;
        };
        "gist.github.com" = {
          hostname = "gist.github.com";
          user = "git";
          identityFile = "~/.ssh/prim_sk_id_ed25519";
          identitiesOnly = true;
        };
      };
      extraConfig = lib.mkBefore ''
        Include ~/.ssh/conf.d/work
      '';
    };
  };
}
