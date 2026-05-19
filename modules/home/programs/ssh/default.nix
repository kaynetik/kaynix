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
      settings = {
        "*" = {
          ControlMaster = "auto";
          ControlPath = "~/.ssh/sockets/%r@%h-%p";
          ControlPersist = "10m";
          IgnoreUnknown = "UseKeychain";
          UseKeychain = "yes";
          AddKeysToAgent = "yes";
          ServerAliveInterval = 60;
          ServerAliveCountMax = 3;
        };
        "github.com" = {
          HostName = "github.com";
          User = "git";
          IdentityFile = "~/.ssh/prim_sk_id_ed25519";
          IdentitiesOnly = true;
        };
        "gist.github.com" = {
          HostName = "gist.github.com";
          User = "git";
          IdentityFile = "~/.ssh/prim_sk_id_ed25519";
          IdentitiesOnly = true;
        };
      };
      extraConfig = lib.mkBefore ''
        Include ~/.ssh/conf.d/work
      '';
    };
  };
}
