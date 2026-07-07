{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaynix.programs.ssh;
  identity = config.kaynix.identity;
  agentSocket = "${config.home.homeDirectory}/.ssh/nix-ssh-agent.sock";
in {
  options.kaynix.programs.ssh = {
    enable = lib.mkEnableOption "ssh";
  };

  config = lib.mkIf cfg.enable {
    home.activation.sshSocketDir = lib.hm.dag.entryBefore ["linkGeneration"] ''
      run mkdir -p "${config.home.homeDirectory}/.ssh/sockets"
      run chmod 700 "${config.home.homeDirectory}/.ssh/sockets"
    '';

    # One supervised nix ssh-agent per login instead of per-shell probe/spawn:
    # launchd restarts it if it dies, the socket path never changes, and shells
    # only inherit the static SSH_AUTH_SOCK below. Keys land in the agent on
    # first use via AddKeysToAgent.
    launchd.agents.nix-ssh-agent = lib.mkIf pkgs.stdenv.isDarwin {
      enable = true;
      config = {
        ProgramArguments = [
          "/bin/sh"
          "-c"
          ''rm -f "${agentSocket}"; exec ${pkgs.openssh}/bin/ssh-agent -D -a "${agentSocket}"''
        ];
        KeepAlive = true;
        RunAtLoad = true;
      };
    };

    home.sessionVariables = lib.mkIf pkgs.stdenv.isDarwin {
      SSH_AUTH_SOCK = agentSocket;
    };

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
          IdentityFile = identity.ssh.keyFile;
          IdentitiesOnly = true;
        };
        "gist.github.com" = {
          HostName = "gist.github.com";
          User = "git";
          IdentityFile = identity.ssh.keyFile;
          IdentitiesOnly = true;
        };
      };
      extraConfig = lib.mkBefore ''
        Include ~/.ssh/conf.d/work
      '';
    };
  };
}
