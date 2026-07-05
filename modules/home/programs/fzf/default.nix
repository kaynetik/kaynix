{
  config,
  lib,
  ...
}: let
  cfg = config.kaynix.programs.fzf;
in {
  options.kaynix.programs.fzf = {
    enable = lib.mkEnableOption "fzf";
  };

  config = lib.mkIf cfg.enable {
    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
      # Atuin owns Ctrl-R (its integration is sourced after fzf). An empty
      # command drops fzf's Ctrl-R binding and the home-manager ownership warning.
      historyWidget.command = "";
      defaultOptions = [
        "--height 40%"
        "--layout=reverse"
        "--border"
        "--inline-info"
        "--color=bg+:#414559,bg:#303446,spinner:#f2d5cf,hl:#e78284"
        "--color=fg:#c6d0f5,header:#e78284,info:#ca9ee6,pointer:#f2d5cf"
        "--color=marker:#f2d5cf,fg+:#c6d0f5,prompt:#ca9ee6,hl+:#e78284"
      ];
    };
  };
}
