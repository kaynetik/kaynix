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
    # Uses only the commandcenter config; the main config would leak
    # connection sharing and agent keys into the observer identities.
    home.packages = lib.mkIf cfg.commandcenter.enable [
      (pkgs.writeShellScriptBin "ccssh" ''
        exec ${pkgs.openssh}/bin/ssh -F "$HOME/.ssh/cc/config" "$@"
      '')
    ];

    home.activation.sshSocketDir = lib.hm.dag.entryBefore ["linkGeneration"] ''
      run mkdir -p "${config.home.homeDirectory}/.ssh/sockets"
      run chmod 700 "${config.home.homeDirectory}/.ssh/sockets"
    '';

    # One launchd-supervised agent with a fixed socket path; keys are added on
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
      # Fragments from kaynix-vault. ssh reads them in lexical order and the
      # first value wins, so use numeric prefixes if two overlap.
      extraConfig = lib.mkBefore ''
        Include ~/.ssh/conf.d/*
      '';
    };
  };
}
