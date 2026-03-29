{
  config,
  lib,
  ...
}: let
  cfg = config.kaynix.programs.lazygit;
in {
  options.kaynix.programs.lazygit = {
    enable = lib.mkEnableOption "lazygit";
  };

  config = lib.mkIf cfg.enable {
    programs.lazygit = {
      enable = true;
      settings = {
        gui = {
          nerdFontsVersion = "3";
          showListFooter = false;
          showRandomTip = false;
          expandFocusedSidePanel = true;
          shortTimeFormat = "15:04";
          branchColorPatterns = {
            "^main$" = "#ed8796";
            "^master$" = "#ed8796";
            "^dev" = "#8bd5ca";
          };
        };
        git = {
          overrideGpg = true;
          autoFetch = false;
          mainBranches = ["main" "master" "develop"];
        };
        os = {
          editPreset = "nvim";
        };
        customCommands = import ./custom-commands.nix;
      };
    };
  };
}
