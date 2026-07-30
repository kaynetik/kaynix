{
  config,
  lib,
  pkgs,
  username,
  hostConfig,
  ...
}: {
  imports = [
    ../modules/home
    ./sops.nix
  ];

  programs.home-manager.enable = true;

  home.username = username;
  home.homeDirectory =
    if pkgs.stdenv.isDarwin
    then "/Users/${username}"
    else "/home/${username}";
  home.stateVersion = hostConfig.homeStateVersion or "24.11";
  home.enableNixpkgsReleaseCheck = false;

  xdg.enable = true;

  home.sessionPath = [
    "${config.home.homeDirectory}/.cargo/bin"
    "${config.home.homeDirectory}/go/bin"
    "${config.home.homeDirectory}/.local/bin"
  ];

  # Working tree layout that no module owns. The zsh directory is already a
  # side effect of linking that module's config, so this only has to hold when
  # zsh is disabled; ordering before sops-nix keeps the decrypted fragment
  # targets valid in that case (see homes/sops.nix).
  home.activation.userDirectories = lib.hm.dag.entryBefore ["sops-nix"] ''
    run mkdir -p \
      "${config.home.homeDirectory}/Development/Work" \
      "${config.home.homeDirectory}/Development/Personal" \
      "${config.home.homeDirectory}/Development/Nix/flakes" \
      "${config.home.homeDirectory}/Development/Nix/shells" \
      "${config.xdg.configHome}/zsh"
  '';

  kaynix.programs = {
    agents.enable = lib.mkDefault true;
    atuin.enable = lib.mkDefault true;
    eza.enable = lib.mkDefault true;
    fzf.enable = lib.mkDefault true;
    gh.enable = lib.mkDefault true;
    git.enable = lib.mkDefault true;
    hunk.enable = lib.mkDefault true;
    java.enable = lib.mkDefault true;
    jjui.enable = lib.mkDefault true;
    jujutsu.enable = lib.mkDefault true;
    k9s.enable = lib.mkDefault true;
    lazygit.enable = lib.mkDefault true;
    neovim.enable = lib.mkDefault true;
    sketchybar.enable = lib.mkDefault pkgs.stdenv.isDarwin;
    ssh.enable = lib.mkDefault true;
    terminals.enable = lib.mkDefault true;
    yazi.enable = lib.mkDefault true;
    zoxide.enable = lib.mkDefault true;
    zsh.enable = lib.mkDefault true;
  };

  kaynix.programs.hunk = {
    enableGitIntegration = true;
    settings = {
      theme = "graphite";
      mode = "auto";
      line_numbers = true;
      wrap_lines = false;
    };
  };
}
