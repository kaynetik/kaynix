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

    commandcenter.enable = lib.mkEnableOption ''
      the commandcenter credentials: a separate ssh config and three dedicated
      keys under ~/.ssh/cc, decrypted by sops (module in the kaynix-vault
      input). The secrets must exist in the vault's secrets.yaml before this
      is switched on
    '';
  };

  config = lib.mkIf cfg.enable {
    # Same ssh, pointed at the commandcenter config only. The main config is
    # not involved: its connection sharing and agent keys would leak into the
    # observer identities.
    home.packages = lib.mkIf cfg.commandcenter.enable [
      (pkgs.writeShellScriptBin "ccssh" ''
        exec ${pkgs.openssh}/bin/ssh -F "$HOME/.ssh/cc/config" "$@"
      '')
    ];

    home.activation.sshSocketDir = lib.hm.dag.entryBefore ["linkGeneration"] ''
      run mkdir -p "${config.home.homeDirectory}/.ssh/sockets"
      run chmod 700 "${config.home.homeDirectory}/.ssh/sockets"
    '';

    # One supervised nix ssh-agent per login instead of per-shell probe/spawn:
    # launchd restarts it if it dies, the socket path never changes, and shells
    # only inherit the static SSH_AUTH_SOCK below. Keys land in the agent on
    # first use via AddKeysToAgent.
    launchd.agents.nix-ssh-agent = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
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

    home.sessionVariables = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
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
        Include ~/.ssh/conf.d/charlie
        Include ~/.ssh/conf.d/delta
        Include ~/.ssh/conf.d/echo
        Include ~/.ssh/conf.d/foxtrot
        Include ~/.ssh/conf.d/golf
      '';
    };
  };
}
