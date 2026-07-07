{pkgs, ...}: {
  fonts.packages =
    [
      pkgs.sketchybar-app-font # App icon ligatures for the sketchybar workspace widget
    ]
    ++ (with pkgs.nerd-fonts; [
      jetbrains-mono # Primary terminal font (Alacritty)
      fira-code
      meslo-lg
    ]);
}
