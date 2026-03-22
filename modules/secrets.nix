{username, ...}: {
  # sops-nix (Home Manager) decrypts secrets at activation; see ../secrets/README.md and ../.sops.yaml.
  # Legacy: keep a writable area for non-sops scratch (optional).
  system.activationScripts.createSecretsDir.text = ''
    mkdir -p /Users/${username}/.config/nix-darwin/secrets
    chown ${username}:staff /Users/${username}/.config/nix-darwin/secrets
    chmod 700 /Users/${username}/.config/nix-darwin/secrets
  '';
}
