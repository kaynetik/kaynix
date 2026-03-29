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

  xdg.enable = true;

  home.sessionPath = [
    "${config.home.homeDirectory}/.cargo/bin"
    "${config.home.homeDirectory}/go/bin"
  ];

  kaynix.programs = {
    agents.enable = lib.mkDefault true;
    atuin.enable = lib.mkDefault true;
    eza.enable = lib.mkDefault true;
    fzf.enable = lib.mkDefault true;
    gh.enable = lib.mkDefault true;
    git.enable = lib.mkDefault true;
    java.enable = lib.mkDefault true;
    jjui.enable = lib.mkDefault true;
    jujutsu.enable = lib.mkDefault true;
    lazygit.enable = lib.mkDefault true;
    neovim.enable = lib.mkDefault true;
    sketchybar.enable = lib.mkDefault pkgs.stdenv.isDarwin;
    ssh.enable = lib.mkDefault true;
    terminals.enable = lib.mkDefault true;
    zoxide.enable = lib.mkDefault true;
    zsh.enable = lib.mkDefault true;
  };
}
