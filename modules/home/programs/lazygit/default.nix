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
          # lazygit 0.66 reads branch colors from gui.theme and rewrites the
          # config file when it still finds them on gui. That file is a Nix
          # store symlink, so the rewrite fails with permission denied.
          theme = {
            branchColorPatterns = {
              "^main$" = "#ed8796";
              "^master$" = "#ed8796";
              "^dev" = "#8bd5ca";
            };
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
