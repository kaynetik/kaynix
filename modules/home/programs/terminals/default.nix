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

    xdg.configFile."tmux" = {
      source = "${kaynixStatic}/tmux";
      recursive = true;
    };
  };
}
