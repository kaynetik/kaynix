{
  config,
  lib,
  kaynixStatic,
  ...
}: let
  cfg = config.kaynix.programs.terminals;
in {
  options.kaynix.programs.terminals = {
    enable = lib.mkEnableOption "terminal emulators (alacritty, tmux)";
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."alacritty/alacritty.toml".source = "${kaynixStatic}/alacritty/alacritty.toml";
    xdg.configFile."alacritty/catppuccin-frappe.toml".source = "${kaynixStatic}/alacritty/catppuccin-frappe.toml";

    # tmux.conf is rendered, not linked: sessionx paths need the concrete home
    # directory, and tmux does not expand $HOME inside plugin option strings.
    xdg.configFile."tmux/tmux.conf".text =
      builtins.replaceStrings ["@HOME@"] [config.home.homeDirectory]
      (builtins.readFile "${kaynixStatic}/tmux/tmux.conf");
    xdg.configFile."tmux/tmux.reset.conf".source = "${kaynixStatic}/tmux/tmux.reset.conf";
  };
}
