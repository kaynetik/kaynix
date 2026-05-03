{
  config,
  lib,
  kaynixStatic,
  ...
}: let
  cfg = config.kaynix.programs.k9s;
in {
  options.kaynix.programs.k9s = {
    enable = lib.mkEnableOption "k9s configuration";
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."k9s/config.yaml".text = ''
      k9s:
        ui:
          skin: catppuccin-frappe
    '';

    xdg.configFile."k9s/skins/catppuccin-frappe.yaml".source = "${kaynixStatic}/k9s/skins/catppuccin-frappe.yaml";
  };
}
