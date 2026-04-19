{
  config,
  lib,
  pkgs,
  ...
}: let
  sopsAgeIdentityYubikey = "${config.xdg.configHome}/sops/age/age-yubikey-identity-nix-sops.txt";
  sopsLaunchAgentPlist = "${config.home.homeDirectory}/Library/LaunchAgents/org.nix-community.home.sops-nix.plist";

  sopsActivationEnvExports = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: value: "export ${name}=${lib.escapeShellArg (toString value)}") config.sops.environment
  );

  # See secrets/README.md#sops-rekey
  sopsRekeyScript = pkgs.writeShellScript "sops-rekey" ''
    set -euo pipefail
    _plist=${lib.escapeShellArg sopsLaunchAgentPlist}
    if [[ ! -r "$_plist" ]]; then
      echo "sops-rekey: plist not found at $_plist" >&2
      exit 1
    fi
    _cmd=$(/usr/libexec/PlistBuddy -c "Print :ProgramArguments:2" "$_plist" 2>/dev/null) || true
    if [[ -z "$_cmd" ]]; then
      echo "sops-rekey: could not extract command from plist" >&2
      exit 1
    fi
    ${sopsActivationEnvExports}
    /bin/bash -o errexit -c "$_cmd"
  '';
in {
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
      "zsh-flowd" = {
        key = "zsh_flowd";
        path = "${config.xdg.configHome}/zsh/conf-flowd.zsh";
        mode = "0600";
        format = "yaml";
      };
      "zsh-kube-ctx-aliases" = {
        key = "zsh_kube_ctx_aliases";
        path = "${config.xdg.configHome}/zsh/conf-kube-ctx-aliases.zsh";
        mode = "0600";
        format = "yaml";
      };
      "ssh-work" = {
        key = "ssh_config_work";
        path = "${config.home.homeDirectory}/.ssh/conf.d/work";
        mode = "0600";
        format = "yaml";
      };
    };
  };

  home.activation.sshConfDir = lib.hm.dag.entryBefore ["sops-nix"] ''
    mkdir -p "${config.home.homeDirectory}/.ssh/conf.d"
    chmod 700 "${config.home.homeDirectory}/.ssh/conf.d"
  '';

  # See secrets/README.md#darwin-activation-and-yubikey
  home.activation.sops-nix = lib.mkIf pkgs.stdenv.isDarwin (
    lib.mkForce (
      lib.hm.dag.entryAfter ["setupLaunchAgents"] ''
        if ${sopsRekeyScript} 2>/dev/null; then
          run echo "sops-nix: secrets decrypted"
        else
          run echo "sops-nix: decryption skipped (no TTY or YubiKey). Run 'sops-rekey' manually."
        fi
      ''
    )
  );

  # See secrets/README.md#sops-rekey
  home.packages = [
    (pkgs.writeShellScriptBin "sops-rekey" ''
      exec ${sopsRekeyScript} "$@"
    '')
  ];

  xdg.configFile."sops/age/README.md".source = ./static/sops/README.md;

  home.sessionVariables = {
    SOPS_AGE_KEY_FILE = sopsAgeIdentityYubikey;
  };
}
