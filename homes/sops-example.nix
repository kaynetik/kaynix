{
  config,
  lib,
  pkgs,
  ...
}: let
  sopsAgeIdentityYubikey = "${config.xdg.configHome}/sops/age/age-yubikey-identity-example.txt";
  sopsLaunchAgentPlist = "${config.home.homeDirectory}/Library/LaunchAgents/org.nix-community.home.sops-nix.plist";

  # Optional group of ssh material: one ssh config plus a few keys, all under
  # ~/.ssh/extra. Not included from ~/.ssh/config; used with `ssh -F ~/.ssh/extra/config`.
  # Public keys are not managed: re-derive with `ssh-keygen -y -f ~/.ssh/extra/<file>`.
  # Replace this flag with a module option if the group should be host-specific.
  extraEnabled = false;
  extraFiles = {
    "ssh-extra-config" = {
      key = "ssh_config_extra";
      file = "config";
    };
    "ssh-extra-key-a" = {
      key = "ssh_key_extra_a";
      file = "extra_a";
    };
    "ssh-extra-key-b" = {
      key = "ssh_key_extra_b";
      file = "extra_b";
    };
  };
  extraSecrets = lib.optionalAttrs extraEnabled (
    lib.mapAttrs (_: v: {
      inherit (v) key;
      path = "${config.home.homeDirectory}/.ssh/extra/${v.file}";
      mode = "0600";
      format = "yaml";
    })
    extraFiles
  );

  secrets =
    extraSecrets
    // {
      "zsh-example-a" = {
        key = "zsh_example_a";
        path = "${config.xdg.configHome}/zsh/conf-example-a.zsh";
        mode = "0600";
        format = "yaml";
      };
      "zsh-example-b" = {
        key = "zsh_example_b";
        path = "${config.xdg.configHome}/zsh/conf-example-b.zsh";
        mode = "0600";
        format = "yaml";
      };
      "ssh-host-a" = {
        key = "ssh_config_host_a";
        path = "${config.home.homeDirectory}/.ssh/conf.d/host-a";
        mode = "0600";
        format = "yaml";
      };
      "ssh-host-b" = {
        key = "ssh_config_host_b";
        path = "${config.home.homeDirectory}/.ssh/conf.d/host-b";
        mode = "0600";
        format = "yaml";
      };
    };

  sopsActivationEnvExports = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: value: "export ${name}=${lib.escapeShellArg (toString value)}") config.sops.environment
  );

  # Activation is skipped while the stamp matches the sops-nix launchd program (its
  # store path hashes the manifest: secret set, destination paths, sops file contents,
  # sops-install-secrets build) and every destination is a symlink that resolves. The decrypted
  # tree lives under $DARWIN_USER_TEMP_DIR, so a reboot breaks the symlinks and
  # forces one fresh decryption.
  sopsProgram = config.launchd.agents.sops-nix.config.Program;
  sopsStampFile = "${config.xdg.stateHome}/sops-nix/last-activated";
  sopsDestinations = lib.concatMapStringsSep " " (s: lib.escapeShellArg s.path) (lib.attrValues secrets);

  # See README.md#sops-rekey in the vault
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
    mkdir -p "$(dirname ${lib.escapeShellArg sopsStampFile})"
    printf '%s' ${lib.escapeShellArg (toString sopsProgram)} > ${lib.escapeShellArg sopsStampFile}
  '';

  sopsUpToDate = pkgs.writeShellScript "sops-up-to-date" ''
    [[ -r ${lib.escapeShellArg sopsStampFile} ]] || exit 1
    [[ "$(< ${lib.escapeShellArg sopsStampFile})" == ${lib.escapeShellArg (toString sopsProgram)} ]] || exit 1
    for _p in ${sopsDestinations}; do
      [[ -L "$_p" && -e "$_p" ]] || exit 1
    done
  '';
in {
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age = {
      keyFile = sopsAgeIdentityYubikey;
      plugins = [pkgs.age-plugin-yubikey];
    };
    inherit secrets;
  };

  home.activation.sshConfDir = lib.hm.dag.entryBefore ["sops-nix"] ''
    mkdir -p "${config.home.homeDirectory}/.ssh/conf.d"
    chmod 700 "${config.home.homeDirectory}/.ssh/conf.d"
  '';

  home.activation.sshExtraDir = lib.mkIf extraEnabled (lib.hm.dag.entryBefore ["sops-nix"] ''
    mkdir -p "${config.home.homeDirectory}/.ssh/extra"
    chmod 700 "${config.home.homeDirectory}/.ssh/extra"
  '');

  # See README.md#darwin-activation-and-yubikey in the vault
  home.activation.sops-nix = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin (
    lib.mkForce (
      lib.hm.dag.entryAfter ["setupLaunchAgents"] ''
        if ${sopsUpToDate}; then
          run echo "sops-nix: secrets up to date, skipping decryption"
        elif ${sopsRekeyScript} 2>/dev/null; then
          run echo "sops-nix: secrets decrypted"
        else
          run echo "sops-nix: decryption skipped (no TTY or YubiKey). Run 'sops-rekey' manually."
        fi
      ''
    )
  );

  # See README.md#sops-rekey in the vault
  home.packages = [
    (pkgs.writeShellScriptBin "sops-rekey" ''
      exec ${sopsRekeyScript} "$@"
    '')
  ];

  home.sessionVariables = {
    SOPS_AGE_KEY_FILE = sopsAgeIdentityYubikey;
  };
}
