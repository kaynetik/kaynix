{
  config,
  lib,
  pkgs,
  ...
}: let
  sopsAgeIdentityYubikey = "${config.xdg.configHome}/sops/age/age-yubikey-identity-nix-sops.txt";
  sopsLaunchAgentPlist = "${config.home.homeDirectory}/Library/LaunchAgents/org.nix-community.home.sops-nix.plist";

  # commandcenter: one ssh config plus three keys (nix hosts, router observer,
  # router admin), all under ~/.ssh/cc. Not included from ~/.ssh/config; used
  # only through `ccssh` or `ssh -F ~/.ssh/cc/config`.
  # Public keys are not managed: re-derived with `ssh-keygen -y -f ~/.ssh/cc/<file>`.
  ccEnabled = config.kaynix.programs.ssh.commandcenter.enable;
  ccFiles = {
    "ssh-cc-config" = {
      key = "ssh_config_cc";
      file = "config";
    };
    "ssh-cc-observe" = {
      key = "ssh_key_cc_observe";
      file = "cc_observe";
    };
    "ssh-cc-router-observer" = {
      key = "ssh_key_cc_router_observer";
      file = "cc_router_observer";
    };
    "ssh-cc-router-admin" = {
      key = "ssh_key_cc_router_admin";
      file = "cc_router_admin";
    };
  };
  ccSecrets = lib.optionalAttrs ccEnabled (
    lib.mapAttrs (_: v: {
      inherit (v) key;
      path = "${config.home.homeDirectory}/.ssh/cc/${v.file}";
      mode = "0600";
      format = "yaml";
    })
    ccFiles
  );

  secrets =
    ccSecrets
    // {
      "zsh-alpha" = {
        key = "zsh_alpha";
        path = "${config.xdg.configHome}/zsh/conf-alpha.zsh";
        mode = "0600";
        format = "yaml";
      };
      "zsh-bravo" = {
        key = "zsh_bravo";
        path = "${config.xdg.configHome}/zsh/conf-bravo.zsh";
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
      "ssh-charlie" = {
        key = "ssh_config_charlie";
        path = "${config.home.homeDirectory}/.ssh/conf.d/charlie";
        mode = "0600";
        format = "yaml";
      };
      "ssh-delta" = {
        key = "ssh_config_delta";
        path = "${config.home.homeDirectory}/.ssh/conf.d/delta";
        mode = "0600";
        format = "yaml";
      };
      "ssh-echo" = {
        key = "ssh_config_echo";
        path = "${config.home.homeDirectory}/.ssh/conf.d/echo";
        mode = "0600";
        format = "yaml";
      };
      "ssh-foxtrot" = {
        key = "ssh_config_foxtrot";
        path = "${config.home.homeDirectory}/.ssh/conf.d/foxtrot";
        mode = "0600";
        format = "yaml";
      };
      "ssh-golf" = {
        key = "ssh_config_golf";
        path = "${config.home.homeDirectory}/.ssh/conf.d/golf";
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
    defaultSopsFile = ../secrets/secrets.yaml;
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

  home.activation.sshCcDir = lib.mkIf ccEnabled (lib.hm.dag.entryBefore ["sops-nix"] ''
    mkdir -p "${config.home.homeDirectory}/.ssh/cc"
    chmod 700 "${config.home.homeDirectory}/.ssh/cc"
  '');

  # See secrets/README.md#darwin-activation-and-yubikey
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
