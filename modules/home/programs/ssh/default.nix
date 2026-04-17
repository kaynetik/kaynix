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
    home.activation.sshSocketDir = lib.hm.dag.entryBefore ["linkGeneration"] ''
      run mkdir -p "${config.home.homeDirectory}/.ssh/sockets"
      run chmod 700 "${config.home.homeDirectory}/.ssh/sockets"
    '';

    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = {
        "*" = {
          controlMaster = "auto";
          controlPath = "~/.ssh/sockets/%r@%h-%p";
          controlPersist = "10m";
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
