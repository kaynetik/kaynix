{
  config,
  lib,
  pkgs,
  ...
}: let
  # YubiKey age identity stub (local file; never commit). Layout and commands: homes/static/sops/README.md
  sopsAgeIdentityYubikey = "${config.xdg.configHome}/sops/age/age-yubikey-identity-nix-sops.txt";
  sopsLaunchAgentPlist = "${config.home.homeDirectory}/Library/LaunchAgents/org.nix-community.home.sops-nix.plist";

  # Same exports launchd passes to the sops-nix agent (needed for age-plugin-yubikey on PATH).
  sopsActivationEnvExports = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: value: "export ${name}=${lib.escapeShellArg (toString value)}") config.sops.environment
  );
in {
  # Decrypts secrets.yaml into ~/.config/zsh/conf-{seda,sietch}.zsh (see secrets/README.md).
  #
  # YubiKey (PIV) age identities: generate with `age-plugin-yubikey`, store the identity stub at
  # ~/.config/sops/age/age-yubikey-identity-nix-sops.txt (local; do not commit), add age1yubikey1... to .sops.yaml, then set
  # age.keyFile to sopsAgeIdentityYubikey and remove the bootstrap key from .sops.yaml.
  sops = {
    defaultSopsFile = ../secrets/secrets.yaml;
    age = {
      keyFile = sopsAgeIdentityYubikey;
      plugins = [pkgs.age-plugin-yubikey];
    };
    secrets = {
      "zsh-seda" = {
        key = "zsh_seda";
        path = "${config.xdg.configHome}/zsh/conf-seda.zsh";
        mode = "0600";
        format = "yaml";
      };
      "zsh-sietch" = {
        key = "zsh_sietch";
        path = "${config.xdg.configHome}/zsh/conf-sietch.zsh";
        mode = "0600";
        format = "yaml";
      };
      # Sensitive SSH host blocks (work servers, internal IPs, etc.).
      # Decrypted to ~/.ssh/conf.d/work and included by programs.ssh extraConfig.
      # Edit with: sops secrets/secrets.yaml  (add key: ssh_config_work)
      "ssh-work" = {
        key = "ssh_config_work";
        path = "${config.home.homeDirectory}/.ssh/conf.d/work";
        mode = "0600";
        format = "yaml";
      };
    };
  };

  # Create ~/.ssh/conf.d before sops-nix writes the work host block into it.
  home.activation.sshConfDir = lib.hm.dag.entryBefore ["sops-nix"] ''
    mkdir -p "${config.home.homeDirectory}/.ssh/conf.d"
    chmod 700 "${config.home.homeDirectory}/.ssh/conf.d"
  '';

  # sops-nix on Darwin: (1) Order after setupLaunchAgents so the plist exists
  # (https://github.com/Mic92/sops-nix/issues/910). (2) Run the same command the LaunchAgent uses
  # once synchronously here: decrypt only happens in that script, not in the bare launchctl lines,
  # and GUI launchd jobs often lack an interactive TTY for YubiKey. Repo zsh/conf-*.zsh is not
  # deployed to ~/.config/zsh; only these secrets do.
  home.activation.sops-nix = lib.mkIf pkgs.stdenv.isDarwin (
    lib.mkForce (
      lib.hm.dag.entryAfter ["setupLaunchAgents"] ''
        ${sopsActivationEnvExports}
        _plist=${lib.escapeShellArg sopsLaunchAgentPlist}
        if [[ -r "$_plist" ]]; then
          _cmd=$(/usr/libexec/PlistBuddy -c "Print :ProgramArguments:2" "$_plist" 2>/dev/null) || true
          if [[ -n "$_cmd" ]]; then
            /bin/bash -o errexit -c "$_cmd"
          fi
        fi
        _hm_uid="$(id -u)"
        /bin/launchctl bootout gui/''${_hm_uid}/org.nix-community.home.sops-nix && true
        /bin/launchctl bootstrap gui/''${_hm_uid} ${lib.escapeShellArg sopsLaunchAgentPlist}
      ''
    )
  );

  xdg.configFile."sops/age/README.md".source = ./static/sops/README.md;

  home.sessionVariables = {
    SOPS_AGE_KEY_FILE = sopsAgeIdentityYubikey;
  };
}
